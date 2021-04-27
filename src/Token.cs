using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

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
                throw new Win32Exception();

            return handle;
        }
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
}
