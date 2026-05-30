# Fix My IP Scripts

两个脚本用于把当前有 IPv4 地址的网络连接改成：

- 网关：`192.168.14.9`
- DNS：`198.18.0.2`

应用时会保留当前 IP 地址和子网掩码不变。还原时会把地址获取改回 DHCP，并把 DNS 改回自动获取。

## macOS

运行：

```bash
sudo ./fix-ip-macos.sh apply
```

还原：

```bash
sudo ./fix-ip-macos.sh restore
```

脚本会处理当前启用且有 IPv4 地址的 network services，并把本次处理过的服务记录到 `/var/tmp/fix-my-ip-macos-services.txt`，还原时优先使用这份记录。

## Windows

请用 PowerShell 执行。脚本需要管理员权限；如果当前 PowerShell 不是管理员，会自动弹出 UAC 提权窗口。

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\fix-ip-windows.ps1 apply
```

还原：

```powershell
.\fix-ip-windows.ps1 restore
```

也可以直接从 GitHub Raw 下载后执行：

```powershell
$u="https://raw.githubusercontent.com/LYiHub/labs-fix-my-ip/refs/heads/main/fix-ip-windows.ps1"; $d="$env:ProgramData\FixMyIP"; New-Item -ItemType Directory -Path $d -Force | Out-Null; $p=Join-Path $d "fix-ip-windows.ps1"; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p; powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p apply
```

网络调用后的还原建议使用已经下载到本地的副本：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:ProgramData\FixMyIP\fix-ip-windows.ps1" restore
```

脚本会处理当前已连接、启用且有 IPv4 地址的物理网卡，包括 Wi-Fi 和有线网卡，并把本次处理过的网卡记录到 `C:\ProgramData\FixMyIP\target-adapters.txt`。

注意：上面的 Raw URL 指向 `main` 分支，后续 `main` 更新后下载到的脚本也会随之变化。正式分发时可以改用固定 commit hash 的 Raw URL。

## 自定义网关或 DNS

macOS：

```bash
sudo GATEWAY=192.168.14.9 DNS=198.18.0.2 ./fix-ip-macos.sh apply
```

Windows：

```powershell
.\fix-ip-windows.ps1 apply -Gateway 192.168.14.9 -Dns 198.18.0.2
```
