param(
    [string]$SessionsRoot = "$env:USERPROFILE\.codex\sessions",
    [string]$OutputRoot = "",
    [string]$Keyword = "",
    [string]$ThreadId = "",
    [int]$RecentTurns = 8,
    [switch]$CreateRescue,
    [switch]$IncludeDeveloperMessages,
    [switch]$RedactPaths,
    [switch]$Shareable
)

$ErrorActionPreference = "Stop"
$redactOutput = $RedactPaths.IsPresent -or $Shareable.IsPresent

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path (Get-Location) "codex-continuity-output"
}

function Get-TextFromContent($content) {
    if ($null -eq $content) { return "" }
    if ($content -is [string]) { return $content }
    $parts = @()
    foreach ($item in @($content)) {
        if ($null -eq $item) { continue }
        if ($item.PSObject.Properties.Name -contains "text") {
            $parts += [string]$item.text
        } elseif ($item.PSObject.Properties.Name -contains "content") {
            $parts += (Get-TextFromContent $item.content)
        }
    }
    return ($parts -join "`n")
}

function Shorten($text, $limit = 360) {
    if ([string]::IsNullOrWhiteSpace($text)) { return "" }
    $clean = ($text -replace "`r", "" -replace "`n+", " ").Trim()
    if ($clean.Length -le $limit) { return $clean }
    return $clean.Substring(0, $limit) + "..."
}

function Unescape-JsonText($text) {
    if ($null -eq $text) { return "" }
    return [System.Text.RegularExpressions.Regex]::Unescape([string]$text)
}

function Protect-OutputText($text) {
    if ($null -eq $text) { return "" }
    $safe = [string]$text
    if (-not $script:redactOutput) { return $safe }

    $safe = $safe -replace '(?i)[A-Z]:\\Users\\[^\\`"''<>\|\r\n]+', '<windows-user-profile>'
    $safe = $safe -replace '(?i)[A-Z]:\\Documents and Settings\\[^\\`"''<>\|\r\n]+', '<windows-user-profile>'
    $safe = $safe -replace '/Users/[^/`"''<>\|\s]+', '<mac-user-profile>'
    $safe = $safe -replace '/home/[^/`"''<>\|\s]+', '<linux-user-profile>'
    $safe = $safe -replace '\\\\[^\\\s`"''<>\|]+\\[^\\\s`"''<>\|]+', '<unc-path>'

    return $safe
}

function Get-JsonField($line, $name) {
    $m = [regex]::Match($line, '"' + [regex]::Escape($name) + '":"((?:\\.|[^"])*)"')
    if ($m.Success) { return (Unescape-JsonText $m.Groups[1].Value) }
    return ""
}

