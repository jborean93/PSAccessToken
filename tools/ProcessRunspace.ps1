<#
.SYNOPSIS
Used by the DoTest task to run Pester in another process which exits cleanly once the tests are complete.
#>
[CmdletBinding()]
param ()

# Create a static class and field that the connecting runspace can fire to indicate it is complete.
Add-Type -TypeDefinition @'
using System.Threading;

public static class Control
{
    public static AutoResetEvent Finished = new AutoResetEvent(false);
}
'@

$pidFile = $PSCommandPath + '.pid'
Set-Content $pidFile -Value $pid

try {
    # Wait until the runspace has signaled it is done
    [void][Control]::Finished.WaitOne()

    # Wait until all connected runspaces have been closed before exiting
    $currentRunspace = [Runspace]::DefaultRunspace.Id
    while (@(Get-Runspace | Where-Object { $_.Id -ne $currentRunspace })) {
        Start-Sleep -Second 1
    }
}
finally {
    Remove-Item $pidFile -Force
}
