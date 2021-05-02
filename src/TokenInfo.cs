using Microsoft.Win32.SafeHandles;
using System;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    internal partial class NativeHelpers
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct SID_AND_ATTRIBUTES
        {
            public IntPtr Sid;
            public TokenGroupAttributes Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct TOKEN_USER
        {
            public SID_AND_ATTRIBUTES User;
        }
    }

    internal partial class NativeMethods
    {
        [DllImport("Advapi32.dll", EntryPoint = "GetTokenInformation", SetLastError = true)]
        private static extern bool NativeGetTokenInformation(
            SafeHandle TokenHandle,
            TokenInformationClass TokenInformationClass,
            SafeMemoryBuffer TokenInformation,
            Int32 TokenInformationLength,
            out Int32 ReturnLength
        );

        public static SafeMemoryBuffer GetTokenInformation(SafeHandle handle, TokenInformationClass infoClass)
        {
            int returnLength;
            bool res = NativeGetTokenInformation(handle, infoClass, SafeMemoryBuffer.NullBuffer, 0,
                out returnLength);
            int errCode = Marshal.GetLastWin32Error();

            if (!res && (errCode != (int)Win32ErrorCode.ERROR_BAD_LENGTH &&
                    errCode != (int)Win32ErrorCode.ERROR_INSUFFICIENT_BUFFER))
                throw new NativeException("GetTokenInformation", errCode);

            SafeMemoryBuffer buffer = new SafeMemoryBuffer(returnLength);
            if (!NativeGetTokenInformation(handle, infoClass, buffer, returnLength, out returnLength))
            {
                buffer.Dispose();
                throw new NativeException("GetTokenInformation");
            }

            return buffer;
        }
    }

    internal class SafeMemoryBuffer : SafeHandleZeroOrMinusOneIsInvalid
    {
        public static readonly SafeMemoryBuffer NullBuffer = new SafeMemoryBuffer(IntPtr.Zero);

        public SafeMemoryBuffer() : base(true) { }
        public SafeMemoryBuffer(int cb) : this(Marshal.AllocHGlobal(cb)) { }

        public SafeMemoryBuffer(IntPtr handle) : base(true)
        {
            base.SetHandle(handle);
        }

        protected override bool ReleaseHandle()
        {
            Marshal.FreeHGlobal(handle);
            return true;
        }
    }

    [Flags]
    public enum TokenGroupAttributes : uint
    {
        Mandatory = 0x00000001,
        EnabledByDefault = 0x00000002,
        Enabled = 0x00000004,
        Owner = 0x00000008,
        UseForDenyOnly = 0x00000010,
        Integrity = 0x00000020,
        IntegrityEnabled = 0x00000040,
        Resource = 0x20000000,
        LogonId = 0xC0000000,
    }

    public enum TokenInformationClass : uint
    {
        User = 1,
        Groups = 2,
        Privileges = 3,
        Owner = 4,
        PrimaryGroup = 5,
        DefaultDacl = 6,
        Source = 7,
        Type = 8,
        ImpersonationLevel = 9,
        Statistics = 10,
        RestrictedSids = 11,
        SessionId = 12,
        GroupsAndPrivileges = 13,
        SessionReference = 14,
        SandBoxInert = 15,
        AuditPolicy = 16,
        Origin = 17,
        ElevationType = 18,
        LinkedToken = 19,
        Elevation = 20,
        HasRestrictions = 21,
        AccessInformation = 22,
        VirtualizationAllowed = 23,
        VirtualizationEnabled = 24,
        IntegrityLevel = 25,
        UIAccess = 26,
        MandatoryPolicy = 27,
        LogonSid = 28,
        IsAppContainer = 29,
        Capabilities = 30,
        AppContainerSid = 31,
        AppContainerNumber = 32,
        UserClaimAttributes = 33,
        DeviceClaimAttributes = 34,
        RestrictedUserClaimAttributes = 35,
        RestrictedDeviceClaimAttributes = 36,
        DeviceGroups = 37,
        RestrictedDeviceGroups = 38,
        SecurityAttributes = 39,
        IsRestricted = 40,
        ProcessTrustLevel = 41,
        PrivateNameSpace = 42,
        SingletonAttributes = 43,
        BnoIsolation = 44,
        ChildProcessFlags = 45,
        IsLessPrivilegedAppContainer = 46,
        IsSandboxed = 47,
        OriginatingProcessTrustLevel = 48,
    }

    public class TokenInfo
    {
        public static SecurityIdentifier GetUser(SafeHandle token)
        {
            using (SafeMemoryBuffer buffer = NativeMethods.GetTokenInformation(token, TokenInformationClass.User))
            {
                var tokenUser = Marshal.PtrToStructure<NativeHelpers.TOKEN_USER>(buffer.DangerousGetHandle());

                return new SecurityIdentifier(tokenUser.User.Sid);
            }
        }
    }
}