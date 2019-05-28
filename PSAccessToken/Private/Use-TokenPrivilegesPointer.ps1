# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Use-TokenPrivilegesPointer {
    <#
    .SYNOPSIS
    Create a valid TOKEN_PRIVILEGES or just an array of LUID_AND_ATTRIBUTES to a pointer.

    .PARAMETER Privilege
    Either the name of the privilege or a hashtable with the following keys;
        Name: The name of the privilege.
        Attributes: The attributes for the privileges, defaults is the value of -DefaultAttributes

    .PARAMETER Process
    A scriptblock that is run with the TOKEN_PRIVILEGES pointer passed in as the -Ptr parameter.

    .PARAMETER DefaultAttributes
    The default attributes to apply to a group if the Attributes key is not set.

    .PARAMETER Variables
    Variables to pass in to the -Process scriptblock as the -Variables parameter.

    .PARAMETER NullAsEmpty
    Controls the behaviour when there are no groups set. When set, the pointer for TOKEN_PRIVILEGES is [IntPtr]::Zero,
    otherwise it is a valid TOKEN_PRIVILEGES structure with GroupCount set to 0.

    .PARAMETER ForceDefaultAttributes
    Ignore any attributes that have been passed in and just forced the Attributes to be DefaultAttributes.

    .PARAMETER OmitTokenPrivileges
    Do not create the full TOKEN_PRIVILEGES structure, just copy each of the LUID_AND_ATTRIBUTES entries to the
    pointer.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Object]
        $Privilege,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Process,

        [PSAccessToken.TokenPrivilegeAttributes]
        $DefaultAttributes = [PSAccessToken.TokenPrivilegeAttributes]'Enabled, EnabledByDefault',

        [Hashtable]
        $Variables,

        [Switch]
        $NullAsEmpty,

        [Switch]
        $ForceDefaultAttributes,

        [Switch]
        $OmitTokenPrivileges
    )

    Begin {
        $privileges = [System.Collections.Generic.List`1[Object]]@()
    }

    Process {
        $attributes = $DefaultAttributes
        if ($Privilege -is [System.Collections.IDictionary]) {
            if (-not $Privilege.ContainsKey('Name')) {
                throw "Privileges entry does not contain key 'Name'"
            }
            $name = $Privilege.Name

            if ($Privilege.ContainsKey('Attributes')) {
                $attributes = $Privilege.Attributes
            }
        } elseif ($Privilege -is [System.Management.Automation.PSCustomObject]) {
            $properties = $Privilege.PSObject.Properties.Name
            if ('Name' -notin $properties){
                throw "Privileges entry does not contain key 'Name'"
            }
            $name = $Privilege.Name

            if ('Attributes' -in $properties) {
                $attributes = $Privilege.Attributes
            }
        } else {
            $name = $Privilege.ToString()
        }

        if ($ForceDefaultAttributes) {
            $attributes = $DefaultAttributes
        }

        # Check if the privilege already exists
        $existing_privilege = $privileges | Where-Object { $_.Name -eq $name }
        if ($null -eq $existing_privilege) {
            $privileges.Add(@{
                Name = $name
                Attributes = [PSAccessToken.TokenPrivilegeAttributes]$attributes
            })
        } else {
            $existing_privilege.Attributes = $existing_privilege.Attributes -bor $attributes
        }
    }

    End {
        if ($privileges.Count -eq 0 -and $NullAsEmpty.IsPresent) {
            $struct_size = 0
        } else {
            $tp_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.TOKEN_PRIVILEGES]
            )
            $landa_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.LUID_AND_ATTRIBUTES]
            )

            # Get the size of the TOKEN_PRIVILEGES structure
            if ($OmitTokenPrivileges) {
                $struct_size = 0
                $existing_luid_and_attributes = 0
            } else {
                $struct_size = $tp_size
                $existing_luid_and_attributes = 1
            }

            if ($privileges.Count -gt 0) {
                # The initial TOKEN_PRIVILEGES struct contains 1 LUID_AND_ATTRIBUTES so that's removed from the final
                # count.
                $struct_size += $landa_size * ($privileges.Count - $existing_luid_and_attributes)
            }
        }

        $pointer_vars = @{
            omit_token_privileges = $OmitTokenPrivileges
            privileges = $privileges
            tp_size = $tp_size
            struct_size = $struct_size
            variables = $Variables
            process = $Process
        }

        Use-SafePointer -Size $struct_size -Variables $pointer_vars -Process {
            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

            $token_privileges_ptr = $Ptr

            if ($Variables.struct_size -ne 0) {
                $token_privileges = New-Object -TypeName PSAccessToken.TOKEN_PRIVILEGES
                $token_privileges.PrivilegeCount = $Variables.privileges.Count
                $token_privileges.Privileges = New-Object -TypeName PSAccessToken.LUID_AND_ATTRIBUTES[] -ArgumentList 1

                for ($i = 0; $i -lt $Variables.privileges.Count; $i++) {
                    $privilege = $Variables.privileges[$i]

                    $landa = New-Object -TypeName PSAccessToken.LUID_AND_ATTRIBUTES
                    $landa.Attributes = $privilege.Attributes
                    $landa.Luid = Convert-PrivilegeToLuid -Name $privilege.Name

                    if ($i -eq 0 -and -not $Variables.omit_token_privileges) {
                        # The 1st LUID_AND_ATTRIBUTES should be placed directly on the TOKEN_PRIVILEGES struct, the
                        # structure is copied after this loop.
                        $token_privileges.Privileges[0] = $landa
                        $Ptr = [System.IntPtr]::Add($Ptr, $Variables.tp_size)
                    } else {
                        # The remaining LUID_AND_ATTRIBUTES are copied manually to the end of the TOKEN_PRIVILEGES
                        # struct.
                        $Ptr = Copy-StructureToPointer -Ptr $Ptr -Structure $landa
                    }
                }

                # Now copy across the TOKEN_PRIVILEGES structure
                if (-not $Variables.omit_token_privileges) {
                    Copy-StructureToPointer -Ptr $token_privileges_ptr -Structure $token_privileges > $null
                }
            }

            &$Variables.process -Ptr $token_privileges_ptr -Variables $Variables.variables
        }
    }
}