---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Get-ThreadHandle

## SYNOPSIS
Get a handle to the current thread of the thread specified.

## SYNTAX

```
Get-ThreadHandle [[-ThreadId] <Int32[]>] [[-Access] <ThreadAccessRights>] [-Inherit] [<CommonParameters>]
```

## DESCRIPTION
Gets a handle to the current thread of the thread specified.
This handle can be used for further actions on the thread that was opened.
When no parameters ares specified then the handle is a psuedo handle with full access rights to the current thread.

## EXAMPLES

### Get current thread handle
```powershell
PS C:\> $handle = Get-ThreadHandle
```

Gets the handle to the current thread with `AllAccess` rights.

### Get thread handle for another thread
```powershell
PS C:\> $handle = Get-ThreadHandle -ThreadId 1234
```

Gets the handle to the thread with the TID of 1234.

### Get thread handle for another thread with custom access rights
```powershell
PS C:\> $handle = Get-ThreadHandle -ThreadId 1234 -Access Impersonate, QueryInformation
```

Gets the handle to the thread with the TID of 1234 with Impersonate and QueryInformation access rights.

## PARAMETERS

### -Access
The desired access rights to the thread object.
The default is `QueryInformation` which allows you to query information about the process.
If specified without a `ThreadId` then the thread handle is for the current thread with the access specified.

```yaml
Type: ThreadAccessRights
Parameter Sets: (All)
Aliases:
Accepted values: Terminate, SuspendResume, GetContext, SetContext, SetInformation, QueryInformation, SetThreadToken, Impersonate, DirectImpersonation, SetLimitedInformation, QueryLimitedInformation, Delete, ReadControl, WriteDAC, WriteOwner, StandardRightsRequired, Synchronize, AllAccess, AccessSystemSecurity

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Inherit
The handle can be inherited by any child processes spawned by the caller process.
When specified without a `ThreadId` then the thread handle is for the current thread that is inheritable.

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

### -ThreadId
The thread ID, or list of, to open the handle for.

```yaml
Type: Int32[]
Parameter Sets: (All)
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
The thread ID(s) to open the handle for.

### PSAccessToken.ThreadAccessRights
The desired access rights for the opened thread handle.

## OUTPUTS

### System.Runtime.InteropServices.SafeHandle
The wrapped SafeHandle of the thread. This handle should be explicitly disposed with the `.Dispose()` method as soon as it isn't needed.

## NOTES

## RELATED LINKS

[GetCurrentThread](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentthread)

[OpenThread](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openthread)
