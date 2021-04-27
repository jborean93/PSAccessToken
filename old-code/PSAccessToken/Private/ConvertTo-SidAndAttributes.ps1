# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function ConvertTo-SidAndAttributes {
    <#
    .SYNOPSIS
    Used to create a basic representation of a SID_AND_ATTRIBUTES structure. This is a helper method used by cmdlets
    that take in a Groups/Sids input and transforms it into a common object that Use-TokenGroupsPointer can understand.
    This is not to be confused with Convert-PointerToSidAndAttributes which takes in a pointer and creates the
    PSAccessToken.SidAndAttributes object for outside consumption.

    .PARAMETER InputObject
    The object to convert, this can be a string or hashtable with the keys Sid, and Attributes.

    .PARAMETER DefaultAttributes
    The attributes to apply if a string input or the Attributes key is not set on the input object.
    #>
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called SID_AND_ATTRIBUTES"
    )]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Object]
        $InputObject,

        [Parameter(Mandatory=$true)]
        [PSAccessToken.TokenGroupAttributes]
        $DefaultAttributes
    )

    Process {
        $attributes = $DefaultAttributes
        if ($InputObject -is [System.Collections.IDictionary]) {
            if (-not $InputObject.ContainsKey('Sid')) {
                throw "Groups entry does not contain key 'Sid'"
            }
            $sid = $InputObject.Sid

            if ($InputObject.ContainsKey('Attributes')) {
                $attributes = $InputObject.Attributes
            }
        } elseif ($InputObject -is [System.Management.Automation.PSCustomObject]) {
            $properties = $InputObject.PSObject.Properties.Name
            if ('Sid' -notin $properties){
                throw "Groups entry does not contain key 'Sid'"
            }
            $sid = $InputObject.Sid

            if ('Attributes' -in $properties) {
                $attributes = $InputObject.Attributes
            }
        } else {
            $sid = $InputObject
        }

        $sid = ConvertTo-SecurityIdentifier -InputObject $sid
        @{
            Sid = $sid
            Attributes = [PSAccessToken.TokenGroupAttributes]$attributes
        }
    }
}