function Read-Session($path, [bool]$includeDeveloperMessages) {
    $meta = $null
    $turns = New-Object System.Collections.Generic.List[object]
    $commands = New-Object System.Collections.Generic.List[string]
    $errors = New-Object System.Collections.Generic.List[string]

    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
        try {
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                if ([string]::IsNullOrWhiteSpace($line)) { continue }

                if ($line.Contains('"type":"session_meta"')) {
                    $meta = [pscustomobject]@{
                        id = Get-JsonField $line "id"
                        timestamp = Get-JsonField $line "timestamp"
                        cwd = Get-JsonField $line "cwd"
                        model = Get-JsonField $line "model"
                        originator = Get-JsonField $line "originator"
                    }
                    continue
                }

                if (-not $line.Contains('"type":"response_item"')) { continue }
                if ($line.Contains('"type":"reasoning"')) { continue }
                if (-not $includeDeveloperMessages -and $line.Contains('"role":"developer"')) { continue }

                try { $j = $line | ConvertFrom-Json } catch { continue }

                if ($j.type -ne "response_item") { continue }
                $p = $j.payload

                if ($p.type -eq "message" -and ($p.role -eq "user" -or $p.role -eq "assistant" -or ($includeDeveloperMessages -and $p.role -eq "developer"))) {
                    $text = Get-TextFromContent $p.content
                    if (-not [string]::IsNullOrWhiteSpace($text)) {
                        $turns.Add([pscustomobject]@{
                            role = $p.role
                            text = $text
                        }) | Out-Null
                    }
                } elseif ($p.type -eq "function_call" -or $p.type -eq "custom_tool_call") {
                    $name = [string]$p.name
                    $args = ""
                    if ($p.PSObject.Properties.Name -contains "arguments") { $args = [string]$p.arguments }
                    elseif ($p.PSObject.Properties.Name -contains "input") { $args = [string]$p.input }
                    $cmd = Shorten (($name + " " + $args).Trim()) 500
                    if ($cmd) { $commands.Add($cmd) | Out-Null }
                } elseif ($p.type -eq "function_call_output" -or $p.type -eq "custom_tool_call_output") {
                    $out = ""
                    if ($p.PSObject.Properties.Name -contains "output") { $out = [string]$p.output }
                    elseif ($p.PSObject.Properties.Name -contains "content") { $out = Get-TextFromContent $p.content }
                    if ($out -match "(?i)\berror\b|exception|failed|context_length_exceeded|compact") {
                        $errors.Add((Shorten $out 700)) | Out-Null
                    }
                }
            }
        } finally {
            $reader.Dispose()
        }
    } finally {
        $stream.Dispose()
    }

    $item = Get-Item -LiteralPath $path
    $allText = (($turns | ForEach-Object { $_.text }) -join "`n")
    return [pscustomobject]@{
        path = $path
        id = if ($meta) { [string]$meta.id } else { "" }
        timestamp = if ($meta) { [string]$meta.timestamp } else { "" }
        cwd = if ($meta) { [string]$meta.cwd } else { "" }
        model = if ($meta) { [string]$meta.model } else { "" }
        originator = if ($meta) { [string]$meta.originator } else { "" }
        lastWrite = $item.LastWriteTime
        sizeBytes = $item.Length
        turns = $turns
        commands = $commands
        errors = $errors
        matchText = $allText
    }
}

function Write-Rescue($session, $outDir, $recentTurns) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $safeId = if ($session.id) { $session.id } else { [System.IO.Path]::GetFileNameWithoutExtension($session.path) }
    $outPath = Join-Path $outDir ("rescue-" + $safeId + ".md")

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Codex Session Rescue") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("> Review and redact before sharing. This file may contain private conversation content.") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add('- Thread id: `' + (Protect-OutputText $session.id) + '`') | Out-Null
    $lines.Add('- Timestamp: `' + (Protect-OutputText $session.timestamp) + '`') | Out-Null
    $lines.Add('- Last write: `' + $session.lastWrite.ToString("yyyy-MM-dd HH:mm:ss") + '`') | Out-Null
    $lines.Add('- CWD: `' + (Protect-OutputText $session.cwd) + '`') | Out-Null
    $lines.Add('- Model: `' + (Protect-OutputText $session.model) + '`') | Out-Null
    $lines.Add('- Source JSONL: `' + (Protect-OutputText $session.path) + '`') | Out-Null
    $lines.Add("") | Out-Null

    $lines.Add("## Recent Turns") | Out-Null
    $recent = @($session.turns | Select-Object -Last $recentTurns)
    foreach ($t in $recent) {
        $lines.Add("") | Out-Null
        $lines.Add("### " + $t.role) | Out-Null
        $lines.Add("") | Out-Null
        $lines.Add('```text') | Out-Null
        $lines.Add((Protect-OutputText (Shorten $t.text 2500))) | Out-Null
        $lines.Add('```') | Out-Null
    }

    $lines.Add("") | Out-Null
    $lines.Add("## Recent Commands") | Out-Null
    foreach ($c in @($session.commands | Select-Object -Last 20)) {
        $lines.Add('- `' + (Protect-OutputText $c) + '`') | Out-Null
    }

    $lines.Add("") | Out-Null
    $lines.Add("## Error-Like Outputs") | Out-Null
    foreach ($e in @($session.errors | Select-Object -Last 20)) {
        $lines.Add("- " + (Protect-OutputText $e)) | Out-Null
    }

    [System.IO.File]::WriteAllLines($outPath, $lines, [System.Text.UTF8Encoding]::new($false))
    return $outPath
}

