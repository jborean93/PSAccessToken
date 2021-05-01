using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "ProcessToken"
    )]
    [OutputType(typeof(SafeHandle))]
    public class OpenProcessTokenCommand : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public SafeHandle[] Process { get; set; }

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = true
        )]
        public TokenAccessRights Access { get; set; } = TokenAccessRights.Query;

        protected override void ProcessRecord()
        {
            if (null == Process || Process.Length == 0)
            {
                Process = new SafeHandle[1] { NativeMethods.GetCurrentProcess() };
            }

            foreach (SafeHandle handle in Process)
            {
                try
                {
                    WriteObject(NativeMethods.OpenProcessToken(handle, Access));
                }
                catch (Win32Exception e)
                {
                    WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get process token",
                        "OpenProcessToken", (Int64)handle.DangerousGetHandle()));
                }
            }
        }
    }
}
