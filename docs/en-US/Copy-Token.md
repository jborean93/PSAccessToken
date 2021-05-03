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
 [-SecurityDescriptor <NativeObjectSecurity>] [-ImpersonationLevel <SecurityImpersonationLevel>]
 [-TokenType <TokenType>] [<CommonParameters>]
```

## DESCRIPTION
Copies an access token while setting whther it's a primary or impersonation token.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Access
{{ Fill Access Description }}

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
{{ Fill ImpersonationLevel Description }}

```yaml
Type: SecurityImpersonationLevel
Parameter Sets: (All)
Aliases:
Accepted values: Anonymous, Identification, Impersonation, Delegation

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inherit
{{ Fill Inherit Description }}

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
{{ Fill SecurityDescriptor Description }}

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
{{ Fill Token Description }}

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
{{ Fill TokenType Description }}

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
## OUTPUTS

### System.Runtime.InteropServices.SafeHandle
## NOTES

## RELATED LINKS
