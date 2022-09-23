using System;
using System.Security.Principal;

namespace PSAccessToken
{
    internal class SecurityHelper
    {
        public static IdentityReference TranslateIdentifier(IdentityReference identity, Type identityType, bool strict = true)
        {
            try
            {
                if (identityType == typeof(SecurityIdentifier))
                    return TranslateToSid(identity);
                else
                    return TranslateToNTAccount(identity);
            }
            catch (IdentityNotMappedException)
            {
                if (strict)
                    throw;

                return identity;
            }
        }

        private static SecurityIdentifier TranslateToSid(IdentityReference identity)
        {
            try
            {
                return (SecurityIdentifier)identity.Translate(typeof(SecurityIdentifier));
            }
            catch (IdentityNotMappedException) { }

            // Is an NTAccount but failed to be mapped, check for known domain parts
            string domain = "";
            string username = ((NTAccount)identity).Value.ToLowerInvariant();
            if (username.Contains("\\"))
            {
                string[] nameSplit = ((NTAccount)identity).Value.Split(new char[] { '\\' }, 2);
                domain = nameSplit[0];
                username = nameSplit[1];
            }

            if (domain == "mandatory label")
            {
                switch (username)
                {
                    case "untrusted mandatory label":
                        return new SecurityIdentifier("S-1-16-0");
                    case "low mandatory label":
                        return new SecurityIdentifier("S-1-16-4096");
                    case "medium mandatory label":
                        return new SecurityIdentifier("S-1-16-8192");
                    case "high mandatory label":
                        return new SecurityIdentifier("S-1-16-12288");
                    case "system mandatory label":
                        return new SecurityIdentifier("S-1-16-16384");
                }
            }
            else if (domain == "nt authority" && domain.StartsWith("logonsessionid_"))
                return new SecurityIdentifier(String.Format("S-1-5-5-{0}", username.Substring(15)));

            throw new IdentityNotMappedException();
        }

        private static NTAccount TranslateToNTAccount(IdentityReference identity)
        {
            try
            {
                return (NTAccount)identity.Translate(typeof(NTAccount));
            }
            catch (IdentityNotMappedException) { }

            string sid = ((SecurityIdentifier)identity).Value.ToLowerInvariant();
            if (sid.StartsWith("S-1-16-"))
            {
                string domain = "Mandatory Label";
                switch (sid)
                {
                    case "S-1-16-0":
                        return new NTAccount(domain, "Untrusted Mandatory Label");
                    case "S-1-16-4096":
                        return new NTAccount(domain, "Low Mandatory Label");
                    case "S-1-16-8192":
                        return new NTAccount(domain, "Medium Mandatory Label");
                    case "S-1-16-12288":
                        return new NTAccount(domain, "High Mandatory Label");
                    case "S-1-16-16384":
                        return new NTAccount(domain, "System Mandatory Label");
                }
            }
            else if (sid.StartsWith("s-1-5-5-"))
                return new NTAccount("NT AUTHORITY", String.Format("LogonSessionId_{0}",
                    sid.Substring(8).Replace("-", "_")));

            throw new IdentityNotMappedException();
        }
    }
}
