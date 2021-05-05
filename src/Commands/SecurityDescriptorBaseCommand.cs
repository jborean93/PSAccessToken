using System;
using System.Collections;
using System.Management.Automation;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    internal class AuthzCollectionTransformation : ArgumentTransformationAttribute {

        public override object? Transform(EngineIntrinsics engineIntrinsics, object inputData)
        {
            if (inputData == null)
                return null;
            else if (inputData is AuthorizationRuleCollection)
                return inputData;

            bool fail = false;
            AuthorizationRuleCollection acl = new AuthorizationRuleCollection();
            if (inputData is AuthorizationRule)
                acl.AddRule((AuthorizationRule)inputData);

            else if (inputData is IList)
            {
                foreach (object? ace in (IList)inputData)
                {
                    if (ace is AuthorizationRule)
                        acl.AddRule((AuthorizationRule)ace);
                    else
                    {
                        fail = true;
                        break;
                    }
                }
            }
            else
                fail = true;

            if (fail)
                throw new ArgumentTransformationMetadataException(
                    "Could not convert input to a valid AuthorizationRuleCollection object.");

            return acl;
        }
    }

    public abstract class SecurityDescriptorBaseCommand<T> : PSCmdlet
        where T : NativeSecurity
    {
        [Parameter()]
        public IdentityReference? Owner { get; set; }

        [Parameter()]
        public IdentityReference? Group { get; set; }

        [Parameter()]
        [AuthzCollectionTransformation()]
        [AllowEmptyCollection()]
        public AuthorizationRuleCollection? Access { get; set; }

        protected override void EndProcessing()
        {
            using (var token = NativeMethods.OpenProcessToken(0, TokenAccessRights.Query))
            {
                if (Owner == null)
                    Owner = TokenInfo.GetOwner(token);

                if (Group == null)
                    Group = TokenInfo.GetPrimaryGroup(token);
            }

            T sec = CreateEmptySecurityDescriptor();
            sec.SetOwner(Owner);
            sec.SetGroup(Group);

            // TODO: Deal with null DACL compared to empty DACL.
            if (Access != null)
            {
                AccessRule[] acl = new AccessRule[Access.Count];
                Access.CopyTo(acl, 0);

                foreach (AccessRule ace in acl)
                    sec.AddAccessRule(ace);
            }

            WriteObject(sec);
        }

        protected abstract T CreateEmptySecurityDescriptor();
    }
}
