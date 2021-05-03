using System;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    internal partial class NativeMethods
    {
        [DllImport("Advapi32.dll", EntryPoint = "DuplicateTokenEx", SetLastError = true)]
        public static extern bool NativeDuplicateTokenEx(
            SafeHandle hExistingToken,
            TokenAccessRights dwDesiredAccess,
            SafeHandle lpTokenAttributes,
            SecurityImpersonationLevel impersonationLevel,
            TokenType TokenType,
            out SafeNativeHandle phNewToken
        );

        public static SafeNativeHandle DuplicateTokenEx(SafeHandle token, TokenAccessRights access,
            SecurityAttributes attributes, SecurityImpersonationLevel impersonationLevel, TokenType tokenType)
        {
            using (SafeHandle secAttr = NativeHelpers.SECURITY_ATTRIBUTES.CreateBuffer(attributes))
            {
                SafeNativeHandle handle;
                if (!NativeDuplicateTokenEx(token, access, secAttr, impersonationLevel, tokenType, out handle))
                    throw new NativeException("DuplicateTokenEx");

                return handle;
            }
        }

        [DllImport("Advapi32.dll", EntryPoint = "ImpersonateLoggedOnUser", SetLastError = true)]
        private static extern bool NativeImpersonateLoggedOnUser(
            SafeHandle hToken
        );

        public static void ImpersonateLoggedOnUser(SafeHandle token)
        {
            if (!NativeImpersonateLoggedOnUser(token))
                throw new NativeException("ImpersonateLoggedOnUser");
        }

        [DllImport("Advapi32.dll", EntryPoint = "OpenProcessToken", SetLastError = true)]
        private static extern bool NativeOpenProcessToken(
            SafeHandle ProcessHandle,
            TokenAccessRights DesiredAccess,
            out SafeNativeHandle TokenHandle
        );

        public static SafeNativeHandle OpenProcessToken(SafeHandle process, TokenAccessRights access)
        {
            SafeNativeHandle handle;
            if (!NativeOpenProcessToken(process, access, out handle))
                throw new NativeException("OpenProcessToken");

            return handle;
        }

        public static SafeNativeHandle OpenProcessToken(Int32 pid, TokenAccessRights accessRights)
        {
            SafeHandle process;

            Int32 currentPid = GetCurrentProcessId();
            if (pid == 0 || pid == currentPid)
                process = GetCurrentProcess();
            else
                process = OpenProcess(ProcessAccessRights.QueryInformation, false, pid);

            using (process)
                return OpenProcessToken(process, accessRights);
        }

        [DllImport("Advapi32.dll", EntryPoint = "OpenThreadToken", SetLastError = true)]
        public static extern bool NativeOpenThreadToken(
            SafeHandle ThreadHandle,
            TokenAccessRights DesiredAccess,
            bool OpenAsSelf,
            out SafeNativeHandle TokenHandle
        );

        public static SafeNativeHandle OpenThreadToken(SafeHandle thread, TokenAccessRights accessRights,
            bool openAsSelf)
        {
            SafeNativeHandle handle;
            if (!NativeOpenThreadToken(thread, accessRights, openAsSelf, out handle))
                throw new NativeException("OpenThreadToken");

            return handle;
        }

        public static SafeNativeHandle OpenThreadToken(Int32 tid, TokenAccessRights accessRights,
            bool openAsSelf)
        {
            SafeHandle thread;

            Int32 currentTid = GetCurrentThreadId();
            if (tid == 0 || tid == currentTid)
                thread = GetCurrentThread();
            else
                thread = OpenThread(ThreadAccessRights.QueryInformation, false, tid);

            using (thread)
                return OpenThreadToken(thread, accessRights, openAsSelf);
        }

        [DllImport("Advapi32.dll", EntryPoint = "RevertToSelf", SetLastError = true)]
        private static extern bool NativeRevertToSelf();

        public static void RevertToSelf()
        {
            if (!NativeRevertToSelf())
                throw new NativeException("RevertToSelf");
        }
    }

    public class TokenSecurity : NativeSecurity<TokenAccessRights, TokenAccessRule>
    {
        public TokenSecurity() : base(ResourceType.KernelObject) { }

        public TokenSecurity(SafeHandle handle, AccessControlSections includeSections)
            : base(ResourceType.KernelObject, handle, includeSections) { }
    }

    public class TokenAccessRule : AccessRule
    {
        public TokenAccessRights TokenAccessRights { get { return (TokenAccessRights)AccessMask; } }

        public TokenAccessRule(IdentityReference identityReference, TokenAccessRights accessMask, bool isInherited,
            InheritanceFlags inheritanceFlags, PropagationFlags propagationFlags, AccessControlType type)
            : base(identityReference, (int)accessMask, isInherited, inheritanceFlags, propagationFlags, type) { }
    }

    public enum SecurityImpersonationLevel : uint
    {
        Anonymous = 0,
        Identification = 1,
        Impersonation = 2,
        Delegation = 3,
    }

    [Flags]
    public enum TokenAccessRights : uint
    {
        AssignPrimary = 0x00000001,
        Duplicate = 0x00000002,
        Impersonate = 0x00000004,
        Query = 0x00000008,
        QuerySource = 0x00000010,
        AdjustPrivileges = 0x00000020,
        AdjustGroups = 0x00000040,
        AdjustDefault = 0x00000080,
        AdjustSessionId = 0x00000100,

        Delete = 0x00010000,
        ReadControl = 0x00020000,
        WriteDAC = 0x00040000,
        WriteOwner = 0x00080000,
        StandardRightsRequired = Delete | ReadControl | WriteDAC | WriteOwner,
        AccessSystemSecurity = 0x01000000,

        Execute = ReadControl | Impersonate,
        Read = ReadControl | Query,
        Write = ReadControl | AdjustDefault | AdjustGroups | AdjustDefault,

        AllAccess = StandardRightsRequired | 0x1FF,
    }

    public enum TokenType : uint
    {
        Primary = 1,
        Impersonation = 2,
    }
}
