---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version: https://github.com/jborean93/PSAccessToken/blob/main/docs/en-US/Exit-TokenContext.md
schema: 2.0.0
---

# Exit-TokenContext

## SYNOPSIS

Exits the current thread impersonation context.

## SYNTAX

```
Exit-TokenContext [<CommonParameters>]
```

## DESCRIPTION

Exits the current thread impersonation context set up by `Enter-TokenContext

## EXAMPLES

### Example 1 Exit the current thread impersonation context

```powershell
[DOMAIN\Username] PS C:\> Exit-TokenContext
```

Exits the currently set up thread impersonation context.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[RevertToSelf](https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-reverttoself)
