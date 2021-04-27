# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Copy-StructureToPointer {
    <#
    .SYNOPSIS
    Copies a structure to a pointer with unmanaged memory.

    .PARAMETER Ptr
    The pointer to copy the struct to. This should be allocated with enough memory to fit the structure.

    .PARAMETER Structure
    The structure to copy.
    #>
    [OutputType([System.IntPtr])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr,

        [Parameter(Mandatory=$true)]
        [Object]
        $Structure
    )

    # The non-deprecated StructureToPtr method uses a generic type. Need to use Reflection to get the method and invoke
    # it. Would love to use GetMethod() but this seems to choke on generic methods with generic type parameters.
    $method = [System.Runtime.InteropServices.Marshal].GetMethods('Public, Static') | Where-Object {
        if ($_.Name -ne 'StructureToPtr' -or -not $_.IsGenericMethod) {
            return $false
        }

        $parameter_types = $_.GetParameters().ParameterType
        return ($parameter_types.Count -eq 3 -and $parameter_types[0].Name -eq 'T' -and
            $parameter_types[1] -eq [System.IntPtr] -and $parameter_types[2] -eq [System.Boolean])
    }
    $g_method = $method.MakeGenericMethod($Structure.GetType())
    $g_method.Invoke($null, @($Structure, $Ptr, $false)) > $null

    return [System.IntPtr]::Add($Ptr, [System.Runtime.InteropServices.Marshal]::SizeOf($Structure))
}