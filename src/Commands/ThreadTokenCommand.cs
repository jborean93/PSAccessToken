using System;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "ThreadToken",
        DefaultParameterSetName = "Id"
    )]
    [OutputType(typeof(SafeHandle))]
    public class GetThreadTokenCommand : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Id"
        )]
        [Alias("Id")]
        public Int32[] ThreadId { get; set; } = Array.Empty<Int32>();

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Handle"
        )]
        [Alias("SafeHandle")]
        public SafeHandle[] Thread { get; set; } = Array.Empty<SafeHandle>();

        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = true
        )]
        public TokenAccessRights Access { get; set; } = TokenAccessRights.Query;

        [Parameter()]
        public SwitchParameter OpenAsSelf { get; set; }

        protected override void ProcessRecord()
        {
            if (ParameterSetName == "Id")
            {
                if (ThreadId.Length == 0)
                {
                    ThreadId = new int[] { 0 };
                }

                foreach (Int32 tid in ThreadId)
                {
                    try
                    {
                        WriteObject(NativeMethods.OpenThreadToken(tid, Access, OpenAsSelf));
                    }
                    catch (NativeException e)
                    {
                        WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get thread token",
                            tid));
                    }
                }
            }
            else
            {
                foreach (SafeHandle handle in Thread)
                {
                    try
                    {
                        WriteObject(NativeMethods.OpenThreadToken(handle, Access, OpenAsSelf));
                    }
                    catch (NativeException e)
                    {
                        WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get thread token",
                            (Int64)handle.DangerousGetHandle()));
                    }
                }
            }
        }
    }
}
