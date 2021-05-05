using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    public static class ImpersonationState
    {
        public static String? OriginalPrompt { get; internal set; }
        public static String? Username { get; internal set; }

        internal static void SetFunction(ProviderIntrinsics provider, string name, ScriptBlock code)
        {
            provider.Item.New(
                new string[] { String.Format("Function:\\{0}", name) },
                "",
                "Function",
                code,
                true
            );
        }
    }

    [Cmdlet(
        VerbsCommon.Enter, "TokenContext",
        DefaultParameterSetName = "Process"
    )]
    public class EnterTokenContext : PSCmdlet
    {
        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Process"
        )]
        [Alias("Id")]
        public Int32 ProcessId { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Thread"
        )]
        public Int32 ThreadId { get; set; }

        [Parameter(
            ParameterSetName = "Thread"
        )]
        public SwitchParameter OpenAsSelf { get; set; }

        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Token"
        )]
        public SafeHandle? Token { get; set; }

        protected override void ProcessRecord()
        {
            if (!String.IsNullOrEmpty(ImpersonationState.OriginalPrompt))
            {
                WriteError(new ErrorRecord(
                    new InvalidOperationException("Cannot enter new token context while in existing one"),
                    nameof(InvalidOperationException),
                    ErrorCategory.InvalidOperation,
                    null
                ));
                return;
            }

            TokenAccessRights access = TokenAccessRights.Query |
                TokenAccessRights.Duplicate |
                TokenAccessRights.Impersonate;

            SafeHandle tokenToProcess;
            try
            {
                if (Token == null)
                {
                    if (this.ParameterSetName == "Process")
                        tokenToProcess = NativeMethods.OpenProcessToken(ProcessId, access);
                    else
                        tokenToProcess = NativeMethods.OpenThreadToken(ThreadId, access, OpenAsSelf);
                }
                else
                    // We don't want to clean this up as we don't own it
                    tokenToProcess = new SafeNativeHandle(Token.DangerousGetHandle(), false, true);
            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to get token to impersonate"));
                return;
            }

            using (tokenToProcess)
            {
                try
                {
                    ImpersonationState.Username = GetTokenUser(tokenToProcess);
                    NativeMethods.ImpersonateLoggedOnUser(tokenToProcess);
                }
                catch (NativeException e)
                {
                    WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to impersonate token",
                        (Int64)tokenToProcess.DangerousGetHandle()));
                    return;
                }
            }

            ImpersonationState.OriginalPrompt = ((FunctionInfo)(InvokeProvider.Item.Get(
                @"Function:\Prompt")[0].BaseObject)).Definition;

            ScriptBlock prompt = ScriptBlock.Create(@"
            $username = [PSAccessToken.ImpersonationState]::Username
            $existingPrompt = [PSAccessToken.ImpersonationState]::OriginalPrompt
            $promptValue = &([ScriptBlock]::Create($existingPrompt))

            ""[$username] $promptValue""");

            ImpersonationState.SetFunction(InvokeProvider, "Prompt", prompt);
        }

        private string GetTokenUser(SafeHandle token)
        {
            SecurityIdentifier sid = TokenInfo.GetUser(token);

            try
            {
                return ((NTAccount)sid.Translate(typeof(NTAccount))).Value;
            }
            catch (IdentityNotMappedException)
            {
                return sid.Value;
            }
        }
    }

    [Cmdlet(
        VerbsCommon.Exit, "TokenContext",
        DefaultParameterSetName = "CurrentIdentity"
    )]
    public class ExitTokenContext : PSCmdlet
    {
        protected override void EndProcessing()
        {
            if (String.IsNullOrEmpty(ImpersonationState.OriginalPrompt))
                return;

            try
            {
                NativeMethods.RevertToSelf();
            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to revert security context"));
                return;
            }

            ImpersonationState.SetFunction(InvokeProvider, "Prompt",
                ScriptBlock.Create(ImpersonationState.OriginalPrompt));
            ImpersonationState.OriginalPrompt = null;
            ImpersonationState.Username = null;
        }
    }
}
