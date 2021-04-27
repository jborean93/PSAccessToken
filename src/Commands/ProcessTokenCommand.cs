using System.ComponentModel;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Open, "ProcessToken"
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
                    WriteError(new ErrorRecord(e, "errorId", ErrorCategory.NotSpecified, null));
                }
            }
        }
    }
}