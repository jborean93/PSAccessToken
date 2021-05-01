# PSAccessToken

[![Test workflow](https://github.com/jborean93/PSAccessToken/workflows/Test%20PSAccessToken/badge.svg)](https://github.com/jborean93/PSAccessToken/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/jborean93/PSAccessToken/branch/main/graph/badge.svg?token=b51IOhpLfQ)](https://codecov.io/gh/jborean93/PSAccessToken)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSAccessToken.svg)](https://www.powershellgallery.com/packages/PSAccessToken)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/jborean93/PSAccessToken/blob/main/LICENSE)


Various cmdlets that can be used to manipulate [Windows Access token](https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/access-tokens).

Better docs are forthcoming, this is still a work in progress.


## Info

TODO Link to docs


## Requirements

These cmdlets have the following requirements

* PowerShell v5.1 or newer
* Windows Server 2008 R2/Windows 7 or newer


## Installing

The easiest way to install this module is through
[PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview).

You can install this module by running;

```powershell
# Install for all users
Install-Module -Name PSAccessToken

# Install for only the current user
Install-Module -Name PSAccessToken -Scope CurrentUser
```


## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the changes.
To build this module run `.\build.ps1 -Task Build` in PowerShell.
To test a build run `.\build.ps1 -Task Test` in PowerShell.
This script will ensure all dependencies are installed before running the test suite.


## Backlog

* Expand tests
* Add way more cmdlets
