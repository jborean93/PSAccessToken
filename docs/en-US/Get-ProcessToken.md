---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Get-ProcessToken

## SYNOPSIS
Gets the access token associated with a process.

## SYNTAX

```
Get-ProcessToken [[-Process] <SafeHandle[]>] [[-Access] <TokenAccessRights>] [<CommonParameters>]
```

## DESCRIPTION
Gets the access token for the current or specific process.

## EXAMPLES

### Get access token for the current process
```powershell
PS C:\> $token = Get-ProcessToken
```

Get the token for the current process with Query rights.

## PARAMETERS

### -Access
The desired access for the access token.
Defaults to Query which can be used to retrieve most readonly properties of a token.

```yaml
Type: TokenAccessRights
Parameter Sets: (All)
Aliases:
Accepted values: AssignPrimary, Duplicate, Impersonate, Query, QuerySource, AdjustPrivileges, AdjustGroups, AdjustDefault, AdjustSessionId, Delete, ReadControl, Execute, Read, Write, WriteDAC, WriteOwner, StandardRightsRequired, AllAccess, AccessSystemSecurity

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Process
The process handle, or list of handles, to get the access token for.
Use Get-ProcessHandle to get a process handle for another process.
When omitted the access token for the current process is used.

```yaml
Type: SafeHandle[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Runtime.InteropServices.SafeHandle[]
The process handles to get the access token for.

### PSAccessToken.TokenAccessRights
The desired access rights for the access token.

## OUTPUTS

### System.Runtime.InteropServices.SafeHandle
The access token that was opened. Make sure to call `.Dispose()` when finished with the token to close the unmanaged resource that it relates to.

## NOTES

## RELATED LINKS

[OpenProcessToken](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocesstoken)
