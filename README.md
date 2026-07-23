```
▪   ▐ ▄  ▌ ▐·▄▄▄ . ▐ ▄ ▄▄▄▄▄      ▄▄▄   ▄· ▄▌▄▄▌ ▐ ▄▌▪  ·▄▄▄▄• ▄▄▄· ▄▄▄  ▄▄▄▄▄
██ •█▌▐█▪█·█▌▀▄.▀·•█▌▐█•██  ▪     ▀▄ █·▐█▪██▌██· █▌▐███ ▪▀·.█▌▐█ ▀█ ▀▄ █·•██  
▐█·▐█▐▐▌▐█▐█•▐▀▀▪▄▐█▐▐▌ ▐█.▪ ▄█▀▄ ▐▀▀▄ ▐█▌▐█▪██▪▐█▐▐▌▐█·▄█▀▀▀•▄█▀▀█ ▐▀▀▄  ▐█.▪
▐█▌██▐█▌ ███ ▐█▄▄▌██▐█▌ ▐█▌·▐█▌.▐▌▐█•█▌ ▐█▀·.▐█▌██▐█▌▐█▌█▌▪▄█▀▐█ ▪▐▌▐█•█▌ ▐█▌·
▀▀▀▀▀ █▪. ▀   ▀▀▀ ▀▀ █▪ ▀▀▀  ▀█▄▀▪.▀  ▀  ▀ •  ▀▀▀▀ ▀▪▀▀▀·▀▀▀ • ▀  ▀ .▀  ▀ ▀▀▀ 


```
  > A Portable IT Asset Collector For **Windows** and **macOS**
  > Drop it on a USB stick, run it on each machine, and will output in CSV 
  > format the hardware, OS, network, and every connected monitor including 
  > serial numbers! The output easily load into Excel, or your own scripts
  > Below is a showcase of the two CSV files outputted.


**HOSTNAME_Specs.csv`:**

```
"ComputerName", "Manufacturer", "Model", "SerialNumber", "AssignedTo", "IPAddress", "MACAddress", 
"OperatingSystem", "OSVersion", "CPU", "RAM(GB)", "Storage(GB)", "MonitorCount", "CollectedOn"
```

**`HOSTNAME_Monitors.csv`:**

```
"ComputerName", "AssignedTo", "MonitorNumber", "Manufacturer", "Model", "Serial", "Year", "CollectedOn"
```


- **macOS monitor serials/year** are often *not* exposed by the OS, especially on Apple Silicon. The model name is reliable; `Serial` and `Year` may be blank. Built-in laptop displays have no separate serial. This is a platform limitation, not a bug.



## License
Licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE).
Copyright (C) 2026 ktrotek.
