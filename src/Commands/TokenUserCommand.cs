using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "TokenUser",
        DefaultParameterSetName = TokenInfoBaseCommand.DefaultParameterSetName
    )]
    [OutputType(typeof(IdentityReference))]
    public class TokenUserCommand : TokenInfoBaseCommand
    {
        [Parameter()]
        [ValidateIdentityType()]
        public Type IdentityType { get; set; } = typeof(NTAccount);

        protected override void TokenOperation(SafeHandle token)
        {
            SecurityIdentifier sid = TokenInfo.GetUser(token);

            try
            {
                WriteObject(sid.Translate(IdentityType));
            }
            catch (IdentityNotMappedException e)
            {
                ErrorRecord err = new ErrorRecord(e, String.Format("Get-TokenUser.{0}", nameof(e)),
                    ErrorCategory.InvalidType, sid);
                err.ErrorDetails = new ErrorDetails(String.Format("Failed to translate {0} to {1}: {2}",
                    sid.Value, IdentityType.Name, e.Message));

                WriteError(err);
            }
        }
    }
}
