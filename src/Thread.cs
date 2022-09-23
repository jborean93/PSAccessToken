using System;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    internal partial class NativeMethods
    {
        [DllImport("Kernel32.dll", EntryPoint = "GetCurrentThread")]
        private static extern IntPtr NativeGetCurrentThread();

        public static SafeNativeHandle GetCurrentThread()
        {
            // GetCurrentThread returns a pseudo handle that should not be closed so we explicitly state the safe
            // wrapper doesn't own the handle and it won't close it when disposed.
            return new SafeNativeHandle(NativeGetCurrentThread(), false, true);
        }

        [DllImport("Kernel32.dll")]
        public static extern Int32 GetCurrentThreadId();

        [DllImport("Kernel32.dll", EntryPoint = "OpenThread", SetLastError = true)]
        private static extern SafeNativeHandle NativeOpenThread(
            ThreadAccessRights dwDesiredAccess,
            bool bInheritHandle,
            int dwThreadId
        );

        public static SafeNativeHandle OpenThread(ThreadAccessRights access, bool inherit, int tid)
        {
            var handle = NativeOpenThread(access, inherit, tid);
            if (handle.IsInvalid)
                throw new NativeException("OpenThread");

            return handle;
        }
    }

    [Flags]
    public enum ThreadAccessRights
    {
        Terminate = 0x00000001,
        SuspendResume = 0x00000002,
        GetContext = 0x00000008,
        SetContext = 0x00000010,
        SetInformation = 0x00000020,
        QueryInformation = 0x00000040,
        SetThreadToken = 0x00000080,
        Impersonate = 0x00000100,
        DirectImpersonation = 0x00000200,
        SetLimitedInformation = 0x00000400,
        QueryLimitedInformation = 0x00000800,

        Delete = 0x00010000,
        ReadControl = 0x00020000,
        WriteDAC = 0x00040000,
        WriteOwner = 0x00080000,
        StandardRightsRequired = Delete | ReadControl | WriteDAC | WriteOwner,
        Synchronize = 0x00100000,
        AccessSystemSecurity = 0x01000000,
        AllAccess = StandardRightsRequired | Synchronize | 0xFFF,
    }
}
