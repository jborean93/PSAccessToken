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

            if (inputData is PSObject)
                inputData = ((PSObject)inputData).BaseObject;

            if (inputData is AuthorizationRuleCollection)
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
                    // In all scenarios a NULL DACL means we use the default DACL value
                    dacl = TokenInfo.GetDefaultDacl(token);
            }

            if (Access != null)
            {
                dacl = new DiscretionaryAcl(false, false, 2, Access.Count);

                foreach (AccessRule? ace in Access)
                {
                    if (ace == null)
                    {
                        WriteError(new ErrorRecord(
                            new ArgumentNullException("Access contains null rule"),
                            String.Format("{0}.{1}", MyInvocation.MyCommand.Name, nameof(ArgumentException)),
                            ErrorCategory.InvalidData,
                            Access
                        ));
                        return;
                    }

                    SecurityIdentifier sid;
                    try
                    {
                        sid = ConvertToSid(ace.IdentityReference);
                    }
                    catch (IdentityNotMappedException e)
                    {
                        WriteIdentityNotMappedError(e, ace.IdentityReference);
                        return;
                    }

                    dacl.AddAccess(
                        ace.AccessControlType,
                        ConvertToSid(ace.IdentityReference),
                        Reflection.GetPropertyValue<int>(s_AccessMaskProp, ace),
                        ace.InheritanceFlags,
                        ace.PropagationFlags
                    );
                }
            }

            SecurityIdentifier ownerSid;
            try
            {
                ownerSid = ConvertToSid(Owner);
            }
            catch (IdentityNotMappedException e)
            {
                WriteIdentityNotMappedError(e, Owner);
                return;
            }

            SecurityIdentifier groupSid;
            try
            {
                groupSid = ConvertToSid(Group);
            }
            catch (IdentityNotMappedException e)
            {
                WriteIdentityNotMappedError(e, Group);
                return;
            }

            CommonSecurityDescriptor rawSec = new CommonSecurityDescriptor(
                false,
                false,
                ControlFlags.DiscretionaryAclPresent,
                ownerSid,
                groupSid,
                null,  // TODO: SACL
                dacl
            );
            WriteObject(CreateSecurityDescriptor(rawSec));
        }

        private SecurityIdentifier ConvertToSid(IdentityReference id)
        {
            return (SecurityIdentifier)SecurityHelper.TranslateIdentifier(id, typeof(SecurityIdentifier), true);
        }

        private void WriteIdentityNotMappedError(IdentityNotMappedException exception, object? obj)
        {
            WriteError(new ErrorRecord(
                exception, String.Format("{0}.{1}", MyInvocation.MyCommand.Name, nameof(IdentityNotMappedException)),
                ErrorCategory.InvalidData, obj
            ));
        }

        protected abstract T CreateSecurityDescriptor(CommonSecurityDescriptor sd);
    }
}