if (-not (Test-Path -LiteralPath $SessionsRoot)) {
    throw "SessionsRoot not found: $SessionsRoot"
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$files = Get-ChildItem -LiteralPath $SessionsRoot -Recurse -File -Filter "rollout-*.jsonl" |
    Sort-Object LastWriteTime -Descending

$sessions = New-Object System.Collections.Generic.List[object]
foreach ($f in $files) {
    $s = Read-Session $f.FullName ($IncludeDeveloperMessages.IsPresent -and -not $Shareable.IsPresent)
    if ($ThreadId -and $s.id -notlike "*$ThreadId*") { continue }
    if ($Keyword -and (($s.matchText + "`n" + $s.cwd + "`n" + $s.path) -notmatch [regex]::Escape($Keyword))) { continue }
    $sessions.Add($s) | Out-Null
}

$indexPath = Join-Path $OutputRoot "session-index.md"
$index = New-Object System.Collections.Generic.List[string]
$index.Add("# Codex Session Index") | Out-Null
$index.Add("") | Out-Null
$index.Add("> Review and redact before sharing. This file may contain private paths or conversation content.") | Out-Null
$index.Add("") | Out-Null
$index.Add("Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) | Out-Null
$index.Add('Sessions root: `' + (Protect-OutputText $SessionsRoot) + '`') | Out-Null
if ($Keyword) { $index.Add('Keyword filter: `' + (Protect-OutputText $Keyword) + '`') | Out-Null }
if ($ThreadId) { $index.Add('Thread filter: `' + (Protect-OutputText $ThreadId) + '`') | Out-Null }
if ($redactOutput) { $index.Add('Redaction: `local user profile paths redacted`') | Out-Null }
$index.Add("") | Out-Null

foreach ($s in $sessions) {
    $lastUser = @($s.turns | Where-Object role -eq "user" | Select-Object -Last 1)
    $lastAssistant = @($s.turns | Where-Object role -eq "assistant" | Select-Object -Last 1)
    $sessionId = if ($s.id) { Protect-OutputText $s.id } else { "(no id)" }
    $index.Add("## " + $s.lastWrite.ToString("yyyy-MM-dd HH:mm:ss") + " - " + $sessionId) | Out-Null
    $index.Add("") | Out-Null
    $index.Add('- CWD: `' + (Protect-OutputText $s.cwd) + '`') | Out-Null
    $index.Add('- Model: `' + (Protect-OutputText $s.model) + '`') | Out-Null
    $index.Add('- JSONL: `' + (Protect-OutputText $s.path) + '`') | Out-Null
    $index.Add("- Size: $([math]::Round($s.sizeBytes / 1MB, 2)) MB") | Out-Null
    $index.Add("- Last user: " + (Protect-OutputText (Shorten $(if ($lastUser) { $lastUser[0].text } else { "" }) 500))) | Out-Null
    $index.Add("- Last assistant: " + (Protect-OutputText (Shorten $(if ($lastAssistant) { $lastAssistant[0].text } else { "" }) 500))) | Out-Null
    if ($s.errors.Count -gt 0) {
        $index.Add("- Recent error-like output: " + (Protect-OutputText (Shorten $s.errors[$s.errors.Count - 1] 500))) | Out-Null
    }
    $index.Add("") | Out-Null
}

[System.IO.File]::WriteAllLines($indexPath, $index, [System.Text.UTF8Encoding]::new($false))

$rescuePaths = @()
if ($CreateRescue) {
    $rescueDir = Join-Path $OutputRoot "rescues"
    foreach ($s in $sessions) {
        $rescuePaths += Write-Rescue $s $rescueDir $RecentTurns
    }
}

Write-Host "Index: $indexPath"
Write-Host "Matched sessions: $($sessions.Count)"
if ($CreateRescue) {
    Write-Host "Rescue files:"
    $rescuePaths | ForEach-Object { Write-Host $_ }
}
