# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function ConvertFrom-SecurityIdentifier {
    <#
    .SYNOPSIS
    Convert a SecurityIdentifier to a human friendly object.

    .PARAMETER Sid
    The SecurityIdentifier object to translate.

    .PARAMETER ErrorBehaviour
    Controls the output when the SID cannot be translated.
        Error - The exception is raised
        PassThru - The Sid object is just returned back
        SidString - The Sid object as a string is returned
        Empty - An empty string is returned
    #>
    Param (
        [Parameter(Mandatory=$true)]
        [System.Security.Principal.SecurityIdentifier]
        $Sid,

        [ValidateSet("Error", "PassThru", "SidString", "Empty")]
        [System.String]
        $ErrorBehaviour = "SidString"
    )

    if ($Sid.Value.StartsWith('S-1-16-')) {
        # .Translate() fails on Integrity label, create our own
        switch ($Sid.Value) {
            'S-1-16-0' { return New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'Untrusted Mandatory Label' }
            'S-1-16-4096' { return New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'Low Mandatory Label' }
            'S-1-16-8192' { return New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'Medium Mandatory Label' }
            'S-1-16-12288' { return New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'High Mandatory Label' }
            'S-1-16-16384' { return New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'System Mandatory Label' }
        }
    } elseif ($Sid.Value.StartsWith('S-1-5-5-')) {
        # .Translate() fails on Logon IDs, create our own
        $logon_id = $Sid.Value.Substring(8)
        return New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'NT AUTHORITY', "Logon Session ID $logon_id"
    }

    try {
        return $Sid.Translate([System.Security.Principal.NTAccount])
    } catch {
        if ($ErrorBehaviour -eq "SidString") {
            return $Sid.Value
        } elseif ($ErrorBehaviour -eq "PassThru") {
            return $Sid
        } elseif ($ErrorBehaviour -eq "Empty") {
            return ""
        } else {
            throw $_
        }
    }
}