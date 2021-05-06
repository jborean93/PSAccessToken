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
            DiscretionaryAcl? rawDacl  = TokenInfo.GetDefaultDacl(token);
            if (rawDacl == null)
                return;

            CommonSecurityDescriptor rawSd = new CommonSecurityDescriptor(
                false,
                false,
                ControlFlags.DiscretionaryAclPresent,
                null,
                null,
                null,
                rawDacl
            );

            TokenSecurity sec = new TokenSecurity(rawSd);
            WriteObject(sec.GetAccessRules(IdentityType));
        }
    }
}
