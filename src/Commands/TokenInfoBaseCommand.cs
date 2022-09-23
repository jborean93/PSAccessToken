using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    internal class ValidateIdentityType : ValidateArgumentsAttribute
    {
        protected override void Validate(object arguments, EngineIntrinsics engineIntrinsics)
        {
            if (!((Type)arguments).IsSubclassOf(typeof(IdentityReference)))
                throw new ArgumentTransformationMetadataException("Type must be subclass of IdentityReference");
        }
    }

    public abstract class TokenInfoBaseCommand : PSCmdlet
    {
        protected const string DefaultParameterSetName = "CurrentIdentity";

        protected virtual TokenAccessRights RequiredRights
        {
            get
            {
                if (((CmdletInfo)MyInvocation.MyCommand).Verb == "Get")
                    return TokenAccessRights.Query;
                else
                    return TokenAccessRights.Write;
            }
        }

        [Parameter(
            Position = 0,
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Token"
        )]
        public SafeHandle[] Token { get; set; } = Array.Empty<SafeHandle>();

        [Parameter(
            Position = 0,
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Process"
        )]
        [Alias("Id")]
        public Int32[] ProcessId { get; set; } = Array.Empty<Int32>();

        [Parameter(
            Mandatory = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Thread"
        )]
        public Int32[] ThreadId { get; set; } = Array.Empty<Int32>();

        [Parameter(
            ParameterSetName = "Thread"
        )]
        public SwitchParameter OpenAsSelf { get; set; }

        [Parameter(
            ParameterSetName = "CurrentIdentity"
        )]
        public SwitchParameter UseProcessToken { get; set; }

        protected override void ProcessRecord()
        {
            if (this.ParameterSetName == "CurrentIdentity")
            {
                CurrentHandleOperation();
            }
            else if (this.ParameterSetName == "Process")
            {
                foreach (Int32 pid in ProcessId)
                {
                    ProcessHandleOperation(pid);
                }
            }
            else if (this.ParameterSetName == "Thread")
            {
                foreach (Int32 tid in ThreadId)
                {
                    ThreadHandleOperation(tid);
                }
            }
            else
            {
                foreach (SafeHandle t in Token)
                {
                    WrapTokenOperation(t);
                }
            }
        }

        protected abstract void TokenOperation(SafeHandle token);

        private void WrapTokenOperation(SafeHandle token)
        {
            try
            {
                TokenOperation(token);
            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get token information",
                    (Int64)token.DangerousGetHandle()));
            }
        }

        private void ProcessHandleOperation(Int32 id)
        {
            try
            {
                using (var process = NativeMethods.OpenProcess(ProcessAccessRights.QueryInformation, false, id))
                using (var token = NativeMethods.OpenProcessToken(process, RequiredRights))
                {
                    WrapTokenOperation(token);
                }
            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, String.Format("Failed to open process {0}", id),
                    id));
            }
        }

        private void ThreadHandleOperation(Int32 id)
        {
            try
            {
                using (var thread = NativeMethods.OpenThread(ThreadAccessRights.QueryInformation, false, id))
                using (var token = NativeMethods.OpenThreadToken(thread, RequiredRights, OpenAsSelf))
                {
                    WrapTokenOperation(token);
                }
            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, String.Format("Failed to open thread {0}", id),
                    id));
            }
        }

        private void CurrentHandleOperation()
        {
            try
            {
                if (!UseProcessToken)
                {
                    try
                    {
                        using (var token = NativeMethods.OpenThreadToken(NativeMethods.GetCurrentThread(),
                            RequiredRights, OpenAsSelf))
                        {
                            WrapTokenOperation(token);
                            return;
                        }
                    }
                    catch (NativeException e)
                    {
                        // If the thread isn't impersonating a token we fall back to the process.
                        if (e.NativeErrorCode != (int)Win32ErrorCode.ERROR_NO_TOKEN)
                            throw;
                    }
                }

                using (var token = NativeMethods.OpenProcessToken(NativeMethods.GetCurrentProcess(), RequiredRights))
                {
                    WrapTokenOperation(token);
                }

            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to open current identity"));
            }
        }
    }
}
