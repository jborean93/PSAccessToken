# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function ConvertTo-SecurityIdentifier {
    <#
    .SYNOPSIS
    Converts an input into a SecurityIdentifier object.

    .DESCRIPTION
    Converts an input (NTAccount, string, SID as string) to a SecurityIdentifier object.

    .PARAMETER InputObject
    The input to convert. Can be:
        String - A string that either represents a SID or SecurityIdentifier
        NTAccount - An NTAccount object
        SecurityIdentifier - No conversion takes place but it will just output this back
        IntPtr - A pointer to an unmanaged memory of a SID.

    .EXAMPLE
    ConvertTo-SecurityIdentifier -InputObject System
    #>
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object[]]
        $InputObject
    )

    Process {
        foreach ($obj in $InputObject) {
            if ($obj -is [System.Security.Principal.IdentityReference]) {
                Write-Output -InputObject ($obj.Translate([System.Security.Principal.SecurityIdentifier]))
            } elseif ($obj -is [System.IntPtr]) {
                if ($obj -ne [System.IntPtr]::Zero) {
                    Write-Output -InputObject (New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $obj)
                }
            } else {
                $obj = $obj.ToString()

                try {
                    $sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $obj
                    Write-Output -InputObject $sid
                } catch [System.ArgumentException] {
                    $nt_account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $obj
                    Write-Output -InputObject ($nt_account.Translate([System.Security.Principal.SecurityIdentifier]))
                }
            }
        }
    }
}