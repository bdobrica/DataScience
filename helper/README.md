# Various Files Used in Workshop #

## wpa_supplicant.conf ##

This is a file required for headless (no TV / no monitor) installation of Raspberry Pi. In order to do that, copy the file on the partition seen from you regular computer on the Raspberry Pi SD card and remember to replace the *your_wifi_ssid* and *your_wifi_password* with your Wi-Fi connection details.

Create also a *ssh* empty file on the same partition, eject and boot the Raspberry Pi. You should see the Raspberry Pi connecting to your network soon enough.

If you don't have a smart router that will tell you what are the new connected devices, please before booting the Raspberry Pi, run the following commands in Windows PowerShell

```powershell
PS C:\Users\bdobr> $ping = New-Object System.Net.NetworkInformation.Ping
PS C:\Users\bdobr> $ip_address = (get-netadapter | get-netipaddress |? { $_.InterfaceAlias -eq 'WiFi' -and $_.AddressFamily -eq 'IPv4' }).ipaddress
PS C:\Users\bdobr> $ip_prefix = $ip_address.split('.')[0..2]-join('.')
PS C:\Users\bdobr> 1..254 | % { $ping.send("$ip_prefix.$_", 200) | Where-Object { $_.status -eq "Success" } | Select-Object -Property address, status }
```

The above script will show you all your Wi-Fi connected devices. Power on the Raspberry Pi and run again just the last command (pressing up arrow and enter). This will help you see which device has recently connected to your network and record that IP address, which is the IP address of your Raspberry Pi.