using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.AccessControl;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Copy, "Token"
    )]
    [OutputType(typeof(SafeHandle))]
    public class CopyTokenCommand : PSCmdlet
    {
        private SecurityAttributes _attributes = null;

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public SafeHandle[] Token { get; set; }

        [Parameter()]
        public TokenAccessRights Access { get; set; }

        [Parameter()]
        public SwitchParameter Inherit { get; set; }

        [Parameter()]
        public NativeObjectSecurity SecurityDescriptor { get; set; }

        [Parameter()]
        public SecurityImpersonationLevel ImpersonationLevel { get; set; } = SecurityImpersonationLevel.Impersonation;

        [Parameter()]
        public TokenType TokenType { get; set; } = TokenType.Primary;

        protected override void BeginProcessing()
        {
            _attributes = new SecurityAttributes()
            {
                InheritHandle = Inherit,
                SecurityDescriptor = SecurityDescriptor,
            };
        }

        protected override void ProcessRecord()
        {
            foreach (SafeHandle t in Token)
            {
                try
                {
                    WriteObject(NativeMethods.DuplicateTokenEx(t, Access, _attributes, ImpersonationLevel,
                        TokenType));
                }
                catch (NativeException e)
                {
                    WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to copy access token",
                        (Int64)t.DangerousGetHandle()));
                }
            }
        }
    }
}
