using System.ComponentModel;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "ThreadHandle",
        DefaultParameterSetName = "Current"
    )]
    [OutputType(typeof(SafeHandle))]
    public class GetThreadHandleCommand : PSCmdlet
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
        public int[] ThreadId { get; set; }

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Explicit"
        )]
        public ThreadAccessRights Access { get; set; } = ThreadAccessRights.QueryInformation;

        [Parameter(
            ParameterSetName = "Explicit"
        )]
        public SwitchParameter Inherit { get; set; }

        protected override void ProcessRecord()
        {
            if (this.ParameterSetName == "Current")
                WriteObject(NativeMethods.GetCurrentThread());
            else
            {
                foreach (int tid in ThreadId)
                {
                    try
                    {
                        WriteObject(NativeMethods.OpenThread(Access, Inherit, tid));
                    }
                    catch (Win32Exception e)
                    {
                        WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get thread handle",
                            "OpenThread", tid));
                    }
                }
            }
        }
    }
}
