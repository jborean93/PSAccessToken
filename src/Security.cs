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
        public static IdentityReference Translate(IdentityReference identity, Type identityType)
        {
            return identity.Translate(identityType);
        }
    }

    public class SecurityAttributes
    {
        public bool InheritHandle { get; set; }
        public NativeObjectSecurity? SecurityDescriptor { get; set; }
    }

    public abstract class NativeSecurity<TRight, TRule> : NativeObjectSecurity
        where TRule : AccessRule
    {
        public override Type AccessRightType { get { return typeof(TRight); } }
        public override Type AccessRuleType { get { return typeof(TRule); } }
        public override Type AuditRuleType { get { throw new NotImplementedException(); } }

        protected NativeSecurity(ResourceType resourceType) : base(false, resourceType) { }
        protected NativeSecurity(ResourceType resourceType, SafeHandle handle,
            AccessControlSections includeSections)
            : base(false, resourceType, handle, includeSections) { }

        public new void AddAccessRule(AccessRule rule) { base.AddAccessRule(rule); }

        public AuthorizationRuleCollection GetAccessRules(Type targetType)
        {
            return GetAccessRules(true, false, targetType);
        }

        public override AuditRule AuditRuleFactory(IdentityReference identityReference, int accessMask,
            bool isInherited, InheritanceFlags inheritanceFlags, PropagationFlags propagationFlags, AuditFlags flags)
        {
            throw new NotImplementedException();
        }

        public new void Persist(SafeHandle handle, AccessControlSections includeSections)
        {
            base.Persist(handle, includeSections);
        }
    }
}
