---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Get-CurrentThreadId

## SYNOPSIS
Get the current thread identifier.

## SYNTAX

```
Get-CurrentThreadId [<CommonParameters>]
```

## DESCRIPTION
Gets the current thread identifier, otherwise known as the tid.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-CurrentThreadId
```

Gets the current thread id.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Int32
The thread id.

## NOTES

This identifier is not the same as the .NET managed thread id.
This is the system thread identifier, similar to the process id.

## RELATED LINKS

[GetCurrentThreadId](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentthreadid)
