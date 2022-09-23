---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version: https://github.com/jborean93/PSAccessToken/blob/main/docs/en-US/Get-ThreadToken.md
schema: 2.0.0
---

# Get-ThreadToken

## SYNOPSIS

Gets the access token associated with a thread.

## SYNTAX

### Id (Default)
```
Get-ThreadToken [[-ThreadId] <Int32[]>] [[-Access] <TokenAccessRights>] [-OpenAsSelf] [<CommonParameters>]
```

### Handle
```
Get-ThreadToken [-Thread] <SafeHandle[]> [[-Access] <TokenAccessRights>] [-OpenAsSelf] [<CommonParameters>]
```

## DESCRIPTION

Gets the access token for the current or specific thread.
This may fail if the thread is not associated with any token, e.g. it's not impersonating anything.

## EXAMPLES

### Get access token for the current thread

```powershell
PS C:\> $token = Get-ThreadToken
```

Get the token for the current thread with Query rights.

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

### -OpenAsSelf

Will open the token using the security context of the process rather than the current thread.
Setting this switch allows the caller to open a thread token using the normal process context rather than the current thread impersonation context.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Thread

The thread handle, or list of handles, to get the access token for.
Use Get-TokenHandle to get a process handle for another process.
When omitted the access token for the current thread is used.

```yaml
Type: SafeHandle[]
Parameter Sets: Handle
Aliases: SafeHandle

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ThreadId

The thread id, or list of tids, to get the access token for.

```yaml
Type: Int32[]
Parameter Sets: Id
Aliases: Id

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Int32[]
The thread ids to get the access token for.

### System.Runtime.InteropServices.SafeHandle[]
The thread handles to get the access token for.

### PSAccessToken.TokenAccessRights
The desired access rights for the access token.

## OUTPUTS

### System.Runtime.InteropServices.SafeHandle
The access token that was opened. Make sure to call `.Dispose()` when finished with the token to close the unmanaged resource that it related to.

## NOTES

## RELATED LINKS

[OpenThreadToken](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openthreadtoken)
