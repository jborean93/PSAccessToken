using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "CurrentThreadId"
    )]
    [OutputType(typeof(Int32))]
    public class GetCurrentThreadId : PSCmdlet
    {
        protected override void EndProcessing()
        {
            WriteObject(NativeMethods.GetCurrentThreadId());
        }
    }

    [Cmdlet(
        VerbsCommon.Get, "ThreadHandle"
    )]
    [OutputType(typeof(SafeHandle))]
    public class GetThreadHandleCommand : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        [Alias("Id")]
        public Int32[] ThreadId { get; set; }

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = true
        )]
        public ThreadAccessRights Access { get; set; } = ThreadAccessRights.QueryInformation;

        [Parameter()]
        public SwitchParameter Inherit { get; set; }

        protected override void ProcessRecord()
        {
            if (ThreadId == null || ThreadId.Length == 0)
            {
                // If the user wants to inherit the existing token or get explicit access we need to use OpenProcess.
                if (Inherit || MyInvocation.BoundParameters.ContainsKey("Access"))
                    ThreadId = new int[] { NativeMethods.GetCurrentThreadId() };
                else
                {
                    WriteVerbose("Calling GetCurrentThread()");
                    WriteObject(NativeMethods.GetCurrentThread());
                    return;
                }
            }

            foreach (int tid in ThreadId)
            {
                WriteVerbose(String.Format("Calling OpenThread({0})", tid));

                try
                {
                    WriteObject(NativeMethods.OpenThread(Access, Inherit, tid));
                }
                catch (NativeException e)
                {
                    WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get thread handle",
                        tid));
                }
            }
        }
    }
}
