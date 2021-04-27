# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Use-TokenGroupsPointer {
    <#
    .SYNOPSIS
    Create a valid TOKEN_GROUPS or just an array of SID_AND_ATTRIBUTES to a pointer.

    .PARAMETER Group
    Either the name of the group or a hashtable with the following keys;
        Sid: The name or SID of the group.
        Attributes: The attributes for the group, defaults is the value of -DefaultAttributes

    .PARAMETER Process
    A scriptblock that is run with the TOKEN_GROUPS pointer passed in as the -Ptr parameter.

    .PARAMETER DefaultAttributes
    The default attributes to apply to a group if the Attributes key is not set.

    .PARAMETER Variables
    Variables to pass in to the -Process scriptblock as the -Variables parameter.

    .PARAMETER NullAsEmpty
    Controls the behaviour when there are no groups set. When set, the pointer for TOKEN_GROUPS is [IntPtr]::Zero,
    otherwise it is a valid TOKEN_GROUPS structure with GroupCount set to 0.

    .PARAMETER ForceDefaultAttributes
    Ignore any attributes that have been passed in and just forced the Attributes to be DefaultAttributes.

    .PARAMETER OmitTokenGroups
    Do not create the full TOKEN_GROUPS structure, just copy each of the SID_AND_ATTRIBUTES entries to the pointer.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Object]
        $Group,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Process,

        [PSAccessToken.TokenGroupAttributes]
        $DefaultAttributes = [PSAccessToken.TokenGroupAttributes]'Enabled, EnabledByDefault, Mandatory',

        [Hashtable]
        $Variables,

        [Switch]
        $NullAsEmpty,

        [Switch]
        $ForceDefaultAttributes,

        [Switch]
        $OmitTokenGroups
    )

    Begin {
        $groups = [System.Collections.Generic.List`1[Object]]@()
        $sid_size = 0
    }

    Process {
        $sanda = ConvertTo-SidAndAttributes -InputObject $Group -DefaultAttributes $DefaultAttributes
        if ($ForceDefaultAttributes) {
            $sanda.Attributes = $DefaultAttributes
        }

        # Check if the group already exists
        $existing_group = $groups | Where-Object { $_.Sid -eq $sanda.Sid }
        if ($null -ne $existing_group) {
            # Update the existing attributes.
            $existing_group.Attributes = $existing_group.Attributes -bor $sanda.Attributes
        } else {
            $groups.Add($sanda)
            $sid_size += $sanda.Sid.BinaryLength
        }
    }

    End {
        if ($groups.Count -eq 0 -and $NullAsEmpty.IsPresent) {
            $struct_size = 0
            $sid_offset = 0
        } else {
            $tg_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.TOKEN_GROUPS]
            )
            $sanda_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.SID_AND_ATTRIBUTES]
            )

            # Get the size of the TOKEN_GROUPS structure
            if ($OmitTokenGroups) {
                $struct_size = 0
                $existing_sid_and_attributes = 0
            } else {
                $struct_size = $tg_size
                $existing_sid_and_attributes = 1
            }

            if ($groups.Count -gt 0) {
                # The initial TOKEN_GROUPS struct contains 1 SID_AND_ATTRIBUTES so that's removed from the final count.
                $struct_size += $sanda_size * ($groups.Count - $existing_sid_and_attributes)
            }

            $sid_offset = $struct_size
            $struct_size += $sid_size
        }

        $pointer_vars = @{
            omit_token_groups = $OmitTokenGroups
            groups = $groups
            tg_size = $tg_size
            struct_size = $struct_size
            sid_offset = $sid_offset
            variables = $Variables
            process = $Process
        }

        Use-SafePointer -Size $struct_size -Variables $pointer_vars -Process {
            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

            $token_groups_ptr = $Ptr

            if ($Variables.struct_size -ne 0) {
                $sid_ptr = [System.IntPtr]::Add($Ptr, $Variables.sid_offset)

                $token_groups = New-Object -TypeName PSAccessToken.TOKEN_GROUPS
                $token_groups.GroupCount = $Variables.groups.Count
                $token_groups.Groups = New-Object -TypeName PSAccessToken.SID_AND_ATTRIBUTES[] -ArgumentList 1

                for ($i = 0; $i -lt $Variables.groups.Count; $i++) {
                    $group = $Variables.groups[$i]

                    $sanda = New-Object -TypeName PSAccessToken.SID_AND_ATTRIBUTES
                    $sanda.Attributes = $group.Attributes
                    $sanda.Sid = $sid_ptr

                    # Now copy the SID to the unmanaged memory section.
                    $sid_ptr = Copy-SidToPointer -Ptr $sid_ptr -Sid $group.Sid

                    if ($i -eq 0 -and -not $Variables.omit_token_groups) {
                        # The 1st SID_AND_ATTRIBUTES should be placed directly on the TOKEN_GROUPS struct, the structure
                        # is copied after this loop.
                        $token_groups.Groups[0] = $sanda
                        $Ptr = [System.IntPtr]::Add($Ptr, $Variables.tg_size)
                    } else {
                        # The remaining SID_AND_ATTRIBUTES are copied manually to the end of the TOKEN_GROUPS struct.
                        $Ptr = Copy-StructureToPointer -Ptr $Ptr -Structure $sanda
                    }
                }

                # Now copy across the TOKEN_GROUPS structure
                if (-not $Variables.omit_token_groups) {
                    Copy-StructureToPointer -Ptr $token_groups_ptr -Structure $token_groups > $null
                }
            }

            &$Variables.process -Ptr $token_groups_ptr -Variables $Variables.variables
        }
    }
}