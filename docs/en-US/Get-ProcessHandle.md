---
external help file: PSAccessToken.dll-Help.xml
Module Name: PSAccessToken
online version:
schema: 2.0.0
---

# Get-ProcessHandle

## SYNOPSIS
Get a handle to the current process or the process specified.

## SYNTAX

### Current (Default)
```
Get-ProcessHandle [-Current] [<CommonParameters>]
```

### Explicit
```
Get-ProcessHandle [-ProcessId] <Int32[]> [[-Access] <ProcessAccessRights>] [-Inherit] [<CommonParameters>]
```

## DESCRIPTION
Gets a handle to the current process or the process specified.
This handle can be used for further actions on the process that was opened.
When no parameters, or `-Current`, is specified then the handle is a pseudo handle with full access rights to the current process.
When `-Id` is specified then it will get the handle to the process with that ID with the access rights specified.

## EXAMPLES

### Get current process handle
```powershell
PS C:\> $handle = Get-ProcessHandle
```

Gets the handle to the current process with `AllAccess` rights.

### Get process handle for another process
```powershell
PS C:\> $handle = Get-ProcessHandle -ProcessId 1234
```

Gets the handle to the process with the PID of 1234.

### Get process handle for another process with custom access rights
```powershell
PS C:\> $handle = Get-ProcessHandle -ProcessId 1234 -Access DupHandle, QueryInformation
```

Gets the handle to the process with the PID of 1234 with DupHandle and QueryInformation access rights.

## PARAMETERS

### -Access
The desired access rights to the process object.
The default is `QueryInformation` which allows you to query information about the process.

```yaml
Type: ProcessAccessRights
Parameter Sets: Explicit
Aliases:
Accepted values: Terminate, CreateThread, VMOperation, VMRead, VMWrite, DupHandle, CreateProcess, SetQuota, SetInformation, QueryInformation, SuspendResume, QueryLimitedInformation, Delete, ReadControl, WriteDAC, WriteOwner, StandardRightsRequired, Synchronize, AllAccess, AccessSystemSecurity

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Current
Gets the handle to the current process with AllAccess rights and no inheritance.
This is the default action even when the switch isn't provided and is only used to differenciate between parameter set.

```yaml
Type: SwitchParameter
Parameter Sets: Current
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inherit
The handle can be inherited by any child processes spawned by the caller process.

```yaml
Type: SwitchParameter
Parameter Sets: Explicit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProcessId
The process ID, or list of, to open the handle for.

```yaml
Type: Int32[]
Parameter Sets: Explicit
Aliases: Id

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Int32[]
The process ID(s) to open the handle for.

### PSAccessToken.ProcessAccessRights
The desired access rights for the opened process handle.

## OUTPUTS

### System.Runtime.InteropServices.SafeHandle
The wrapped SafeHandle of the process. This handle should be explicitly disposed with the `.Dispose()` method as soon as it isn't needed.

## NOTES

## RELATED LINKS

[GetCurrentProcess](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess)

[OpenProcess](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess)
