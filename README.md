<p align="center">
  <img src="assets/banner.png" alt="InventoryWizart — pc + monitor asset collector" width="820">
</p>
<br>

  > A Portable IT Asset Collector For **Windows** and **macOS**.
  > Drop it on a USB stick, run it on a machine, and it will output in CSV 
  > format the hardware, OS, network, and every connected monitor including 
  > serial numbers! The output easily loads into Excel, or your own scripts 
  > Below is a showcase of the two CSV files outputted.
<br>

HOSTNAME_Specs.csv

```
"ComputerName", "Manufacturer", "Model", "SerialNumber", "AssignedTo", "IPAddress", "MACAddress", 
"OperatingSystem", "OSVersion", "CPU", "RAM(GB)", "Storage(GB)", "MonitorCount", "CollectedOn"
```
<br>

HOSTNAME_Monitors.csv

```
"ComputerName", "AssignedTo", "MonitorNumber", "Manufacturer", "Model", "Serial", "Year", "CollectedOn"
```
<br>
- macOS monitor serials/year are often *not* exposed by the OS. The model name is reliable; "Serial" and "Year" may be blank.
- "RAM(GB)" is reported as a whole number, snapped to the real installed size, so a 16 GB PC reads `16` and not `15.9`.
- Numbers never use a decimal comma. Both scripts write in the invariant/C locale, so a Greek and an English machine produce identical files.

