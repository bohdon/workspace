
# Change some performance settings
# set overall settings to Custom (option 3 out of Auto, Best Appearance, Best Performance, Custom)
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects -Name VisualFXSetting -Type DWord -Value 3 # default 0
# disable maximize / minimize animations
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -Type String -Value 0 # default 1

# Set theme to dark, disable transparency and coloring
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Type DWord -Value 0 # default 1
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Type DWord -Value 0 # default 0
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name EnableTransparency -Type DWord -Value 0 # default 1
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name ColorPrevalence -Type DWord -Value 0 # default 0
