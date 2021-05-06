using System;
using System.Collections;
using System.Management.Automation;
using System.Reflection;
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
        private static readonly PropertyInfo s_AccessMaskProp = Reflection.GetProperty(
            typeof(AccessRule),
            "AccessMask",
            BindingFlags.NonPublic | BindingFlags.Instance
        );

        [Parameter()]
        public IdentityReference? Owner { get; set; }

        [Parameter()]
        public IdentityReference? Group { get; set; }

        [Parameter()]
        [AuthzCollectionTransformation()]
        [AllowEmptyCollection()]
        [AllowNull()]
        public AuthorizationRuleCollection? Access { get; set; }

        protected override void EndProcessing()
        {
            DiscretionaryAcl? dacl = null;
            using (var token = NativeMethods.OpenProcessToken(0, TokenAccessRights.Query))
            {
                if (Owner == null)
                    Owner = TokenInfo.GetOwner(token);

                if (Group == null)
                    Group = TokenInfo.GetPrimaryGroup(token);

                if (Access == null)
                    // If null was explicitly set then create a null DACL.
                    if (MyInvocation.BoundParameters.ContainsKey("Access"))
                        dacl = SecurityHelper.CreateNullDacl();
                    else
                        dacl = TokenInfo.GetDefaultDacl(token);
            }

            if (Access != null)
            {
                dacl = new DiscretionaryAcl(false, false, 0, Access.Count);

                AccessRule[] aces = new AccessRule[Access.Count];
                Access.CopyTo(aces, 0);
                foreach (AccessRule ace in aces)
                {
                    dacl.AddAccess(
                        ace.AccessControlType,
                        ConvertToSid(ace.IdentityReference),
                        Reflection.GetPropertyValue<int>(s_AccessMaskProp, ace),
                        ace.InheritanceFlags,
                        ace.PropagationFlags
                    );
                }
            }

            CommonSecurityDescriptor rawSec = new CommonSecurityDescriptor(
                false,
                false,
                ControlFlags.DiscretionaryAclPresent,
                ConvertToSid(Owner),
                ConvertToSid(Group),
                null,  // TODO: SACL
                dacl
            );
            T sec = CreateSecurityDescriptor(rawSec);

            WriteObject(sec);
        }

        private SecurityIdentifier ConvertToSid(IdentityReference id)
        {
            return (SecurityIdentifier)SecurityHelper.TranslateIdentifier(id, typeof(SecurityIdentifier), true);
        }

        protected abstract T CreateSecurityDescriptor(CommonSecurityDescriptor sd);
    }
}
