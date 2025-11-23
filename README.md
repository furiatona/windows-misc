# windows-misc

[![No Maintenance Intended](https://unmaintained.tech/badge.svg)](https://unmaintained.tech/)

This repository contains miscellaneous windows script. You can use it, but it's at your own risk.

## Scripts

### LaptopHealthCheck.ps1
A comprehensive PowerShell script for testing used laptops on-site. Perfect for quick hardware diagnostics when buying or selling used laptops.

**Features:**
- System information (manufacturer, model, CPU, RAM, disk, BIOS, battery)
- Performance tests (CPU stress test, memory test, disk read/write speed)
- SMART disk health check (requires admin)
- System error log analysis (last 7 days)
- Generates both console output and HTML report
- Works without admin privileges (gracefully skips admin-only tests)
- Safe for old hardware (lightweight tests, <10 minutes)
- Zero-error design with comprehensive error handling

**Usage:**
```powershell
.\LaptopHealthCheck.ps1
```

For full SMART disk diagnostics, run as administrator:
```powershell
# Right-click PowerShell → "Run as Administrator"
.\LaptopHealthCheck.ps1
```

### MaxOutstandingConnections.reg
Registry file for Windows network configuration.