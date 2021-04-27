# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSUseShouldProcessForStateChangingFunctions", "",
    Justification="These are just test util functions, ignoring this rule"
)]
Param ()

Function Get-SystemToken {
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
                    $token_user = Get-TokenUser -Token $h_token
                    if ($token_user.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq 'S-1-5-18') {
                        return Copy-AccessToken -Token $h_token -Access AdjustPrivileges, Duplicate, Impersonate, Query
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

    throw "Failed to get system token"
}

Function New-LocalAccount {
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Username,

        [Parameter(Mandatory=$true)]
        [SecureString]
        $Password
    )

    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $adsi_obj = $adsi.Children | Where-Object { $_.SchemaClassName -eq 'User' -and $_.Name -eq $Username }

    if ($null -eq $adsi_obj) {
        $adsi_obj = $adsi.Create("User", $username)
    }

    # ADS_UF_PASSWORD_CANT_CHANGE, ADS_UF_DONT_EXPIRE_PASSWD
    $user_flags = $adsi_obj.UserFlags.Value
    if ($null -eq $user_flags) {
        $user_flags = 64 -bor 65536
    } else {
        $user_flags = $user_flags -bor 64 -bor 65536
    }
    $adsi_obj.UserFlags = $user_flags

    $pass_ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($Password)
    try {
        $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($pass_ptr)
        $adsi_obj.SetPassword($pass) > $null
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($pass_ptr)
    }

    $adsi_obj.SetInfo() > $null

    $sid_bytes = $adsi_obj.InvokeGet("objectSID")
    $sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $sid_bytes, 0

    return $sid
}

Function Remove-LocalAccount {
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Username
    )

    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $adsi_obj = $adsi.Children | Where-Object { $_.SchemaClassName -eq 'User' -and $_.Name -eq $Username }

    if ($null -ne $adsi_obj) {
        $adsi.Delete("User", $adsi_obj.Name.Value)
    }
}

Function Set-LocalAccountMembership {
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Username,

        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Groups
    )

    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $user_obj = $adsi.Children | Where-Object { $_.SchemaClassName -eq 'User' -and $_.Name -eq $Username }

    if ($null -eq $user_obj) {
        throw "Failed to find local account $Username"
    }

    $existing_groups = [System.String[]]@($user_obj.Groups() | ForEach-Object -Process {
        $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)
    })
    $to_add = [System.Linq.Enumerable]::Except($Groups, $existing_groups)
    $to_remove = [System.Linq.Enumerable]::Except($existing_groups, $Groups)

    $true, $false | ForEach-Object -Process {
        $group_list = if ($_) { $to_add } else { $to_remove}

        foreach ($group in $group_list) {
            $grp_obj = $adsi.Children | Where-Object { $_.SchemaClassName -eq 'Group' -and $_.Name -eq $group }
            if ($null -eq $grp_obj) {
                throw "Failed to find local gorup $group"
            }

            if ($_) {
                $grp_obj.Add($user_obj.Path)
            } else {
                $grp_obj.Remove($user_obj.Path)
            }
        }
    }
}