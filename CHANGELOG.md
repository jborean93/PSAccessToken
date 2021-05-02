# Changelog for PInvokeHelper

## v0.2.0 - TBD

* Changed `Open-ProcessToken` to `Get-ProcessToken`
* Added the following cmdlet:
  * [Enter-TokenContext](docs/en-US/Enter-TokenContext.md) - Sets the thread security context to the token specified
  * [Exit-TokenContext](docs/en-US/Exit-TokenContext.md) - Exits the thread security context that has been entered
  * [Get-CurrentThreadId](docs/en-US/Get-CurrentThreadId.md) - Gets the Thread ID of the current thread
  * [Get-ThreadToken](docs/en-US/Get-ThreadToken.md) - Gets the access token for the thread specified
  * [Get-TokenUser](docs/en-US/Get-TokenUser.md) - Gets the username of the token specified


## v0.1.0 - 2021-05-01

* Initial version of the `PSAccessToken` module
