using System;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "ProcessHandle"
    )]
    [OutputType(typeof(SafeHandle))]
    public class GetProcessHandleCommand : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        [Alias("Id")]
        public Int32[] ProcessId { get; set; }

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = true
        )]
        public ProcessAccessRights Access { get; set; } = ProcessAccessRights.QueryInformation;

        [Parameter()]
        public SwitchParameter Inherit { get; set; }

        protected override void ProcessRecord()
        {
            if (ProcessId == null || ProcessId.Length == 0)
            {
                // If the user wants to inherit the existing token or get explicit access we need to use OpenProcess.
                if (Inherit || MyInvocation.BoundParameters.ContainsKey("Access"))
                    ProcessId = new int[] { NativeMethods.GetCurrentProcessId() };
                else
                {
                    WriteVerbose("Calling GetCurrentProcess()");
                    WriteObject(NativeMethods.GetCurrentProcess());
                    return;
                }
            }

            foreach (int pid in ProcessId)
            {
                WriteVerbose(String.Format("Calling OpenProcess({0})", pid));

                try
                {
                    WriteObject(NativeMethods.OpenProcess(Access, Inherit, pid));
                }
                catch (NativeException e)
                {
                    WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get process handle",
                        pid));
                }
            }
        }
    }
}
