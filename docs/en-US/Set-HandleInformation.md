---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version: https://github.com/jborean93/PSAccessToken/blob/main/docs/en-US/Set-HandleInformation.md
schema: 2.0.0
---

# Set-HandleInformation

## SYNOPSIS

Sets certain property of a Windows handle.

## SYNTAX

```
Set-HandleInformation [-Handle] <SafeHandle[]> [-Inherit] [-ProtectFromClose] [-Clear] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Sets the Inherit or ProtectFromClose properties of a Windows handle.

## EXAMPLES

### Set a handle as inheritable

```powershell
PS C:\> $handle = Get-ProcessHandle -ProcessId 1234
PS C:\> Set-HandleInformation -Handle $handle -Inherit
```

Sets the specified handles are inheritable, keeping any existing flags.

### Set a handle with protect from close and clear other flags

```powershell
PS C:\> $handle = Get-ProcessHandle -ProcessId 1234
PS C:\> Set-HandleInformation -Handle $handle -ProtectFromClose -Clear
```

Protects the handle from being closed and clears any other flags like Inherit.

### Clear all handle flags

```powershell
PS C:\> $handle = Get-ProcessHandle -ProcessId 1234
PS C:\> Set-HandleInformation -Handle $handle -Clear
```

Clears the Inherit and ProtectFromClose flags on the handle.

## PARAMETERS

### -Clear

When set then all the existing flags will be unset except for the parameters specified.
When unset, or not specified, the parameters specified add to the existing flags already set.
Use this to clear any existing handle flags you don't want to be set.

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

### -Handle

The handle, or list of handles, to set the information on.

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

### -Inherit

Whether to set the Inherit flag on the handle(s) specified.

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

### -ProtectFromClose

Whether to set the ProtectFromClose flag on the handle(s) specified.

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

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

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
The handles to set the information on.

## OUTPUTS

### None
## NOTES

## RELATED LINKS

[SetHandleInformation](https://docs.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-sethandleinformation)
