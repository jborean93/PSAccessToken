# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenWithPrivilege {
    Param (
        [System.String[]]$Privileges
    )

    $priv_check = {
        $valid = $true

        foreach ($privilege in $Privileges) {
            if ($privilege -notin $args[0]) {
                $valid = $false
                break
            }
        }

        return $valid
    }.GetNewClosure()

    $token_privileges = Get-TokenPrivileges
    $valid = &$priv_check $token_privileges.Name
    if ($valid -eq $true) {
        return Copy-AccessToken -Access Duplicate, Query
    }

    # Loop through all process tokens and check if they have the privileges we need
    foreach ($process in [System.Diagnostics.Process]::GetProcesses()) {
        try {
            $h_process = Get-ProcessHandle -ProcessId $process.Id -Access QueryInformation -ErrorAction SilentlyContinue
            if ($null -eq $h_process -or $h_process.IsInvalid) {
                continue
            }

            try {
                $h_token = Open-ProcessToken -Process $h_process -Access Query, Duplicate -ErrorAction SilentlyContinue
                if ($null -eq $h_token -or $h_token.IsInvalid) {
                    continue
                }

                try {
                    $valid = &$priv_check (Get-TokenPrivileges -Token $h_token).Name

                    if ($valid) {
                        return Copy-AccessToken -Token $h_token -Access Duplicate, Query
                    }
                } finally {
                    $h_token.Dispose()
                }
            } finally {
                $h_process.Dispose()
            }
        } finally {
            $process.Dispose()
        }
    }

    # The sad part, we need to create our own local user, set LSA to give that account the privileges required, log
    # that user into the system, then steal that token.
    # Not yet requires because I can steal lsass.exe's token.
    throw "Failed to find token with privileges $Privileges"
}

Function Get-SystemToken {
    foreach ($process in [System.Diagnostics.Process]::GetProcesses()) {
        try {
            $h_process = Get-ProcessHandle -ProcessId $process.Id -Access QueryInformation -ErrorAction SilentlyContinue
            if ($null -eq $h_process -or $h_process.IsInvalid) {
                continue
            }

            try {
                $dispose = $true
                $h_token = Open-ProcessToken -Process $h_process -Access Query, Duplicate -ErrorAction SilentlyContinue
                if ($null -eq $h_token -or $h_token.IsInvalid) {
                    continue
                }

                try {
                    $token_user = Get-TokenUser -Token $h_token
                    if ($token_user.Value -eq 'S-1-5-18') {
                        $dispose = $false
                        return $h_token
                    }
                } finally {
                    if ($dispose) {
                        $h_token.Dispose()
                    }
                }
            } finally {
                $h_process.Dispose()
            }
        } finally {
            $process.Dispose()
        }
    }

    throw "Failed to get system token"
}