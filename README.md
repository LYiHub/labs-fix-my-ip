# Fix IP Scripts

用于临时修改当前已连接网络的 IPv4 网关和 DNS。

| 项目 | 值 |
| --- | --- |
| 网关 | `192.168.14.9` |
| DNS | `198.18.0.2` |

执行修改时会保留当前 IP 地址和子网掩码不变，只修改网关和 DNS。

执行还原时会把地址获取改回 DHCP，并把 DNS 改回自动获取。

## macOS

### 网络一键修改

```bash
u="https://raw.githubusercontent.com/LYiHub/labs-fix-my-ip/refs/heads/main/fix-ip-macos.sh"; p="/var/tmp/fix-ip-macos.sh"; curl -fsSL "$u" -o "$p" && chmod +x "$p" && sudo "$p" apply
```

### 还原

如果已经执行过上面的网络命令，优先使用本地副本还原：

```bash
sudo /var/tmp/fix-ip-macos.sh restore
```

也可以重新从网络下载后还原：

```bash
u="https://raw.githubusercontent.com/LYiHub/labs-fix-my-ip/refs/heads/main/fix-ip-macos.sh"; p="/var/tmp/fix-ip-macos.sh"; curl -fsSL "$u" -o "$p" && chmod +x "$p" && sudo "$p" restore
```

### 本地脚本用法

```bash
sudo ./fix-ip-macos.sh apply
sudo ./fix-ip-macos.sh restore
```

macOS 脚本会处理当前启用且有 IPv4 地址的 network services，并把本次处理过的服务记录到 `/var/tmp/fix-my-ip-macos-services.txt`，还原时优先使用这份记录。

## Windows

请用 PowerShell 执行。脚本需要管理员权限；如果当前 PowerShell 不是管理员，会自动弹出 UAC 提权窗口。

### 网络一键修改

```powershell
$u="https://raw.githubusercontent.com/LYiHub/labs-fix-my-ip/refs/heads/main/fix-ip-windows.ps1"; $d="$env:ProgramData\FixMyIP"; New-Item -ItemType Directory -Path $d -Force | Out-Null; $p=Join-Path $d "fix-ip-windows.ps1"; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p; powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p apply
```

### 还原

如果已经执行过上面的网络命令，优先使用本地副本还原：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:ProgramData\FixMyIP\fix-ip-windows.ps1" restore
```

也可以重新从网络下载后还原：

```powershell
$u="https://raw.githubusercontent.com/LYiHub/labs-fix-my-ip/refs/heads/main/fix-ip-windows.ps1"; $d="$env:ProgramData\FixMyIP"; New-Item -ItemType Directory -Path $d -Force | Out-Null; $p=Join-Path $d "fix-ip-windows.ps1"; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p; powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p restore
```

### 本地脚本用法

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\fix-ip-windows.ps1 apply
.\fix-ip-windows.ps1 restore
```

Windows 脚本会处理当前已连接、启用且有 IPv4 地址的物理网卡，包括 Wi-Fi 和有线网卡，并把本次处理过的网卡记录到 `C:\ProgramData\FixMyIP\target-adapters.txt`。

## 自定义网关或 DNS

macOS：

```bash
sudo GATEWAY=192.168.14.9 DNS=198.18.0.2 ./fix-ip-macos.sh apply
```

Windows：

```powershell
.\fix-ip-windows.ps1 apply -Gateway 192.168.14.9 -Dns 198.18.0.2
```

## 注意事项

- 上面的网络命令使用 GitHub Raw 的 `main` 分支地址，`main` 更新后下载到的脚本也会变化。
- 如果要固定版本，请把 Raw URL 改成指定 commit hash 的地址。
- 脚本会修改系统网络配置：macOS 需要 `sudo`，Windows 需要管理员权限或确认 UAC 弹窗。
- 建议先保存对应平台的本地还原命令，避免网络配置修改后无法重新下载脚本。
