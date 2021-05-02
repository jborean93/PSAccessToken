---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Enter-TokenContext

## SYNOPSIS
Enter a token impersonation context on the calling thread.

## SYNTAX

### Process (Default)
```
Enter-TokenContext [[-ProcessId] <Int32>] [<CommonParameters>]
```

### Thread
```
Enter-TokenContext [-ThreadId <Int32>] [-OpenAsSelf] [<CommonParameters>]
```

### Token
```
Enter-TokenContext [[-Token] <SafeHandle>] [<CommonParameters>]
```

## DESCRIPTION
Impersonate the security context of the process, thread, or explicit token in the current thread.
Only one token context can be impersonated at a time, call `Exit-TokenContext` to diable impersonation.

## EXAMPLES

### Impersonate the current process
```powershell
PS C:\> Enter-TokenContext
```

Impersonate the current process in the current thread.
This is useful for enabling/disabling privileges for the current thread instead of process wise.

## PARAMETERS

### -OpenAsSelf
Opens the thread token using the current process security context rather than the current thread one.

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
Impersonates the specified process.
If omitted then the current process is impersonated.

```yaml
Type: Int32
Parameter Sets: Process
Aliases: Id

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ThreadId
Impersonates the specified thread, will fail if the thread does not have a token assigned to it.

```yaml
Type: Int32
Parameter Sets: Thread
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Token
Impersonates the specified token.
The token must have `Duplicate` and `Query` rights if it's a primary token and `Impersonate` and `Query` rights if it's an impersonation token.

```yaml
Type: SafeHandle
Parameter Sets: Token
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

### System.Runtime.InteropServices.SafeHandle

The token handle to impersonate.

### System.Int32

The process id of the process to impersonate.

## OUTPUTS

### System.Object
## NOTES

Entering a security context changes the current prompt to show the username of that context in the prompt message.

## RELATED LINKS

[ImpersonateLoggedOnUser](https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-impersonateloggedonuser)
