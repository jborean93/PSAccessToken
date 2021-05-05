using System;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    internal partial class NativeHelpers
    {
        [StructLayout(LayoutKind.Sequential)]
        public class SECURITY_ATTRIBUTES
        {
            public UInt32 nLength;
            public IntPtr lpSecurityDescriptor;
            public bool bInheritHandle = false;

            public SECURITY_ATTRIBUTES()
            {
                nLength = (UInt32)Marshal.SizeOf(this);
            }

            public static SafeMemoryBuffer CreateBuffer(SecurityAttributes? attr)
            {
                if (attr == null)
                    return SafeMemoryBuffer.NullBuffer;

                byte[] secDesc = new byte[0];
                if (attr.SecurityDescriptor != null)
                    secDesc = attr.SecurityDescriptor.GetSecurityDescriptorBinaryForm();

                SECURITY_ATTRIBUTES secAttr = new SECURITY_ATTRIBUTES()
                {
                    lpSecurityDescriptor = IntPtr.Zero,
                    bInheritHandle = attr.InheritHandle,
                };

                int structSize = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
                SafeMemoryBuffer buffer = new SafeMemoryBuffer(structSize + secDesc.Length);
                try
                {
                    if (secDesc.Length > 0)
                    {
                        secAttr.lpSecurityDescriptor = IntPtr.Add(buffer.DangerousGetHandle(), structSize);
                        Marshal.Copy(secDesc, 0, secAttr.lpSecurityDescriptor, secDesc.Length);
                    }
                    Marshal.StructureToPtr(secAttr, buffer.DangerousGetHandle(), false);

                    return buffer;
                }
                catch
                {
                    buffer.Dispose();
                    throw;
                }
            }
        }
    }

    internal class PrincipalHelper
    {
        public static AuthorizationRuleCollection TranslateRawAcl(RawAcl raw, Type identityType,
            NativeObjectSecurity sd)
        {
            AuthorizationRuleCollection acl = new AuthorizationRuleCollection();

            foreach (GenericAce ace in raw)
            {
                AuthorizationRule rule;
                if (ace.AceType == AceType.SystemAudit)
                {
                    AuditFlags flags = AuditFlags.None;
                    if (ace.AceFlags.HasFlag(AceFlags.SuccessfulAccess))
                        flags |= AuditFlags.Success;

                    if (ace.AceFlags.HasFlag(AceFlags.FailedAccess))
                        flags |= AuditFlags.Failure;

                    rule = sd.AuditRuleFactory(
                        TranslateIdentifier(((CommonAce)ace).SecurityIdentifier, identityType, false),
                        ((CommonAce)ace).AccessMask,
                        ace.IsInherited,
                        ace.InheritanceFlags,
                        ace.PropagationFlags,
                        flags
                    );
                }
                else
                {
                    rule = sd.AccessRuleFactory(
                        TranslateIdentifier(((CommonAce)ace).SecurityIdentifier, identityType, false),
                        ((CommonAce)ace).AccessMask,
                        ace.IsInherited,
                        ace.InheritanceFlags,
                        ace.PropagationFlags,
                        (AccessControlType)ace.AceType
                    );
                }

                acl.AddRule(rule);
            }

            return acl;
        }

        public static IdentityReference TranslateIdentifier(IdentityReference identity, Type identityType, bool strict = true)
        {
            try
            {
                if (identityType == typeof(SecurityIdentifier))
                    return TranslateToSid(identity);
                else
                    return TranslateToNTAccount(identity);
            }
            catch (IdentityNotMappedException)
            {
                if (strict)
                    throw;

                return identity;
            }
        }

        private static SecurityIdentifier TranslateToSid(IdentityReference identity)
        {
            try
            {
                return (SecurityIdentifier)identity.Translate(typeof(SecurityIdentifier));
            }
            catch (IdentityNotMappedException) { }

            // Is an NTAccount but failed to be mapped, check for known domain parts
            string domain = "";
            string username = ((NTAccount)identity).Value.ToLowerInvariant();
            if (username.Contains("\\"))
            {
                string[] nameSplit = ((NTAccount)identity).Value.Split(new char[] { '\\' }, 2);
                domain = nameSplit[0];
                username = nameSplit[1];
            }

            if (domain == "mandatory label")
            {
                switch (username)
                {
                    case "untrusted mandatory label":
                        return new SecurityIdentifier("S-1-16-0");
                    case "low mandatory label":
                        return new SecurityIdentifier("S-1-16-4096");
                    case "medium mandatory label":
                        return new SecurityIdentifier("S-1-16-8192");
                    case "high mandatory label":
                        return new SecurityIdentifier("S-1-16-12288");
                    case "system mandatory label":
                        return new SecurityIdentifier("S-1-16-16384");
                }
            }
            else if (domain == "nt authority" && domain.StartsWith("logonsessionid_"))
                return new SecurityIdentifier(String.Format("S-1-5-5-{0}", username.Substring(15)));

            throw new IdentityNotMappedException();
        }

        private static NTAccount TranslateToNTAccount(IdentityReference identity)
        {
            try
            {
                return (NTAccount)identity.Translate(typeof(NTAccount));
            }
            catch (IdentityNotMappedException) { }

            string sid = ((SecurityIdentifier)identity).Value.ToLowerInvariant();
            if (sid.StartsWith("S-1-16-"))
            {
                string domain = "Mandatory Label";
                switch (sid)
                {
                    case "S-1-16-0":
                        return new NTAccount(domain, "Untrusted Mandatory Label");
                    case "S-1-16-4096":
                        return new NTAccount(domain, "Low Mandatory Label");
                    case "S-1-16-8192":
                        return new NTAccount(domain, "Medium Mandatory Label");
                    case "S-1-16-12288":
                        return new NTAccount(domain, "High Mandatory Label");
                    case "S-1-16-16384":
                        return new NTAccount(domain, "System Mandatory Label");
                }
            }
            else if (sid.StartsWith("s-1-5-5-"))
                return new NTAccount("NT AUTHORITY", String.Format("LogonSessionId_{0}",
                    sid.Substring(8).Replace("-", "_")));

            throw new IdentityNotMappedException();
        }
    }

    public class SecurityAttributes
    {
        public bool InheritHandle { get; set; }
        public NativeObjectSecurity? SecurityDescriptor { get; set; }
    }

    public abstract class NativeSecurity : NativeObjectSecurity
    {
        protected NativeSecurity(bool isContainer, ResourceType resourceType)
            : base(isContainer, resourceType) { }

        protected NativeSecurity(bool isContainer, ResourceType resourceType, SafeHandle? handle,
            AccessControlSections includeSections) : base(isContainer, resourceType, handle, includeSections) { }

        public new void AddAccessRule(AccessRule rule) { base.AddAccessRule(rule); }
        public new void AddAuditRule(AuditRule rule) { base.AddAuditRule(rule); }

        public override AuditRule AuditRuleFactory(IdentityReference identityReference, int accessMask,
            bool isInherited, InheritanceFlags inheritanceFlags, PropagationFlags propagationFlags, AuditFlags flags)
        {
            throw new NotImplementedException();
        }

        public AuthorizationRuleCollection GetAccessRules(Type targetType)
        {
            return GetAccessRules(true, false, targetType);
        }

        public new void Persist(SafeHandle handle, AccessControlSections includeSections)
        {
            base.Persist(handle, includeSections);
        }
    }

    public abstract class NativeSecurity<TRight, TRule> : NativeSecurity
        where TRule : AccessRule
    {
        public override Type AccessRightType { get { return typeof(TRight); } }
        public override Type AccessRuleType { get { return typeof(TRule); } }
        public override Type AuditRuleType { get { throw new NotImplementedException(); } }

        protected NativeSecurity(ResourceType resourceType) : base(false, resourceType) { }
        protected NativeSecurity(ResourceType resourceType, SafeHandle handle,
            AccessControlSections includeSections)
            : base(false, resourceType, handle, includeSections) { }
    }
}
