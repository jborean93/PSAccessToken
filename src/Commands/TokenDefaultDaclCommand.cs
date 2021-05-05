using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "TokenDefaultDacl",
        DefaultParameterSetName = TokenInfoBaseCommand.DefaultParameterSetName
    )]
    [OutputType(typeof(AuthorizationRuleCollection))]
    public class TokenDefaultDaclCommand : TokenInfoBaseCommand
    {
        [Parameter()]
        [ValidateIdentityType()]
        public Type IdentityType { get; set; } = typeof(NTAccount);

        protected override void TokenOperation(SafeHandle token)
        {
            RawAcl? rawDacl  = TokenInfo.GetDefaultDacl(token);
            if (rawDacl == null)
                return;

            TokenSecurity sec = new TokenSecurity();
            AuthorizationRuleCollection dacl = PrincipalHelper.TranslateRawAcl(rawDacl, IdentityType, sec);
            WriteObject(dacl, false);
        }
    }
}
