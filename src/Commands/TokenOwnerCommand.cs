using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "TokenOwner",
        DefaultParameterSetName = TokenInfoBaseCommand.DefaultParameterSetName
    )]
    [OutputType(typeof(IdentityReference))]
    public class TokenOwnerCommand : TokenInfoBaseCommand
    {
        [Parameter()]
        [ValidateIdentityType()]
        public Type IdentityType { get; set; } = typeof(NTAccount);

        protected override void TokenOperation(SafeHandle token)
        {
            SecurityIdentifier sid = TokenInfo.GetOwner(token);
            WriteObject(PrincipalHelper.TranslateIdentifier(sid, IdentityType));
        }
    }
}
