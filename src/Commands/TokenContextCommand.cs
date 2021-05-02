using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace PSAccessToken
{
    public static class ImpersonationState
    {
        public static String OriginalPrompt { get; internal set; }
        public static String Username { get; internal set; }

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
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Thread"
        )]
        public Int32 ThreadId { get; set; }

        [Parameter(
            ParameterSetName = "Thread"
        )]
        public SwitchParameter OpenAsSelf { get; set; }

        [Parameter(
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "Token"
        )]
        public SafeHandle Token { get; set; }

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
            bool cleanup = true;

            if (this.ParameterSetName == "Process")
            {
                if (ProcessId == 0)
                {
                    Token = NativeMethods.OpenProcessToken(NativeMethods.GetCurrentProcess(), access);
                }
                else
                {
                    using (SafeHandle process = NativeMethods.OpenProcess(ProcessAccessRights.QueryInformation,
                        false, ProcessId))
                    {
                        Token = NativeMethods.OpenProcessToken(process, access);
                    }
                }
            }
            else if (this.ParameterSetName == "Thread")
            {
                using (SafeHandle thread = NativeMethods.OpenThread(ThreadAccessRights.QueryInformation,
                    false, ThreadId))
                {
                    Token = NativeMethods.OpenThreadToken(thread, access, OpenAsSelf);
                }
            }
            else
            {
                cleanup = false;
            }

            try
            {
                SecurityIdentifier sid = TokenInfo.GetUser(Token);
                try
                {
                    ImpersonationState.Username = ((NTAccount)sid.Translate(typeof(NTAccount))).Value;
                }
                catch (IdentityNotMappedException)
                {
                    ImpersonationState.Username = sid.Value;
                }

                NativeMethods.ImpersonateLoggedOnUser(Token);
            }
            catch (NativeException e)
            {
                WriteError(ErrorHelper.GenerateWin32Error(e, "Failed to impersonate token",
                    (Int64)Token.DangerousGetHandle()));
                return;
            }
            finally
            {
                if (cleanup)
                    Token.Dispose();
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
