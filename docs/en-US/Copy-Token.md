---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Copy-Token

## SYNOPSIS
Copies an access token.

## SYNTAX

```
Copy-Token [-Token] <SafeHandle[]> [-Access <TokenAccessRights>] [-Inherit]
 [-SecurityDescriptor <NativeObjectSecurity>] [-ImpersonationLevel <TokenImpersonationLevel>]
 [-TokenType <TokenType>] [<CommonParameters>]
```

## DESCRIPTION
Copies an access token while setting whether it's a primary or impersonation token.

## EXAMPLES

### Creates a primary access token
```powershell
PS C:\> $newToken = Copy-Token -Token $existing
```

Creates a primary access token copy of the existing token while granting the new copy the same access rights as the existing token.

### Creates an impersonation token with Delegation rights
```powershell
PS C:\> $newToken = Copy-Token -Token $existing -TokenType Impersonation -ImpersonationLevel Delegation
```

Creates an impersonation access token with delegation rights.

### Creates an inheritable token
```powershell
PS C:\> $newToken = Copy-Token -Token $existing -Inherit
```

Creates a primary access token of the existing that is also inheritable to child processes.

### Creates a token with different access rights
```powershell
PS C:\> $newToken = Copy-Token -Token $existing -Access Query, Duplicate
```

Creates a copy of the existing token that has the `Query` and `Duplicate` access rights.

## PARAMETERS

### -Access
The token access to assign to the copied token that is created.
When not set it will use the access that the input token current has.

```yaml
Type: TokenAccessRights
Parameter Sets: (All)
Aliases:
Accepted values: AssignPrimary, Duplicate, Impersonate, Query, QuerySource, AdjustPrivileges, AdjustGroups, AdjustDefault, AdjustSessionId, Delete, ReadControl, Execute, Read, Write, WriteDAC, WriteOwner, StandardRightsRequired, AllAccess, AccessSystemSecurity

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImpersonationLevel
The impersonation level used when creating an impersonation type token.
When creating a `Primary` token this can only be set, and defaults to, `None`.
When creating an `Impersonation` token this defaults to `Impersonation` and cannot be set to `None`.

```yaml
Type: TokenImpersonationLevel
Parameter Sets: (All)
Aliases:
Accepted values: None, Anonymous, Identification, Impersonation, Delegation

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inherit
Whether the duplicated token can be inherited to any child processes spawned by the caller.

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

### -SecurityDescriptor
The security descriptor to apply to the token copy created.
If a SACL is present on the security descriptor then the `AccessSystemSecurity` access mask is also applied to the new token.

```yaml
Type: NativeObjectSecurity
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Token
The token to duplicate.
This token must have been opened with `Duplicate` access.

```yaml
Type: SafeHandle[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -TokenType
The type of token that the copy becomes.

```yaml
Type: TokenType
Parameter Sets: (All)
Aliases:
Accepted values: Primary, Impersonation

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
The access token(s) to duplicate.

## OUTPUTS

### System.Runtime.InteropServices.SafeHandle
The access token that was duplicated.


## NOTES
The copied token is a new handle, it should be cleaned up with `.Dispose()` as soon as it is no longer needed.

## RELATED LINKS

[DuplicateTokenEx](https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-duplicatetokenex)
