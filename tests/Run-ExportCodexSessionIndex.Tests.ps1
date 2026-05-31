$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$script = Join-Path $repoRoot "scripts/Export-CodexSessionIndex.ps1"

function Assert-True($condition, $message) {
    if (-not $condition) { throw $message }
}

function Assert-NotMatchText($text, $pattern, $message) {
    if ($text -match $pattern) { throw $message }
}

Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter "*.ps1" |
    Where-Object { $_.FullName -notmatch "\\.git\\" } |
    ForEach-Object {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) {
            throw "PowerShell parse failed for $($_.FullName): $($errors[0].Message)"
        }
    }

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-continuity-kit-test-" + [guid]::NewGuid().ToString("N"))
$sessionsRoot = Join-Path $tempRoot "sessions"
$sessionDir = Join-Path (Join-Path (Join-Path $sessionsRoot "2026") "05") "31"
$outputRoot = Join-Path $tempRoot "out"

New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null
$jsonl = Join-Path $sessionDir "rollout-test.jsonl"

$lines = @(
    '{"type":"session_meta","payload":{"id":"test-thread","timestamp":"2026-05-31T12:00:00Z","cwd":"C:\\Users\\alice\\Desktop\\ExampleRepo","model":"gpt-test","originator":"codex"}}',
    '{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"Please fix C:\\Users\\alice\\Desktop\\ExampleRepo\\app.ps1"}]}}',
    '{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Checked /Users/alice/work/private and /home/bob/project."}]}}',
    '{"type":"response_item","payload":{"type":"message","role":"developer","content":[{"type":"input_text","text":"Developer-only content should not appear in shareable output."}]}}'
)
[System.IO.File]::WriteAllLines($jsonl, $lines, [System.Text.UTF8Encoding]::new($false))

& $script -SessionsRoot $sessionsRoot -OutputRoot $outputRoot -CreateRescue -Shareable -IncludeDeveloperMessages | Out-Host

$indexPath = Join-Path $outputRoot "session-index.md"
$rescuePath = (Get-ChildItem -LiteralPath (Join-Path $outputRoot "rescues") -Filter "*.md" | Select-Object -First 1).FullName

Assert-True (Test-Path -LiteralPath $indexPath) "Index file was not created."
Assert-True (Test-Path -LiteralPath $rescuePath) "Rescue file was not created."

$combined = (Get-Content -LiteralPath $indexPath -Raw) + "`n" + (Get-Content -LiteralPath $rescuePath -Raw)

Assert-True ($combined -match 'Redaction: `local user profile paths redacted`') "Shareable output did not record redaction mode."
Assert-NotMatchText $combined "alice|bob|C:\\Users\\|/Users/alice|/home/bob" "Shareable output leaked a test user path."
Assert-NotMatchText $combined "Developer-only content" "Shareable output included developer messages."

Write-Host "All tests passed."
