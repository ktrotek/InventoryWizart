```
▗▄▄▄▖▗▖  ▗▖▗▖  ▗▖▗▖ ▗▖▗▖  ▗▖▗▄▄▄▖▗▄▖ ▗▄▄▖▗▖  ▗▖    ▗▖ ▗▖▗▄▄▄▖▗▄▄▄▄▖ ▗▄▖ ▗▄▄▖▗▄▄▄▖
  █  ▐▛▚▖▐▌▐▌  ▐▌▐▌ ▐▌▐▛▚▖▐▌  █ ▐▌ ▐▌▐▌ ▐▌▝▚▞▘     ▐▌ ▐▌  █     ▗▞▘▐▌ ▐▌▐▌ ▐▌ █  
  █  ▐▌ ▝▜▌▐▌  ▐▌▐▌ ▐▌▐▌ ▝▜▌  █ ▐▌ ▐▌▐▛▀▚▖ ▐▌      ▐▌ ▐▌  █   ▗▞▘  ▐▛▀▜▌▐▛▀▚▖ █  
▗▄█▄▖▐▌  ▐▌ ▝▚▞▘ ▐▙█▟▌▐▌  ▐▌  █ ▝▚▄▞▘▐▌ ▐▌ ▐▌      ▐▙█▟▌▗▄█▄▖▐▙▄▄▄▖▐▌ ▐▌▐▌ ▐▌ █             
```


  > A Portable IT Asset Collector For **Windows** and **macOS**.
  > Drop it on a USB stick, run it on each machine, and will output in CSV 
  > format the hardware, OS, network, and every connected monitor including 
  > serial numbers! The output easily load into Excel, or your own scripts 
  > Below is a showcase of the two CSV files outputted.
<br>
**`HOSTNAME_Specs.csv`:**

```
"ComputerName", "Manufacturer", "Model", "SerialNumber", "AssignedTo", "IPAddress", "MACAddress", 
"OperatingSystem", "OSVersion", "CPU", "RAM(GB)", "Storage(GB)", "MonitorCount", "CollectedOn"
```
<br>
**`HOSTNAME_Monitors.csv`:**

```
"ComputerName", "AssignedTo", "MonitorNumber", "Manufacturer", "Model", "Serial", "Year", "CollectedOn"
```
<br>
- macOS monitor serials/year are often *not* exposed by the OS. The model name is reliable; `Serial` and `Year` may be blank.

<br><br>



## License
Licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE).
Copyright (C) 2026 ktrotek.
