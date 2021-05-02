using System;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "ProcessToken",
        DefaultParameterSetName = "Id"
    )]
    [OutputType(typeof(SafeHandle))]
    public class GetProcessTokenCommand : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Id"
        )]
        [Alias("Id")]
        public Int32[] ProcessId { get; set; }

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Handle"
        )]
        [Alias("SafeHandle")]
        public SafeHandle[] Process { get; set; }

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = true
        )]
        public TokenAccessRights Access { get; set; } = TokenAccessRights.Query;

        protected override void ProcessRecord()
        {
            if (ParameterSetName == "Id")
            {
                if (null == ProcessId || ProcessId.Length == 0)
                {
                    OpenProcess(NativeMethods.GetCurrentProcess());
                    return;
                }

                ProcessAccessRights processAccess = ProcessAccessRights.QueryInformation |
                    ProcessAccessRights.SetInformation;

                foreach (Int32 pid in ProcessId)
                {
                    try
                    {
                        using (SafeHandle process = NativeMethods.OpenProcess(processAccess, false, pid))
                            OpenProcess(process);
                    }
                    catch (NativeException e)
                    {
                        WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get process handle",
                            pid));
                    }
                }
            }
            else
            {
                foreach (SafeHandle handle in Process)
                    OpenProcess(handle);
            }
        }

        private void OpenProcess(SafeHandle handle)
        {
            try
            {
                WriteObject(NativeMethods.OpenProcessToken(handle, Access));
            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get process token",
                    (Int64)handle.DangerousGetHandle()));
            }
        }
    }
}
