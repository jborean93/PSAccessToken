using System.Management.Automation;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.New, "TokenSecurity"
    )]
    [OutputType(typeof(IdentityReference))]
    public class TokenSecurityCommand : SecurityDescriptorBaseCommand<TokenSecurity>
    {
        protected override TokenSecurity CreateSecurityDescriptor(CommonSecurityDescriptor sd)
        {
            return new TokenSecurity(sd);
        }
    }
}
