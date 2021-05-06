using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "TokenImpersonationLevel",
        DefaultParameterSetName = TokenInfoBaseCommand.DefaultParameterSetName
    )]
    [OutputType(typeof(TokenImpersonationLevel))]
    public class TokenImpersonationLevelCommand : TokenInfoBaseCommand
    {
        protected override void TokenOperation(SafeHandle token)
        {
            WriteObject(TokenInfo.GetImpersonationLevel(token));
        }
    }
}
