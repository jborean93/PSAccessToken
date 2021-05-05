using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    [Cmdlet(
        VerbsCommon.Copy, "Token"
    )]
    [OutputType(typeof(SafeHandle))]
    public class CopyTokenCommand : PSCmdlet
    {
        private SecurityAttributes? _attributes = null;

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true
        )]
        public SafeHandle[]? Token { get; set; }

        [Parameter()]
        public TokenAccessRights Access { get; set; }

        [Parameter()]
        public SwitchParameter Inherit { get; set; }

        [Parameter()]
        public NativeObjectSecurity? SecurityDescriptor { get; set; }

        [Parameter()]
        public TokenImpersonationLevel ImpersonationLevel { get; set; }

        [Parameter()]
        public TokenType TokenType { get; set; } = TokenType.Primary;

        protected override void BeginProcessing()
        {
            _attributes = new SecurityAttributes()
            {
                InheritHandle = Inherit,
                SecurityDescriptor = SecurityDescriptor,
            };

            if (!MyInvocation.BoundParameters.ContainsKey("ImpersonationLevel"))
            {
                if (TokenType == TokenType.Primary)
                    ImpersonationLevel = TokenImpersonationLevel.None;
                else
                    ImpersonationLevel = TokenImpersonationLevel.Impersonation;
            }
        }

        protected override void ProcessRecord()
        {
            if (TokenType == TokenType.Impersonation && ImpersonationLevel == TokenImpersonationLevel.None)
            {
                WriteError(new ErrorRecord(
                    new ArgumentException("Cannot create an Impersonation token with the None impersonation level"),
                    String.Format("Copy-Token.{0}", nameof(ArgumentException)),
                    ErrorCategory.InvalidArgument,
                    null
                ));
                return;
            }
            else if (TokenType == TokenType.Primary && ImpersonationLevel != TokenImpersonationLevel.None)
            {
                WriteError(new ErrorRecord(
                    new ArgumentException("Cannot create a Primary token with any impersonation level other than None"),
                    String.Format("Copy-Token.{0}", nameof(ArgumentException)),
                    ErrorCategory.InvalidArgument,
                    null
                ));
                return;
            }

            foreach (SafeHandle t in Token ?? Array.Empty<SafeHandle>())
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
