---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Get-TokenImpersonationLevel

## SYNOPSIS
Get the impersonation level associated with an access token.

## SYNTAX

### CurrentIdentity (Default)
```
Get-TokenImpersonationLevel [-UseProcessToken] [<CommonParameters>]
```

### Token
```
Get-TokenImpersonationLevel [-Token] <SafeHandle[]> [<CommonParameters>]
```

### Process
```
Get-TokenImpersonationLevel [-ProcessId] <Int32[]> [<CommonParameters>]
```

### Thread
```
Get-TokenImpersonationLevel -ThreadId <Int32[]> [-OpenAsSelf] [<CommonParameters>]
```

## DESCRIPTION
Get the `TokenImpersonationLevel` associated with an access token.

## EXAMPLES

### Get the impersonation level of the current security context
```powershell
PS C:\> Get-TokenImpersonationLevel
```

Gets the impersonation level of the current security context.

## PARAMETERS

### -OpenAsSelf
Will open the thread id specified using the process level security context instead of the thread level context.

```yaml
Type: SwitchParameter
Parameter Sets: Thread
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProcessId
Gets the token impersonation level for the process specified.

```yaml
Type: Int32[]
Parameter Sets: Process
Aliases: Id

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ThreadId
Gets the token impersonation level for the thread specified.
The thread must be impersonating a token for this to be valid.

```yaml
Type: Int32[]
Parameter Sets: Thread
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Token
Gets the token impersonation level for the token handle specified.
This can be a process or thread token already retrieved or created.

```yaml
Type: SafeHandle[]
Parameter Sets: Token
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -UseProcessToken
Get the token impersonation level for the current process security context rather than the current thread impersonation context.

```yaml
Type: SwitchParameter
Parameter Sets: CurrentIdentity
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Runtime.InteropServices.SafeHandle[]
The process or token handle(s) to get the token impersonation level for.

### System.Int32[]
The process id(s) to get the token impersonation level for.

## OUTPUTS

### System.Security.Principal.TokenImpersonationLevel
The token impersonation level.
A primary token will have a level of `None`.

## NOTES

## RELATED LINKS

[GetTokenInformation](https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-gettokeninformation)
[TOKEN_INFORMATION_CLASS](https://docs.microsoft.com/en-us/windows/win32/api/winnt/ne-winnt-token_information_class)
[SECURITY_IMPERSONATION_LEVEL](https://docs.microsoft.com/en-us/windows/win32/api/winnt/ne-winnt-security_impersonation_level)
