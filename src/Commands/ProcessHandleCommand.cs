using System.ComponentModel;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "ProcessHandle",
        DefaultParameterSetName = "Current"
    )]
    [OutputType(typeof(SafeHandle))]
    public class GetProcessHandleCommand : PSCmdlet
    {
        [Parameter(
            ParameterSetName = "Current"
        )]
        public SwitchParameter Current { get; set; }

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Explicit"
        )]
        [Alias("Id")]
        public int[] ProcessId { get; set; }

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Explicit"
        )]
        public ProcessAccessRights Access { get; set; } = ProcessAccessRights.QueryInformation;

        [Parameter(
            ParameterSetName = "Explicit"
        )]
        public SwitchParameter Inherit { get; set; }

        protected override void ProcessRecord()
        {
            if (this.ParameterSetName == "Current")
                WriteObject(NativeMethods.GetCurrentProcess());
            else
            {
                foreach (int pid in ProcessId)
                {
                    try
                    {
                        WriteObject(NativeMethods.OpenProcess(Access, Inherit, pid));
                    }
                    catch (Win32Exception e)
                    {
                        WriteError(new ErrorRecord(e, "errorId", ErrorCategory.NotSpecified, null));
                    }
                }
            }
        }
    }
}
