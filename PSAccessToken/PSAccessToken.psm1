# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

#Requires -Module PInvokeHelper

$module_builder = New-DynamicModule -Name PSAccessToken

# Import Enums
@(
    @{
        Name = 'PSAccessToken.LogonType'
        Type = ([System.UInt32])
        Values = @{
            Interactive = 2
            Network = 3
            Batch = 4
            Service = 5
            Proxy = 6
            Unlock = 7
            NetworkCleartext = 8
            NewCredentials = 9
            RemoteInteractive = 10
            CachedInteractive = 11
            CachedRemoteInteractive = 12
            CachedUnlock = 13
        }
    },
    @{
        Name = 'PSAccessToken.ProfileUserFlags'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            Guest = 0x00000001
            NoEncryption = 0x00000002
            CachedAccount = 0x00000004
            UsedLmPassword = 0x00000008
            ExtraSids = 0x00000020
            SubAuthSessionKey = 0x00000040
            ServerTrustAccount = 0x00000080
            Ntmlv2Enabled = 0x00000100
            ResourceGroups = 0x00000200
            ProfilePathReturned = 0x00000400
            Ntv2 = 0x00000800
            Lmv2 = 0x00001000
            Ntlmv2 = 0x00002000
            Optimized = 0x00004000
            Winlogon = 0x00008000
            Pkinit = 0x00010000
            NotOptimized = 0x00020000
            NoElevation = 0x00040000
            ManagedServer = 0x00080000
        }
    },
    @{
        Name = 'PSAccessToken.ObjectAttributesFlags'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            Inherit = 0x00000002
            Permanent = 0x00000010
            Exclusive = 0x00000020
            CaseInsensitive = 0x00000040
            OpenIf = 0x00000080
            OpenLink = 0x00000100
            KernelHandle = 0x00000200
            ForceAccessCheck = 0x00000400
            IgnoreImpersonatedDeviceMap = 0x00000800
            DontReparse = 0x00001000
            ValidAttributes = 0x00001FF2
        }
    },
    @{
        Name = 'PSAccessToken.ProcessAccessFlags'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            Terminate = 0x00000001
            CreateThread = 0x00000002
            VmOperation = 0x00000008
            VmRead = 0x00000010
            VmWrite = 0x00000020
            DupHandle = 0x00000040
            CreateProcess = 0x00000080
            SetQuota = 0x00000100
            SetInformation = 0x00000200
            QueryInformation = 0x00000400
            SuspendResume = 0x00000800
            QueryLimitedInformation = 0x00001000
            Delete = 0x00010000
            ReadControl = 0x00020000
            WriteDac = 0x00040000
            WriteOwner = 0x00080000
            Synchronize = 0x00100000
        }
    },
    @{
        Name = 'PSAccessToken.ProfileBufferType'
        Type = ([System.UInt32])
        Values = @{
            Interactive = 2
            Lm20 = 3
            SmartCard = 4
            KerbTicket = 5
        }
    },
    @{
        Name = 'PSAccessToken.RestrictedTokenFlags'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            DisableMaxPrivilege = 0x1
            SandboxInert = 0x2  # Not valid until Server 2008 R2, Windows 7+
            LuaToken = 0x4
            WriteRestricted = 0x8
        }
    },
    @{
        Name = 'PSAccessToken.SecurityContextTrackingMode'
        Type = ([System.Byte])
        Values = @{
            Static = 0x0
            Dynamic = 0x8
        }
    },
    @{
        Name = 'PSAccessToken.SecurityImpersonationLevel'
        Type = ([System.UInt32])
        Values = @{
            Anonymous = 0
            Identification = 1
            Impersonation = 2
            Delegation = 3
        }
    },
    @{
        Name = 'PSAccessToken.ThreadAccessFlags'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            Terminate = 0x00000001
            SuspendResume = 0x00000002
            GetContext = 0x00000008
            SetContext = 0x00000010
            SetInformation = 0x00000020
            QueryInformation = 0x00000040
            SetThreadToken = 0x00000080
            Impersonate = 0x00000100
            DirectImpersonation = 0x00000200
            SetLimitedInformation = 0x00000400
            QueryLimitedInformation = 0x00000800
            Delete = 0x00010000
            ReadControl = 0x00020000
            WriteDac = 0x00040000
            WriteOwner = 0x00080000
            Synchronize = 0x00100000
        }
    },
    @{
        Name = 'PSAccessToken.TokenElevationType'
        Type = ([System.UInt32])
        Values = @{
            Default = 1
            Full = 2
            Limited = 3
        }
    },
    @{
        Name = 'PSAccessToken.TokenGroupAttributes'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            Mandatory = 0x00000001
            EnabledByDefault = 0x00000002
            Enabled = 0x00000004
            Owner = 0x00000008
            UseForDenyOnly = 0x00000010
            Integrity = 0x00000020
            IntegrityEnabled = 0x00000040
            Resource = 0x20000000
            LogonId = ([System.UInt32]"0xC0000000")
        }
    },
    @{
        Name = 'PSAccessToken.TokenInformationClass'
        Type = ([System.UInt32])
        Values = @{
            User = 1
            Groups = 2
            Privileges = 3
            Owner = 4
            PrimaryGroup = 5
            DefaultDacl = 6
            Source = 7
            Type = 8
            ImpersonationLevel = 9
            Statistics = 10
            RestrictedSids = 11
            SessionId = 12
            GroupsAndPrivileges = 13
            SessionReference = 14
            SandBoxInert = 15
            AuditPolicy = 16
            Origin = 17
            ElevationType = 18
            LinkedToken = 19
            Elevation = 20
            HasRestrictions = 21
            AccessInformation = 22
            VirtualizationAllowed = 23
            VirtualizationEnabled = 24
            IntegrityLevel = 25
            UIAccess = 26
            MandatoryPolicy = 27
            LogonSid = 28
            IsAppContainer = 29
            Capabilities = 30
            AppContainerSid = 31
            AppContainerNumber = 32
            UserClaimAttributes = 33
            DeviceClaimAttributes = 34
            RestrictedUserClaimAttributes = 35
            RestrictedDeviceClaimAttributes = 36
            DeviceGroups = 37
            RestrictedDeviceGroups = 38
            SecurityAttributes = 39
            IsRestricted = 40
            ProcessTrustLevel = 41
            PrivateNameSpace = 42
            SingletonAttributes = 43
            BnoIsolation = 44
            ChildProcessFlags = 45
            IsLessPrivilegedAppContainer = 46
            IsSandboxed = 47
            OriginatingProcessTrustLevel = 48
        }
    },
    @{
        Name = 'PSAccessToken.TokenMandatoryPolicy'
        Type = ([System.UInt32])
        Values = @{
            Off = 0
            NoWriteUp = 1
            NewProcessMin = 2
            ValidMask =3
        }
    },
    @{
        Name = 'PSAccessToken.TokenPrivilegeAttributes'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            Disabled = 0x00000000
            EnabledByDefault = 0x00000001
            Enabled = 0x00000002
            Removed = 0x00000004
            UsedForAccess = ([System.UInt32]'0x80000000')
        }
    },
    @{
        Name = 'PSAccessToken.TokenType'
        Type = ([System.UInt32])
        Values = @{
            Primary = 1
            Impersonation = 2
        }
    }
) | ForEach-Object -Process { Import-Enum -ModuleBuilder $module_builder @_ }

