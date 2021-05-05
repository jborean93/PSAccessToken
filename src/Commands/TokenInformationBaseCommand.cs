using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    internal class ValidateIdentityType : ValidateArgumentsAttribute {
        protected override void Validate(object arguments, EngineIntrinsics engineIntrinsics) {
            if (!((Type)arguments).IsSubclassOf(typeof(IdentityReference)))
                throw new ArgumentTransformationMetadataException("Type must be subclass of IdentityReference");
        }
    }

    public abstract class TokenInfoBaseCommand : PSCmdlet
    {
        protected const string DefaultParameterSetName = "CurrentIdentity";

        protected TokenAccessRights RequiredRights
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
        public SafeHandle[]? Token { get; set; }

        [Parameter(
            Position = 0,
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Process"
        )]
        [Alias("Id")]
        public Int32[]? ProcessId { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Thread"
        )]
        public Int32[]? ThreadId { get; set; }

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
                foreach (Int32 pid in ProcessId ?? Array.Empty<Int32>())
                    ProcessHandleOperation(pid);
            }
            else if (this.ParameterSetName == "Thread")
            {
                foreach (Int32 tid in ThreadId ?? Array.Empty<Int32>())
                    ThreadHandleOperation(tid);
            }
            else
            {
                foreach (SafeHandle t in Token ?? Array.Empty<SafeHandle>())
                    WrapTokenOperation(t);
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
                    WrapTokenOperation(token);
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
                    WrapTokenOperation(token);
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
                    WrapTokenOperation(token);

            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to open current identity"));
            }
        }

        protected void WriteIdentityReference(IdentityReference value, Type outputType)
        {
            try
            {
                WriteObject(value.Translate(outputType));
            }
            catch (IdentityNotMappedException e)
            {
                ErrorRecord err = new ErrorRecord(e, String.Format("{0}.{1}", MyInvocation.MyCommand.Name, nameof(e)),
                    ErrorCategory.InvalidType, value);
                err.ErrorDetails = new ErrorDetails(String.Format("Failed to translate {0} to {1}: {2}",
                    value.Value, outputType.Name, e.Message));

                WriteError(err);
            }
        }
    }
}
