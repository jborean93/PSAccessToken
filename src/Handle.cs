using Microsoft.Win32.SafeHandles;
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    internal partial class NativeMethods
    {
        [DllImport("Kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(
            IntPtr hObject
        );

        [DllImport("Kernel32.dll", EntryPoint = "GetHandleInformation", SetLastError = true)]
        private static extern bool NativeGetHandleInformation(
            SafeHandle hObject,
            out HandleFlags lpdwFlags
        );

        public static HandleFlags GetHandleInformation(SafeHandle handle)
        {
            HandleFlags flags;
            if (!NativeGetHandleInformation(handle, out flags))
                throw new Win32Exception();

            return flags;
        }

        [DllImport("Kernel32.dll", EntryPoint = "SetHandleInformation", SetLastError = true)]
        private static extern bool NativeSetHandleInformation(
            SafeHandle hObject,
            HandleFlags dwMask,
            HandleFlags dwFlags
        );

        public static void SetHandleInformation(SafeHandle handle, HandleFlags mask, HandleFlags flags)
        {
            if (!NativeSetHandleInformation(handle, mask, flags))
                throw new Win32Exception();
        }
    }

    [Flags]
    public enum HandleFlags : uint
    {
        None = 0x00000000,
        Inherit = 0x00000001,
        ProtectFromClose = 0x00000002,
    }

    internal class SafeNativeHandle : SafeHandleZeroOrMinusOneIsInvalid
    {
        private bool _isValid = false;

        public SafeNativeHandle() : base(true) { }
        public SafeNativeHandle(IntPtr handle) : this(handle, true) { }
        public SafeNativeHandle(IntPtr handle, bool ownsHandle) : this(handle, ownsHandle, false) { }
        public SafeNativeHandle(IntPtr handle, bool ownsHandle, bool isValid) : base(ownsHandle)
        {
            base.SetHandle(handle);
            _isValid = isValid;
        }

        public override bool IsInvalid
        {
            get
            {
                if (_isValid)
                    return false;
                else
                    return base.IsInvalid;
            }
        }

        protected override bool ReleaseHandle()
        {
            return NativeMethods.CloseHandle(handle);
        }
    }
}
