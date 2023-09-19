# Tun2SocksKit

[![Downloads][0]][1]

[0]: https://img.shields.io/github/downloads/arror/Tun2SocksKit/total.svg
[1]: https://github.com/arror/Tun2SocksKit/releases/latest

⚠️⚠️⚠️不保证每个版本都可用，请自行[Fork](https://github.com/daemooon/Tun2SocksKit/fork)发布⚠️⚠️⚠️

### 重要变更

> `2.4.0` 支持maccatalyst（arm64、x86_64）by [@hossinasaadi](https://github.com/hossinasaadi)

> `2.2.1` 支持macOS（arm64、x86_64）

> ~~`2.2.0` 支持macOS（arm64、x86_64）~~

> `2.1.16` 支持iPhone模拟器，[hev-socks5-tunnel-iphonesimulator](https://github.com/daemooon/hev-socks5-tunnel-iphonesimulator)实现

> ~~`2.1.10` 支持arm64的模拟器~~

> `2.0.1` 使用[hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel)替换[leaf](https://github.com/eycorsican/leaf)实现


### 使用
```swift
import Tun2SocksKit

Socks5Tunnel.run(withFileDescriptor: 4, configFilePath: localConfigFileURL.path(percentEncoded: false))
```

### 配置文件（详见[hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel)）
```yml
tunnel:
  mtu: 9000

socks5:
  port: 7890
  address: ::1
  udp: 'udp'

misc:
  task-stack-size: 20480
  connect-timeout: 5000
  read-write-timeout: 60000
  log-file: stderr
  log-level: debug
  limit-nofile: 65535
```






