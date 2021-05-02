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
        public Int32[] ThreadId { get; set; }

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Handle"
        )]
        [Alias("SafeHandle")]
        public SafeHandle[] Thread { get; set; }

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
                if (null == ThreadId || ThreadId.Length == 0)
                {
                    OpenThread(NativeMethods.GetCurrentThread());
                    return;
                }

                ThreadAccessRights threadAccess = ThreadAccessRights.QueryInformation |
                    ThreadAccessRights.SetInformation;

                foreach (Int32 tid in ThreadId)
                {
                    try
                    {
                        using (SafeHandle thread = NativeMethods.OpenThread(threadAccess, false, tid))
                            OpenThread(thread);
                    }
                    catch (NativeException e)
                    {
                        WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get thread handle",
                            tid));
                    }
                }
            }
            else
            {
                foreach (SafeHandle handle in Thread)
                    OpenThread(handle);
            }
        }

        private void OpenThread(SafeHandle handle)
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
