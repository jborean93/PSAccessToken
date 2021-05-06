using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "TokenType",
        DefaultParameterSetName = TokenInfoBaseCommand.DefaultParameterSetName
    )]
    [OutputType(typeof(TokenType))]
    public class TokenTypeCommand : TokenInfoBaseCommand
    {
        protected override void TokenOperation(SafeHandle token)
        {
            WriteObject(TokenInfo.GetTokenType(token));
        }
    }
}
