---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Get-HandleInformation

## SYNOPSIS
Get information on a Windows handle.

## SYNTAX

```
Get-HandleInformation [-Handle] <SafeHandle[]> [<CommonParameters>]
```

## DESCRIPTION
Get handle information such as whether it is inheritable or protected from being closed.

## EXAMPLES

### Get handle information
```powershell
PS C:\> $handle = Get-ProcessHandle -ProcessId 1234
PS C:\> Get-HandleInformation -Handle $handle
```

Gets the handle flags for the opened process handle.

## PARAMETERS

### -Handle
The handle, or list of handles, to get the handle information for.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Runtime.InteropServices.SafeHandle[]
The handls to get the handle information for.

## OUTPUTS

### PSAccessToken.HandleFlags
The flags that apply to that handle. There are 3 flags that can be set

* None: No flags are set

* Inherit: A child process created with the inherit handles option will inherit this handle

* ProtectFromClose: Closing/disposing the handle will not work with this flag set

## NOTES

## RELATED LINKS

[GetHandleInformation](https://docs.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-gethandleinformation)
