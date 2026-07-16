# Every registry value 03-Set-Registry writes, as one list. The set script applies
# them; the check script verifies each one. Single source — no drift, no gaps.
# Each entry: Path (reg.exe-style HKLM\.. / HKCU\..), Name, Value (int), Type.

$RegistryTweaks = @(
    # --- Telemetry / privacy ---
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'DisableEnterpriseAuthProxy'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'AITEnable'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'EnableActivityFeed'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'UploadUserActivities'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Input\TIPC'; Name = 'Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Personalization\Settings'; Name = 'AcceptedPrivacyPolicy'; Value = 0; Type = 'DWord' }

    # --- Focus thieves: content delivery / suggestions / spotlight ---
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338393Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353694Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353696Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-310093Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338389Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SystemPaneSuggestionsEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenOverlayEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'; Name = 'ScoobeSystemSettingEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard'; Name = 'Disabled'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications'; Name = 'ToastEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'; Name = 'LetAppsRunInBackground'; Value = 2; Type = 'DWord' }

    # --- Focus thieves: game bar / dvr ---
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR'; Value = 0; Type = 'DWord' }

    # --- Focus thieves: search / cortana / first logon ---
    @{ Path = 'HKCU\Software\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'CortanaConsent'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCortana'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'EnableFirstLogonAnimation'; Value = 0; Type = 'DWord' }

    # --- Edge taming ---
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'BackgroundModeEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'StartupBoostEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HideFirstRunExperience'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ImportBrowserSettings'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'AutoImportAtFirstRun'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ShowRecommendationsEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DefaultBrowserSettingEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'DefaultBrowserSettingsCampaignEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeShoppingAssistantEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeCollectionsEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HubsSidebarEnabled'; Value = 0; Type = 'DWord' }

    # --- Update / sleep backing values (set elsewhere, verified here too) ---
    @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAutoUpdate'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'HiberbootEnabled'; Value = 0; Type = 'DWord' }

    # --- Explorer QoL ---
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'HideFileExt'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarMn'; Value = 0; Type = 'DWord' }
)
