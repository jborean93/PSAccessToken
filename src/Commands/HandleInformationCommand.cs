using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Get, "HandleInformation"
    )]
    [OutputType(typeof(HandleFlags))]
    public class GetHandleInformationCommand : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public SafeHandle[] Handle { get; set; }

        protected override void ProcessRecord()
        {
            foreach (SafeHandle h in Handle)
            {
                try
                {
                    WriteObject(NativeMethods.GetHandleInformation(h));
                }
                catch (Win32Exception e)
                {
                    WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get handle information",
                        "GetHandleInformation", (Int64)h.DangerousGetHandle()));
                }
            }
        }
    }

    [Cmdlet(
        VerbsCommon.Set, "HandleInformation",
        SupportsShouldProcess = true
    )]
    public class SetHandleInformationCommand : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public SafeHandle[] Handle { get; set; }

        [Parameter()]
        public SwitchParameter Inherit { get; set; }

        [Parameter()]
        public SwitchParameter ProtectFromClose { get; set; }

        [Parameter()]
        public SwitchParameter Clear { get; set; }

        private HandleFlags _mask = HandleFlags.None;
        private HandleFlags _flags = HandleFlags.None;

        protected override void BeginProcessing()
        {
            if (Inherit)
            {
                _flags |= HandleFlags.Inherit;
            }

            if (ProtectFromClose)
            {
                _flags |= HandleFlags.ProtectFromClose;
            }

            if (Clear)
                _mask = HandleFlags.Inherit | HandleFlags.ProtectFromClose;
            else
                _mask = _flags;
        }

        protected override void ProcessRecord()
        {
            foreach (SafeHandle h in Handle)
            {
                try
                {
                    if (ShouldProcess(String.Format("Token {0}", (Int64)h.DangerousGetHandle()),
                        String.Format("Mask {0} - Flags {1}", _mask, _flags)))
                    {
                        NativeMethods.SetHandleInformation(h, _mask, _flags);
                    }
                }
                catch (Win32Exception e)
                {
                    WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to set handle information",
                        "SetHandleInformation", (Int64)h.DangerousGetHandle()));
                }
            }
        }
    }
}