# Import structs
@(
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/lsalookup/ns-lsalookup-_lsa_string
        Name = 'PSAccessToken.LSA_STRING'
        Fields = @(
            @{
                Name = 'Length'
                Type = ([System.UInt16])
            },
            @{
                Name = 'MaximumLength'
                Type = ([System.UInt16])
            },
            @{
                Name = 'Buffer'
                Type = ([System.String])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::LPStr
                }
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/subauth/ns-subauth-_unicode_string
        Name = 'PSAccessToken.LSA_UNICODE_STRING'
        Fields = @(
            @{
                Name = 'Length'
                Type = ([System.UInt16])
            },
            @{
                Name = 'MaximumLength'
                Type = ([System.UInt16])
            },
            @{
                Name = 'Buffer'
                # Keep as IntPtr because we sometimes deal with a SecureString and we don't want to expose that to the managed heap.
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        # The same struct is used for both Kerberos and MSV1.0 so we just combine them.
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-_kerb_interactive_logon
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-_msv1_0_interactive_logon
        Name = 'PSAccessToken.LSA_INTERACTIVE_LOGON'
        Fields = @(
            @{
                Name = 'MessageType'
                Type = ([System.UInt32])
            },
            @{
                Name = 'LogonDomainName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'UserName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'Password'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            }
        )
    },
    @{
        # The same struct is used for both Kerberos and MSV1.0 so we just combine them.
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-_msv1_0_interactive_profile
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-kerb_interactive_profile
        Name = 'PSAccessToken.LSA_INTERACTIVE_PROFILE'
        Fields = @(
            @{
                Name = 'MessageType'
                Type = ([PSAccessToken.ProfileBufferType])
            },
            @{
                Name = 'LogonCount'
                Type = ([System.UInt16])
            },
            @{
                Name = 'BadPasswordCount'
                Type = ([System.UInt16])
            },
            @{
                Name = 'LogonTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'LogoffTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'KickOffTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'PasswordLastSet'
                Type = ([System.Int64])
            },
            @{
                Name = 'PasswordCanChange'
                Type = ([System.Int64])
            },
            @{
                Name = 'PasswordMustChange'
                Type = ([System.Int64])
            },
            @{
                Name = 'LogonScript'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'HomeDirectory'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'FullName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'ProfilePath'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'HomeDirectoryDrive'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'LogonServer'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'UserFlags'
                Type = ([PSAccessToken.ProfileUserFlags])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-_lsa_last_inter_logon_info
        Name = 'PSAccessToken.LSA_LAST_INTER_LOGON_INFO'
        Fields = @(
            @{
                Name = 'LastSuccessfulLogon'
                Type = ([System.Int64])
            },
            @{
                Name = 'LastFailedLogon'
                Type = ([System.Int64])
            },
            @{
                Name = 'FailedAttemptCountSinceLastSuccessfulLogon'
                Type = ([System.UInt32])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-msv1_0_lm20_logon_profile
        Name = 'PSAccessToken.LSA_LM20_LOGON_PROFILE'
        Fields = @(
            @{
                Name = 'MessageType'
                Type = ([PSAccessToken.ProfileBufferType])
            },
            @{
                Name = 'KickOffTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'LogoffTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'UserFlags'
                Type = ([PSAccessToken.ProfileUserFlags])
            },
            @{
                Name = 'UserSessionKey'
                Type = ([System.Byte[]])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                    SizeConst = 16
                }
            },
            @{
                Name = 'LogonDomainName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'LanmanSessionKey'
                Type = ([System.Byte[]])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                    SizeConst = 8
                }
            },
            @{
                Name = 'LogonServer'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'UserParameters'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            }
        )
    },
    @{
        # The same struct is used for both Kerberos and MSV1.0 so we just combine them.
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-_kerb_s4u_logon
        Name = 'PSAccessToken.LSA_S4U_LOGON'
        Fields = @(
            @{
                Name = 'MessageType'
                Type = ([System.UInt32])
            },
            @{
                Name = 'Flags'
                Type = ([System.UInt32])
            },
            @{
                Name = 'UserPrincipalName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'DomainName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_luid
        Name = 'PSAccessToken.LUID'
        Fields = @(
            @{
                Name = 'LowPart'
                Type = ([System.UInt32])
            },
            @{
                Name = 'HighPart'
                Type = ([System.Int32])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_luid_and_attributes
        Name = 'PSAccessToken.LUID_AND_ATTRIBUTES'
        Fields = @(
            @{
                Name = 'Luid'
                Type = 'PSAccessToken.LUID'
            },
            @{
                Name = 'Attributes'
                Type = ([PSAccessToken.TokenPrivilegeAttributes])
            }
        )
    },
    @{
        # https://msdn.microsoft.com/en-us/windows/ff557749(v=vs.90)
        Name = 'PSAccessToken.OBJECT_ATTRIBUTES'
        Fields = @(
            @{
                Name = 'Length'
                Type = [System.UInt32]
            },
            @{
                Name = 'RootDirectory'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'ObjectName'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'Attributes'
                Type = ([System.UInt32])
            },
            @{
                Name = 'SecurityDescriptor'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'SecurityQualityOfService'
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_quota_limits
        Name = 'PSAccessToken.QUOTA_LIMITS'
        Fields = @(
            @{
                Name = 'PagedPoolLimit'
                Type = ([System.UIntPtr])
            },
            @{
                Name = 'NonPagedPoolLimit'
                Type = ([System.UIntPtr])
            },
            @{
                Name = 'MinimumWorkingSetSize'
                Type = ([System.UIntPtr])
            },
            @{
                Name = 'MaximumWorkingSetSize'
                Type = ([System.UIntPtr])
            },
            @{
                Name = 'PagefileLimit'
                Type = ([System.UIntPtr])
            },
            @{
                Name = 'TimeLimit'
                Type = ([System.Int64])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/ns-ntsecapi-_security_logon_session_data
        Name = 'PSAccessToken.SECURITY_LOGON_SESSION_DATA'
        Fields = @(
            @{
                Name = 'Size'
                Type = ([System.UInt32])
            },
            @{
                Name = 'LogonId'
                Type = 'PSAccessToken.LUID'
            },
            @{
                Name = 'UserName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'LogonDomain'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'AuthenticationPackage'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'LogonType'
                Type = ([PSAccessToken.LogonType])
            },
            @{
                Name = 'Session'
                Type = ([System.UInt32])
            },
            @{
                Name = 'Sid'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'LogonTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'LogonServer'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'DnsDomainName'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'Upn'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'UserFlags'
                Type = ([PSAccessToken.ProfileUserFlags])
            },
            @{
                Name = 'LastLogonInfo'
                Type = 'PSAccessToken.LSA_LAST_INTER_LOGON_INFO'
            },
            @{
                Name = 'LogonScript'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'ProfilePath'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'HomeDirectory'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'HomeDirectoryDrive'
                Type = 'PSAccessToken.LSA_UNICODE_STRING'
            },
            @{
                Name = 'LogoffTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'KickOffTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'PasswordLastSet'
                Type = ([System.Int64])
            },
            @{
                Name = 'PasswordCanChange'
                Type = ([System.Int64])
            },
            @{
                Name = 'PasswordMustChange'
                Type = ([System.Int64])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_security_quality_of_service
        Name = 'PSAccessToken.SECURITY_QUALITY_OF_SERVICE'
        Fields = @(
            @{
                Name = 'Length'
                Type = ([System.UInt32])
            },
            @{
                Name = 'ImpersonationLevel'
                Type = ([PSAccessToken.SecurityImpersonationLevel])
            },
            @{
                Name = 'ContextTrackingMode'
                Type = ([PSAccessToken.SecurityContextTrackingMode])
            },
            @{
                Name = 'EffectiveOnly'
                Type = ([System.Boolean])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::U1
                }
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_sid_and_attributes
        Name = 'PSAccessToken.SID_AND_ATTRIBUTES'
        Fields = @(
            @{
                Name = 'Sid'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'Attributes'
                Type = ([PSAccessToken.TokenGroupAttributes])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_sid_and_attributes_hash
        Name = 'PSAccessToken.SID_AND_ATTRIBUTES_HASH'
        Fields = @(
            @{
                Name = 'SidCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'SidAttr'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'Hash'
                Type = ([System.UInt32[]])
                MarshalAs = @{
                    ArraySubType = [System.Runtime.InteropServices.UnmanagedType]::U4
                    Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                    SizeConst = 32
                }
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_access_information
        Name = 'PSAccessToken.TOKEN_ACCESS_INFORMATION'
        Fields = @(
            @{
                Name = 'SidHash'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'RestrictedSidHash'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'Privileges'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'AuthenticationId'
                Type = 'PSAccessToken.LUID'
            },
            @{
                Name = 'TokenType'
                Type = ([PSAccessToken.TokenType])
            },
            @{
                Name = 'ImpersonationLevel'
                Type = ([PSAccessToken.SecurityImpersonationLevel])
            },
            @{
                Name = 'MandatoryPolicy'
                Type = ([PSAccessToken.TokenMandatoryPolicy])
            },
            @{
                Name = 'Flags'
                Type = ([System.UInt32])
            },
            @{
                Name = 'AppContainerNumber'
                Type = ([System.UInt32])
            },
            @{
                Name = 'PackageSid'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'CapabilitiesHash'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'TrustLevelSid'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'SecurityAttributes'
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_appcontainer_information
        Name = 'PSAccessToken.TOKEN_APPCONTAINER_INFORMATION'
        Fields = @(
            @{
                Name = 'TokenAppContainer'
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        Name = 'PSAccessToken.TOKEN_BNO_ISOLATION_INFORMATION'
        Fields = @(
            @{
                Name = 'IsolationPrefix'
                Type = ([System.String])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                }
            },
            @{
                Name = 'IsolationEnabled'
                Type = ([System.Boolean])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_default_dacl
        Name = 'PSAccessToken.TOKEN_DEFAULT_DACL'
        Fields = @(
            @{
                Name = 'DefaultDacl'
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_elevation
        Name = 'PSAccessToken.TOKEN_ELEVATION'
        Fields = @(
            @{
                Name = 'TokenIsElevated'
                Type = ([System.Boolean])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_groups
        Name = 'PSAccessToken.TOKEN_GROUPS'
        Fields = @(
            @{
                Name = 'GroupCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'Groups'
                Type = 'PSAccessToken.SID_AND_ATTRIBUTES[]'
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                    SizeConst = 1
                }
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_groups_and_privileges
        Name = 'PSAccessToken.TOKEN_GROUPS_AND_PRIVILEGES'
        Fields = @(
            @{
                Name = 'SidCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'SidLength'
                Type = ([System.UInt32])
            },
            @{
                Name = 'Sids'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'RestrictedSidCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'RestrictedSidLength'
                Type = ([System.UInt32])
            },
            @{
                Name = 'RestrictedSids'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'PrivilegeCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'PrivilegeLength'
                Type = ([System.UInt32])
            },
            @{
                Name = 'Privileges'
                Type = ([System.IntPtr])
            },
            @{
                Name = 'AuthenticationId'
                Type = 'PSAccessToken.LUID'
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_linked_token
        Name = 'PSAccessToken.TOKEN_LINKED_TOKEN'
        Fields = @(
            @{
                Name = 'LinkedToken'
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_mandatory_label
        Name = 'PSAccessToken.TOKEN_MANDATORY_LABEL'
        Fields = @(
            @{
                Name = 'Label'
                Type = 'PSAccessToken.SID_AND_ATTRIBUTES'
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-token_mandatory_policy
        Name = 'PSAccessToken.TOKEN_MANDATORY_POLICY_STRUCT'
        Fields = @(
            @{
                Name = 'Policy'
                Type = ([PSAccessToken.TokenMandatoryPolicy])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-token_origin
        Name = 'PSAccessToken.TOKEN_ORIGIN'
        Fields = @(
            @{
                Name = 'OriginatingLogonSession'
                Type = 'PSAccessToken.LUID'
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_owner
        Name = 'PSAccessToken.TOKEN_OWNER'
        Fields = @(
            @{
                Name = 'Owner'
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-token_primary_group
        Name = 'PSAccessToken.TOKEN_PRIMARY_GROUP'
        Fields = @(
            @{
                Name = 'PrimaryGroup'
                Type = ([System.IntPtr])
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_privileges
        Name = 'PSAccessToken.TOKEN_PRIVILEGES'
        Fields = @(
            @{
                Name = 'PrivilegeCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'Privileges'
                Type = 'PSAccessToken.LUID_AND_ATTRIBUTES[]'
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                    SizeConst = 1
                }
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-token_source
        Name = 'PSAccessToken.TOKEN_SOURCE'
        Fields = @(
            @{
                Name = 'SourceName'
                Type = ([System.Char[]])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                    SizeConst = 8
                }
            },
            @{
                Name = 'SourceIdentifier'
                Type = 'PSAccessToken.LUID'
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-token_statistics
        Name = 'PSAccessToken.TOKEN_STATISTICS'
        Fields = @(
            @{
                Name = 'TokenId'
                Type = 'PSAccessToken.LUID'
            },
            @{
                Name = 'AuthenticationId'
                Type = 'PSAccessToken.LUID'
            },
            @{
                Name = 'ExpirationTime'
                Type = ([System.Int64])
            },
            @{
                Name = 'TokenType'
                Type = ([PSAccessToken.TokenType])
            },
            @{
                Name = 'ImpersonationLevel'
                Type = ([PSAccessToken.SecurityImpersonationLevel])
            },
            @{
                Name = 'DynamicCharged'
                Type = ([System.UInt32])
            },
            @{
                Name = 'DynamicAvailable'
                Type = ([System.UInt32])
            },
            @{
                Name = 'GroupCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'PrivilegeCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'ModifiedId'
                Type = 'PSAccessToken.LUID'
            }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_token_user
        Name = 'PSAccessToken.TOKEN_USER'
        Fields = @(
            @{
                Name = 'User'
                Type = 'PSAccessToken.SID_AND_ATTRIBUTES'
            }
        )
    }
) | ForEach-Object -Process { Import-Struct -ModuleBuilder $module_builder @_ }

#Import Win32 Functions

$type_builder = $module_builder.DefineType(
    'PSAccessToken.NativeMethods',
    'Public, Class'
)
@(
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/securitybaseapi/nf-securitybaseapi-adjusttokenprivileges
        DllName = 'Advapi32.dll'
        Name = 'AdjustTokenPrivileges'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            [System.Runtime.InteropServices.SafeHandle],
            [System.Boolean],
            [System.IntPtr],
            [System.UInt32],
            [System.IntPtr],
            @{ Ref = $true; Type = [System.UInt32] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-auditenumeratecategories
        DllName = 'Advapi32.dll'
        Name = 'AuditEnumerateCategories'
        ReturnType = @{
            Type = [System.Boolean]
            MarshalAs = @{
                Type = [System.Runtime.InteropServices.UnmanagedType]::U1
            }
        }
        ParameterTypes = @(
            @{ Ref = $true; Type = [System.IntPtr] },
            @{ Ref = $true; Type = [System.UInt32] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-auditenumeratesubcategories
        DllName = 'Advapi32.dll'
        Name = 'AuditEnumerateSubCategories'
        ReturnType = @{
            Type = [System.Boolean]
            MarshalAs = @{
                Type = [System.Runtime.InteropServices.UnmanagedType]::U1
            }
        }
        ParameterTypes = @(
            [System.Guid],
            @{
                Type = [System.Boolean]
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::U1
                }
            },
            @{ Ref = $true; Type = [System.IntPtr] },
            @{ Ref = $true; Type = [System.UInt32] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-auditfree
        DllName = 'Advapi32.dll'
        Name = 'AuditFree'
        ReturnType = ([System.Void])
        ParameterTypes = @(
            [System.IntPtr]
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-auditlookupcategorynamew
        DllName = 'Advapi32.dll'
        Name = 'AuditLookupCategoryNameW'
        ReturnType = @{
            Type = [System.Boolean]
            MarshalAs = @{
                Type = [System.Runtime.InteropServices.UnmanagedType]::U1
            }
        }
        ParameterTypes = @(
            [System.Guid],
            @{ Ref = $true; Type = [System.IntPtr] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-auditlookupsubcategorynamew
        DllName = 'Advapi32.dll'
        Name = 'AuditLookupSubCategoryNameW'
        ReturnType = @{
            Type = [System.Boolean]
            MarshalAs = @{
                Type = [System.Runtime.InteropServices.UnmanagedType]::U1
            }
        }
        ParameterTypes = @(
            [System.Guid],
            @{ Ref = $true; Type = [System.IntPtr] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/aa366535(v=vs.85)
        DllName = 'Kernel32.dll'
        Name = 'CopyMemory'
        ReturnType = ([System.Void])
        ParameterTypes = @(
            [System.IntPtr],
            [System.IntPtr],
            [System.UIntPtr]
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/securitybaseapi/nf-securitybaseapi-createrestrictedtoken
        DllName = 'Advapi32.dll'
        Name = 'CreateRestrictedToken'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            [System.Runtime.InteropServices.SafeHandle],
            [PSAccessToken.RestrictedTokenFlags],
            [System.UInt32],
            [System.IntPtr],
            [System.UInt32],
            [System.IntPtr],
            [System.UInt32],
            [System.IntPtr],
            @{ Ref = $true; Type = [PInvokeHelper.SafeNativeHandle] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/securitybaseapi/nf-securitybaseapi-duplicatetokenex
        DllName = 'Advapi32.dll'
        Name = 'DuplicateTokenEx'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            [System.Runtime.InteropServices.SafeHandle],
            [System.Security.Principal.TokenAccessLevels],
            [System.IntPtr],
            [PSAccessToken.SecurityImpersonationLevel],
            [PSAccessToken.TokenType],
            @{ Ref = $true; Type = [PInvokeHelper.SafeNativeHandle] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
        DllName = 'Kernel32.dll'
        Name = 'GetCurrentProcess'
        ReturnType = ([PInvokeHelper.SafeNativeHandle])
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-getcurrentthread
        DllName = 'Kernel32.dll'
        Name = 'GetCurrentThread'
        ReturnType = ([PInvokeHelper.SafeNativeHandle])
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-getcurrentthreadid
        # PowerShell/.NET does not have a way like '$PID' to get the current thread ID. Expose the PInvoke method for this.
        DllName = 'Kernel32.dll'
        Name = 'GetCurrentThreadId'
        ReturnType = ([System.UInt32])
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/securitybaseapi/nf-securitybaseapi-gettokeninformation
        DllName = 'Advapi32.dll'
        Name = 'GetTokenInformation'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            [System.Runtime.InteropServices.SafeHandle],
            [PSAccessToken.TokenInformationClass],
            [System.IntPtr],
            [System.UInt32],
            @{ Ref = $true; Type = [System.UInt32] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/securitybaseapi/nf-securitybaseapi-impersonateloggedonuser
        DllName = 'Advapi32.dll'
        Name = 'ImpersonateLoggedOnUser'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            [System.Runtime.InteropServices.SafeHandle]
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winbase/nf-winbase-lookupprivilegenamew
        DllName = 'Advapi32.dll'
        Name = 'LookupPrivilegeNameW'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            @{
                Type = ([System.String])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                }
            },
            @{ Ref = $true; Type = [PSAccessToken.LUID] }
            [System.Text.StringBuilder],
            @{ Ref = $true; Type = [System.UInt32] }
        )
        SetLastError = $true
        CharSet = [System.Runtime.InteropServices.CharSet]::Unicode
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winbase/nf-winbase-lookupprivilegevaluew
        DllName = 'Advapi32.dll'
        Name = 'LookupPrivilegeValueW'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            @{
                Type = [System.String]
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                }
            },
            @{
                Type = [System.String]
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                }
            },
            @{ Ref = $true; Type = [PSAccessToken.LUID] }
        )
        SetLastError = $true
        CharSet = [System.Runtime.InteropServices.CharSet]::Unicode
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsaconnectuntrusted
        DllName = 'Secur32.dll'
        Name = 'LsaConnectUntrusted'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            @{ Ref = $true; Type = [System.IntPtr] }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsaderegisterlogonprocess
        DllName = 'Secur32.dll'
        Name = 'LsaDeregisterLogonProcess'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            [System.IntPtr]
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsafreereturnbuffer
        DllName = 'Secur32.dll'
        Name = 'LsaFreeReturnBuffer'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            [System.IntPtr]
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsagetlogonsessiondata
        DllName = 'Secur32.dll'
        Name = 'LsaGetLogonSessionData'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            @{ Ref = $true; Type = [PSAccessToken.LUID] },
            @{ Ref = $true; Type = [System.IntPtr] }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsalookupauthenticationpackage
        DllName = 'Secur32.dll'
        Name = 'LsaLookupAuthenticationPackage'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            [System.IntPtr],
            [PSAccessToken.LSA_STRING],
            @{ Ref = $true; Type = [System.UInt32] }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsantstatustowinerror
        DllName = 'Advapi32.dll'
        Name = 'LsaNtStatusToWinError'
        ReturnType = ([System.Int32])
        ParameterTypes = @(
            [System.UInt32]
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsalogonuser
        DllName = 'Secur32.dll'
        Name = 'LsaLogonUser'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            [System.IntPtr],
            [PSAccessToken.LSA_STRING],
            [PSAccessToken.LogonType],
            [System.UInt32],
            [System.IntPtr],
            [System.UInt32],
            [System.IntPtr],
            [PSAccessToken.TOKEN_SOURCE],
            @{ Ref = $true; Type = [System.IntPtr] },
            @{ Ref = $true; Type = [System.UInt32] },
            @{ Ref = $true; Type = [PSAccessToken.LUID] },
            @{ Ref = $true; Type = [PInvokeHelper.SafeNativeHandle] },
            @{ Ref = $true; Type = [PSAccessToken.QUOTA_LIMITS] },
            @{ Ref = $true; Type = [System.UInt32] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/ntsecapi/nf-ntsecapi-lsaregisterlogonprocess
        DllName = 'Secur32.dll'
        Name = 'LsaRegisterLogonProcess'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            [PSAccessToken.LSA_STRING],
            @{ Ref = $true; Type = [System.IntPtr] },
            @{ Ref = $true; Type = [System.IntPtr] }
        )
    },
    @{
        # This is undocumented, used the below as a baseline
        # https://www.ntinternals.net/index.html?page=UserMode%2FUndocumented%20Functions%2FNT%20Objects%2FToken%2FNtCreateToken.html
        DllName = 'ntdll.dll'
        Name = 'NtCreateToken'
        ReturnType = ([System.UInt32])
        ParameterTypes = @(
            @{ Ref = $true; Type = [PInvokeHelper.SafeNativeHandle] },
            [System.Security.Principal.TokenAccessLevels],
            @{ Ref = $true; Type = [PSAccessToken.OBJECT_ATTRIBUTES] },
            [PSAccessToken.TokenType],
            @{ Ref = $true; Type = [PSAccessToken.LUID] },
            @{ Ref = $true; Type = [System.Int64] },
            @{ Ref = $true; Type = [PSAccessToken.TOKEN_USER] },
            [System.IntPtr],
            [System.IntPtr],
            @{ Ref = $true; Type = [PSAccessToken.TOKEN_OWNER] },
            @{ Ref = $true; Type = [PSAccessToken.TOKEN_PRIMARY_GROUP] },
            @{ Ref = $true; Type = [PSAccessToken.TOKEN_DEFAULT_DACL] },
            @{ Ref = $true; Type = [PSAccessToken.TOKEN_SOURCE] }
        )
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-openprocess
        DllName = 'Kernel32.dll'
        Name = 'OpenProcess'
        ReturnType = ([PInvokeHelper.SafeNativeHandle])
        ParameterTypes = @(
            [PSAccessToken.ProcessAccessFlags],
            [System.Boolean],
            [System.UInt32]
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-openthread
        DllName = 'Kernel32.dll'
        Name = 'OpenThread'
        ReturnType = ([PInvokeHelper.SafeNativeHandle])
        ParameterTypes = @(
            [PSAccessToken.ThreadAccessFlags],
            [System.Boolean],
            [System.UInt32]
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-openprocesstoken
        DllName = 'Advapi32.dll'
        Name = 'OpenProcessToken'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            [System.IntPtr],
            [System.Security.Principal.TokenAccessLevels],
            @{ Ref = $true; Type = [PInvokeHelper.SafeNativeHandle] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-openthreadtoken
        DllName = 'Advapi32.dll'
        Name = 'OpenThreadToken'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            [System.IntPtr],
            [System.Security.Principal.TokenAccessLevels],
            [System.Boolean],
            @{ Ref = $true; Type = [PInvokeHelper.SafeNativeHandle] }
        )
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/securitybaseapi/nf-securitybaseapi-reverttoself
        DllName = 'Advapi32.dll'
        Name = 'RevertToSelf'
        ReturnType = ([System.Boolean])
        ParameterTypes = @()
        SetLastError = $true
    },
    @{
        # https://docs.microsoft.com/en-us/windows/desktop/api/winternl/nf-winternl-rtlntstatustodoserror
        DllName = 'ntdll.dll'
        Name = 'RtlNtStatusToDosError'
        ReturnType = ([System.Int32])
        ParameterTypes = @(
            [System.UInt32]
        )
    }
) | ForEach-Object -Process { Import-PInvokeMethod -TypeBuilder $type_builder @_ }
$type_builder.CreateType() > $null

### TEMPLATED EXPORT FUNCTIONS ###
# The below is replaced by the CI system during the build cycle to contain all
# the Public and Private functions into the 1 psm1 file for faster importing.

if (Test-Path -LiteralPath $PSScriptRoot\Public) {
    $public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
} else {
    $public = @()
}
if (Test-Path -LiteralPath $PSScriptRoot\Private) {
    $private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
} else {
    $private = @()
}

# dot source the files
foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

$public_functions = $public.Basename

### END TEMPLATED EXPORT FUNCTIONS ###

# TypeData for the various PSCustomObjects created in this library
@(
    @{
        TypeName = 'PSAccessToken.AuditCategory'
        DefaultDisplayPropertySet = 'Name', 'Guid'
    },
    @{
        TypeName = 'PSAccessToken.InteractiveProfile'
        DefaultDisplayPropertySet = 'MessageType', 'UserFlags', 'LogonServer'
    },
    @{
        TypeName = 'PSAccessToken.Lm20Profile'
        DefaultDisplayPropertySet = 'MessageType', 'UserFlags', 'LogonServer'
    },
    @{
        TypeName = 'PSAccessToken.LogonInfo'
        DefaultDisplayPropertySet = 'Username', 'Domain', 'Token'
    },
    @{
        TypeName = 'PSAccessToken.LogonSessionData'
        DefaultDisplayPropertySet = 'UserName', 'DnsDomainName', 'LogonType', 'Session'
    },
    @{
        TypeName = 'PSAccessToken.TokenAuditPolicy'
        DefaultDisplayPropertySet = 'Policy', 'Success', 'Failure'
    },
    @{
        TypeName = 'PSAccessToken.TokenStatistics'
        DefaultDisplayPropertySet = 'TokenId', 'ImpersonationLevel', 'GroupCount', 'PrivilegeCount'
    }
) | ForEach-Object -Process { Update-TypeData -Force @_ }

Export-ModuleMember -Function $public_functions
