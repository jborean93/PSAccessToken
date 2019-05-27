# PSAccessToken

[![Build status](https://ci.appveyor.com/api/projects/status/f9fbq0361snk5oxs?svg=true)](https://ci.appveyor.com/project/jborean93/psaccesstoken)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSAccessToken.svg)](https://www.powershellgallery.com/packages/PSAccessToken)

Various cmdlets that can be used to manipulate [Windows Access token](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/access-tokens).

Better docs are forthcoming, this is still a work in progress.


## Info

Cmdlets included with this module are;

* `Copy-AccessToken`: Makes a copy of an existing access token with the ability to change the impersonation level.
* `Get-LogonsessionData`: Get the logon session data for the current process/thread or the token specified.
* `Get-ProcessHandle`: Get a handle on the current process or an explicit process based on the PID.
* `Get-ThreadHandle`: Get a handle on the current thread or an explicit thread based on the TID.
* `Invoke-LogonUser`: Logs on an account through LSA and returns the access token and other logon info back.
* `Invoke-WithImpersonation`: Invokes a scriptblock like [Invoke-Command](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/invoke-command?view=powershell-6) but under the security context of an access token.
* `New-AccessToken`: Creates a new access token with any combination of user, groups, privileges, etc.
* `New-LowBoxToken`: Creates a copy of an existing token as a "Low Box" token with a Low integrity level and set of Capabilities.
* `New-RestrictedToken`: Creates a restricted copy of an existing access token, with various groups or privileges, removed or restricted.
* `Open-ProcessToken`: Opens a process handle to get the access token inside.
* `Open-ThreadToken`: Opens a thread handle to get the access token inside.

There are also cmdlets to get and set individual accesstoken elements. These
cmdlets are;

* `Get-Token*`: Get information from an access token
* `Set-Token*`: Set information on an access token, only certain classes can have information changed.

Each cmdlet follow the form `Get/Set-<TokenInfoClass>` where `TokenInfoClass`
is a value from [TOKEN_INFORMATION_CLASS](https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ne-winnt-_token_information_class).

Run `Get-Command -Name Get-Token*, Set-Token* -Module PSAccessToken` to get a
list of all cmdlets that can be called.


## Requirements

These cmdlets have the following requirements

* PowerShell v3.0 or newer
* Windows PowerShell (not PowerShell Core)
* Windows Server 2008/Windows 7 or newer


## Installing

The easiest way to install this module is through
[PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview).
This is installed by default with PowerShell 5 but can be added on PowerShell
3 or 4 by installing the MSI [here](https://www.microsoft.com/en-us/download/details.aspx?id=51451).

Once installed, you can install this module by running;

```
# Install for all users
Install-Module -Name PSAccessToken

# Install for only the current user
Install-Module -Name PSAccessToken -Scope CurrentUser
```

If you wish to remove the module, just run
`Uninstall-Module -Name PSAccessTOken`.

If you cannot use PowerShellGet, you can still install the module manually,
here are some basic steps on how to do this;

1. Download the latext zip from GitHub [here](https://github.com/jborean93/PSAccessToken/releases/latest)
2. Extract the zip
3. Copy the folder `PSAccessToken` inside the zip to a path that is set in `$env:PSModulePath`. By default this could be `C:\Program Files\WindowsPowerShell\Modules` or `C:\Users\<user>\Documents\WindowsPowerShell\Modules`
4. Reopen PowerShell and unblock the downloaded files with `$path = (Get-Module -Name PSAccessToken -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1;`
5. Reopen PowerShell one more time and you can start using the cmdlets

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable `PSModulePath` if you want to use another path._


## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the
changes. To test out your changes locally you can just run `.\build.ps1` in
PowerShell. This script will ensure all dependencies are installed before
running the test suite.

The tests are expected to be run as an Administrative account that has UAC
enabled and applied to the current user.

_Note: this requires PowerShellGet or WMF 5 to be installed_


## Backlog

* Generate docs based on cmdlet doc string
* Finish off the rest of the `Get-Token*` cmdlets
* Finish off the rest of the `Set-Token*` cmdlets
* Add cmdlet to call `CheckTokenMembership` to check if a SID is enabled on the specified access token
* Create a release once the majority of the above works
* Change Installing example to download the combined module from PSGallery on the manual step instead of GitHub
