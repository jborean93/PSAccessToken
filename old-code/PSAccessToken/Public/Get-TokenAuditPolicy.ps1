# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenAuditPolicy {
    <#
    .SYNOPSIS
    Get the audit policy of the access token.

    .DESCRIPTION
    Gets the audit policy byte array definition of the access token. This shows all policies that have been enabled on
    the access token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    A byte[] of the audit policy info. This can change to a proper structure once this is understood more.

    .EXAMPLE Gets the audit policy for the current process
    Get-TokenAuditPolicy

    .EXAMPLE Gets the audit policy for the process with the id 1234
    Get-TokenAuditPolicy -ProcessId 1234

    .EXAMPLE Gets the audit policy for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenAuditPolicy -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }

    .NOTES
    This requires the SeSecurityPrivilege on the current token, it will be automatically enabled and disabled as
    needed. The structure is not documented so the output object is based on what I have observed. It may change if any
    bugs are found that require a UI change.
    #>
    [OutputType('PSAccessToken.TokenAuditPolicy')]
    [CmdletBinding(DefaultParameterSetName="Token")]
    Param (
        [Parameter(ParameterSetName="Token")]
        [System.Runtime.InteropServices.SafeHandle]
        $Token,

        [Parameter(ParameterSetName="PID")]
        [System.UInt32]
        $ProcessId,

        [Parameter(ParameterSetName="TID")]
        [System.UInt32]
        $ThreadId,

        [Parameter(ParameterSetName="ProcessToken")]
        [Switch]
        $UseProcessToken
    )

    $old_state = Set-TokenPrivileges -Name SeSecurityPrivilege -Strict
    try {
        Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::AuditPolicy) -Process {
            Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

            # TOKEN_AUDIT_POLICY is a just a struct that contains a byte array of a certain length. We just copy the
            # value to bytes ourselves and parse that.
            $policy = New-Object -TypeName System.Byte[] -ArgumentList $TokenInfoLength
            [System.Runtime.InteropServices.Marshal]::Copy($TokenInfo, $policy, 0, $policy.Length)

            # The order that Get-AuditCategory returns each sub category is important. I don't know of any other way
            # to correct map the raw bytes from TokenAuditPolicy to the actual policy names as TOKEN_AUDIT_POLICY is
            # not fully documented. Each sub category are controlled by every 4 bits with each byte representing;
            #
            # 0001 - Subcategory is enabled for successful events
            # 0100 - Subcategory is enabled for failure events
            #
            # The lower part is the first category of the byte.

            # Even with the ordering above, manual testing has shown that a small number of policies don't align with
            # each other, this hashtable is a manual override of the byte index for specific sub categories.
            $manual_mapping = @{  # Sub Category Name = Index shifter
                '0cce9219-69ae-11d9-bed3-505054503030' = 1  # IPsec Quick Mode
                '0cce921a-69ae-11d9-bed3-505054503030' = 1  # IPsec Extended Mode
                '0cce921b-69ae-11d9-bed3-505054503030' = -2  # Special Logon

                '0cce9221-69ae-11d9-bed3-505054503030' = +1  # Certification Services
                '0cce9222-69ae-11d9-bed3-505054503030' = +1  # Application Generated
                '0cce9223-69ae-11d9-bed3-505054503030' = +1  # Handle Manipulation
                '0cce9224-69ae-11d9-bed3-505054503030' = +1  # File Share
                '0cce9225-69ae-11d9-bed3-505054503030' = +1  # Filtering Platform Packet Drop
                '0cce9226-69ae-11d9-bed3-505054503030' = +1  # Filtering Platform Connection
                '0cce9227-69ae-11d9-bed3-505054503030' = -6  # Other Object Access Events
            }

            $audit_sub_categories = (Get-AuditCategory).SubCategories
            for ($i = 0; $i -lt $audit_sub_categories.Length; $i++) {
                $sub_category = $audit_sub_categories[$i]

                # Override the byte index with known mapping changes.
                $byte_index = $i
                if ($sub_category.Guid -in $manual_mapping.Keys) {
                    $byte_index = $byte_index + $manual_mapping."$($sub_category.Guid)"
                }

                $byte_entry = $byte_index / 2
                $byte_entry_floor = [System.Math]::Floor($byte_entry)

                $raw_byte = $policy[$byte_entry_floor]
                if ($byte_entry -eq $byte_entry_floor) {
                    $raw_byte = $raw_byte -band 0x0F
                } else {
                    $raw_byte = $raw_byte -shr 4
                }

                [PSCustomObject]@{
                    PSTypeName = 'PSAccessToken.TokenAuditPolicy'
                    Policy = $sub_category.Name
                    Guid = $sub_category.Guid
                    Success = (($raw_byte -band 1) -ne 0)
                    Failure = (($raw_byte -band 4) -ne 0)
                }
            }
        }
    } finally {
        $old_state | Set-TokenPrivileges > $null
    }
}