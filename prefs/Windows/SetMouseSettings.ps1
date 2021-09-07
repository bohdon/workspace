
# set mouse sensitivity to 1.0
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSensitivity -Type String -Value 10 # default 10

# disable mouse acceleration
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Type String -Value 0 # default 1
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Type String -Value 0 # default 6
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Type String -Value 0 # default 10
