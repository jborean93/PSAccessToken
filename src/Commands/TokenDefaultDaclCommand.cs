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
    [OutputType(new [] { typeof(TokenAccessRule), typeof(AuthorizationRuleCollection) })]
    public class TokenDefaultDaclCommand : TokenInfoBaseCommand
    {
        [Parameter()]
        [ValidateIdentityType()]
        public Type IdentityType { get; set; } = typeof(NTAccount);

        [Parameter()]
        public SwitchParameter NoEnumerate;

        protected override void TokenOperation(SafeHandle token)
        {
            RawAcl? rawDacl  = TokenInfo.GetDefaultDacl(token);
            if (rawDacl == null)
                return;

            AuthorizationRuleCollection dacl = new AuthorizationRuleCollection();
            foreach (CommonAce ace in rawDacl)
            {
                TokenAccessRule rule = new TokenAccessRule(
                    PrincipalHelper.Translate(ace.SecurityIdentifier, IdentityType),
                    (TokenAccessRights)ace.AccessMask,
                    ace.IsInherited,
                    ace.InheritanceFlags,
                    ace.PropagationFlags,
                    (AccessControlType)(int)ace.AceType
                );

                if (NoEnumerate)
                    dacl.AddRule(rule);
                else
                    WriteObject(rule);
            }

            if (NoEnumerate)
                WriteObject(dacl, false);
        }
    }
}
