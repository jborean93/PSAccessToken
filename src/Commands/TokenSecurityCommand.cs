using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "TokenSecurity"
    )]
    [OutputType(typeof(TokenSecurity))]
    public class GetTokenSecurityCommand : TokenInfoBaseCommand
    {
        protected override TokenAccessRights RequiredRights
        {
            get
            {
                TokenAccessRights rights = TokenAccessRights.ReadControl;
                if (Audit)
                    rights |= TokenAccessRights.AccessSystemSecurity;

                return rights;
            }
        }

        [Parameter()]
        public SwitchParameter Audit { get; set; }

        protected override void TokenOperation(SafeHandle token)
        {
            AccessControlSections sections = AccessControlSections.Group |
                AccessControlSections.Owner |
                AccessControlSections.Access;
            if (Audit)
                sections |= AccessControlSections.Audit;

            WriteObject(new TokenSecurity(token, sections));
        }
    }

    [Cmdlet(
        VerbsCommon.New, "TokenSecurity"
    )]
    [OutputType(typeof(IdentityReference))]
    public class NewTokenSecurityCommand : SecurityDescriptorBaseCommand<TokenSecurity>
    {
        protected override TokenSecurity CreateSecurityDescriptor(CommonSecurityDescriptor sd)
        {
            return new TokenSecurity(sd);
        }
    }

    [Cmdlet(
        VerbsCommon.Set, "TokenSecurity",
        SupportsShouldProcess = true
    )]
    public class SetTokenSecurityCommand : TokenInfoBaseCommand
    {
        protected override TokenAccessRights RequiredRights
        {
            get
            {
                TokenAccessRights rights = TokenAccessRights.WriteDAC;
                if (Acl != null)
                {
                    if (Acl.GetOwner(typeof(SecurityIdentifier)) != null)
                        rights |= TokenAccessRights.WriteOwner;

                    // TODO: Implement support for SACL
                    // rights |= TokenAccessRights.AccessSystemSecurity;
                }

                return rights;
            }
        }

        [Parameter(
            Mandatory = true,
            Position = 1
        )]
        public TokenSecurity Acl { get; set; } = new TokenSecurity();

        protected override void TokenOperation(SafeHandle token)
        {
            AccessControlSections sections = AccessControlSections.Access;
            if (Acl.GetOwner(typeof(SecurityIdentifier)) != null)
                sections |= AccessControlSections.Owner;

            if (Acl.GetGroup(typeof(SecurityIdentifier)) != null)
                sections |= AccessControlSections.Group;

            // TODO: Support Audit
            if (ShouldProcess(string.Format("Token {0}", (Int64)token.DangerousGetHandle()), "SetSD"))
                Acl.Persist(token, sections);
        }
    }
}
