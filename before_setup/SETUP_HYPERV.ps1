# must be turned off
Set-VMVideo -VMName "TestRunner" -HorizontalResolution 1920 -VerticalResolution 1080 -ResolutionType Single
Set-VM -VMName "TestRunner" -EnhancedSessionTransportType None
