using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;

namespace PSAccessToken
{
    public abstract class SecurityDescriptorBaseCommand : PSCmdlet
    {
        protected override void ProcessRecord()
        {

        }
    }
}
