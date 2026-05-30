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

请用“以管理员身份运行”的 PowerShell 执行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\fix-ip-windows.ps1 apply
```

还原：

```powershell
.\fix-ip-windows.ps1 restore
```

脚本会处理当前已连接、启用且有 IPv4 地址的物理网卡，包括 Wi-Fi 和有线网卡，并把本次处理过的网卡记录到 `C:\ProgramData\FixMyIP\target-adapters.txt`。

## 自定义网关或 DNS

macOS：

```bash
sudo GATEWAY=192.168.14.9 DNS=198.18.0.2 ./fix-ip-macos.sh apply
```

Windows：

```powershell
.\fix-ip-windows.ps1 apply -Gateway 192.168.14.9 -Dns 198.18.0.2
```
