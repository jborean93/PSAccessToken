using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.New, "TokenSecurity"
    )]
    [OutputType(typeof(IdentityReference))]
    public class TokenSecurityCommand : SecurityDescriptorBaseCommand<TokenSecurity>
    {
        protected override TokenSecurity CreateEmptySecurityDescriptor()
        {
            return new TokenSecurity();
        }
    }
}
