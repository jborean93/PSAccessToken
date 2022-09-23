using System;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    internal partial class NativeMethods
    {
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

    // TokenImpersonationLevel is the publicly exposed enum for this as it includes None.
    internal enum SecurityImpersonationLevel : uint
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

        GenericAll = 0x10000000,
        GenericExecute = 0x20000000,
        GenericWrite = 0x4000000,
        GenericRead = 0x80000000,

        AllAccess = StandardRightsRequired | 0x1FF,
    }

    public enum TokenType : uint
    {
        Primary = 1,
        Impersonation = 2,
    }
}
