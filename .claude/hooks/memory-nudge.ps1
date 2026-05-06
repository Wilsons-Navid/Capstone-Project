# Stop hook: nudges Claude to update auto-memory if meaningful capstone work occurred this turn.
# See: C:\Users\LENOVO\.claude\projects\C--Users-LENOVO-Desktop-Capstone-Project\memory\feedback_proactive_memory.md

$ErrorActionPreference = 'Stop'

try {
    $stdin = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($stdin)) { exit 0 }
    $hook = $stdin | ConvertFrom-Json
    # Already in a blocked-stop chain — let Claude finish, don't loop.
    if ($hook.stop_hook_active) { exit 0 }
} catch {
    # Never block on bad input.
    exit 0
}

$reason = @"
Before ending the turn: consider whether meaningful capstone progress was made this turn (new artifacts written, supervisor decisions recorded, scope changes, ML baselines or datasets, code modules added, pilot milestones, outreach status changes).

If yes: update or create memory files at C:\Users\LENOVO\.claude\projects\C--Users-LENOVO-Desktop-Capstone-Project\memory\ BEFORE stopping. Per feedback_proactive_memory.md, do not ask permission first.

If only trivial work happened (typo fixes, simple lookups, exploratory questions, restating known facts): say so briefly in one sentence and stop. No update needed.
"@

$response = [pscustomobject]@{
    decision = 'block'
    reason   = $reason
} | ConvertTo-Json -Compress

Write-Output $response
exit 0
