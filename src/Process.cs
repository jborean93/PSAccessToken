using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    internal partial class NativeMethods
    {
        [DllImport("Kernel32.dll", EntryPoint = "GetCurrentProcess")]
        private static extern IntPtr NativeGetCurrentProcess();

        public static SafeNativeHandle GetCurrentProcess()
        {
            // GetCurrentProcess returns a pseudo handle that should not be closed so we explicitly state the safe
            // wrapper doesn't own the handle and it won't close it when disposed.
            return new SafeNativeHandle(NativeGetCurrentProcess(), false, true);
        }

        [DllImport("Kernel32.dll", EntryPoint = "OpenProcess", SetLastError = true)]
        private static extern SafeNativeHandle NativeOpenProcess(
            ProcessAccessRights dwDesiredAccess,
            bool bInheritHandle,
            int dwProcessId
        );

        public static SafeNativeHandle OpenProcess(ProcessAccessRights access, bool inherit, int pid)
        {
            var handle = NativeOpenProcess(access, inherit, pid);
            if (handle.IsInvalid)
                throw new Win32Exception();

            return handle;
        }
    }

    [Flags]
    public enum ProcessAccessRights : uint
    {
        Terminate = 0x00000001,
        CreateThread = 0x00000002,
        VMOperation = 0x00000008,
        VMRead = 0x00000010,
        VMWrite = 0x00000020,
        DupHandle = 0x00000040,
        CreateProcess = 0x00000080,
        SetQuota = 0x00000100,
        SetInformation = 0x00000200,
        QueryInformation = 0x00000400,
        SuspendResume = 0x00000800,
        QueryLimitedInformation = 0x00001000,

        Delete = 0x00010000,
        ReadControl = 0x00020000,
        WriteDAC = 0x00040000,
        WriteOwner = 0x00080000,
        StandardRightsRequired = Delete | ReadControl | WriteDAC | WriteOwner,
        Synchronize = 0x00100000,
        AccessSystemSecurity = 0x01000000,
        AllAccess = StandardRightsRequired | Synchronize | 0x1FFF,
    }
}
