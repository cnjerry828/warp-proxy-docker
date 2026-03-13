# WARP Proxy Docker

一个基于 Docker 的 Cloudflare WARP 代理服务，提供 SOCKS5 代理功能，并支持定期自动更换 IP。

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 📋 目录

- [功能特性](#功能特性)
- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [使用方法](#使用方法)
- [项目结构](#项目结构)
- [常见问题](#常见问题)
- [注意事项](#注意事项)

## 🌟 功能特性

- ✅ **SOCKS5 代理服务** - 通过 Cloudflare WARP 提供稳定的 SOCKS5 代理
- ✅ **自动更换 IP** - 支持定时自动更换 IP，避免被限制
- ✅ **Docker 容器化** - 开箱即用，无需复杂配置
- ✅ **IPv6 支持** - 完整支持 IPv4 和 IPv6
- ✅ **自动重启** - 容器故障自动重启
- ✅ **端口转发** - 使用 socat 实现透明端口转发
- ✅ **可选鉴权** - 可选开启 SOCKS5 用户名/密码鉴权（3proxy），防止公网被滥用

## 📦 前置要求

- Docker（版本 20.10+）
- Docker Compose（版本 1.29+）
- Linux 系统（推荐 Ubuntu 20.04+）
- 至少 512MB RAM
- 网络连接良好

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone [https://github.com/kschen202115/warp-proxy-docker](https://github.com/cnjerry828/warp-proxy-docker).git
cd warp-proxy-docker
```

### 2. 启动服务

```bash
docker-compose up -d
```

### 3. 验证服务

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f warp-socks

# 测试 SOCKS5 代理（需要安装 curl）
curl -x socks5://127.0.0.1:1080 https://www.google.com
```

### 4. 停止服务

```bash
docker-compose down
```

## ⚙️ 配置说明

在 `docker-compose.yml` 文件中可以配置以下参数：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `SOCKS_PORT` | 1080 | 容器内 SOCKS5 监听端口（对外端口由 ports 映射决定） |
| `RESTART_INTERVAL` | 3600 | IP 更换间隔时间（秒），默认 1 小时 |
| `SOCKS_USER` | *(空)* | （可选）开启 SOCKS5 用户名鉴权，需与 `SOCKS_PASS` 同时设置 |
| `SOCKS_PASS` | *(空)* | （可选）开启 SOCKS5 密码鉴权，需与 `SOCKS_USER` 同时设置 |
| `WARP_LOCAL_PORT` | 10080 | （可选）WARP 本地代理端口（容器内部使用） |

### 修改配置示例

编辑 `docker-compose.yml`：

#### 示例 1：仅换端口（将对外端口改为 31080）

```yaml
ports:
  - "31080:1080"

environment:
  - SOCKS_PORT=1080
  - RESTART_INTERVAL=1800
  - WARP_LOCAL_PORT=10080
```

#### 示例 2：换端口 + 开启 SOCKS5 用户名/密码鉴权（推荐公网）

```yaml
ports:
  - "31080:1080"

environment:
  - SOCKS_PORT=1080
  - RESTART_INTERVAL=1800
  - WARP_LOCAL_PORT=10080
  - SOCKS_USER=your_user
  - SOCKS_PASS=your_strong_password
```

然后重启服务：

```bash
docker compose down
docker compose up -d --build
```

> 不设置 `SOCKS_USER`/`SOCKS_PASS` 时，将回退为原始 socat 转发（无鉴权）。
> 同时建议在云厂商安全组仅放行你需要的端口（例如 31080/tcp）。

## 💻 使用方法

### 命令行使用

#### 通过 curl 测试

```bash
# 测试 SOCKS5 连接
curl -x socks5://127.0.0.1:1080 https://www.whatismyipaddress.com

# 获取当前 IP
curl -s -x socks5://127.0.0.1:1080 https://api.ipify.org?format=json | jq .
```

#### Python 使用

```python
import requests
from requests.adapters import HTTPAdapter
from socks import socksocket, SOCK5, SOCKS5

def get_ip_via_warp():
    socks_proxy = 'socks5://127.0.0.1:1080'
    proxies = {
        'http': socks_proxy,
        'https': socks_proxy,
    }
    
    response = requests.get('https://api.ipify.org?format=json', proxies=proxies)
    return response.json()

print(get_ip_via_warp())
```

#### Node.js 使用

```javascript
const axios = require('axios');
const HttpProxyAgent = require('http-proxy-agent');
const HttpsProxyAgent = require('https-proxy-agent');

const client = axios.create({
  httpAgent: new HttpProxyAgent('http://127.0.0.1:1080'),
  httpsAgent: new HttpsProxyAgent('http://127.0.0.1:1080'),
});

client.get('https://api.ipify.org?format=json')
  .then(res => console.log(res.data));
```

### 查看日志

```bash
# 实时查看日志
docker-compose logs -f

# 查看最后 100 行日志
docker-compose logs --tail=100

# 只查看最后 1 小时的日志
docker-compose logs --since 1h
```

### 管理容器

```bash
# 重启服务
docker-compose restart

# 更新镜像后重建
docker-compose up -d --build

# 删除所有相关资源
docker-compose down -v
```

## 📁 项目结构

```
warp-proxy-docker/
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置文件
├── entrypoint.sh          # 容器启动入口脚本
├── ip_changer.sh          # IP 定时更换脚本
└── README.md              # 项目文档
```

### 文件说明

- **Dockerfile** - 定义容器镜像，包含 WARP 客户端安装和依赖配置
- **docker-compose.yml** - 定义服务配置、端口映射、环境变量等
- **entrypoint.sh** - 容器启动时执行的脚本，负责初始化 WARP 和启动代理
- **ip_changer.sh** - 后台运行的脚本，定期更换 IP 地址
- **README.md** - 项目文档和使用说明

## 🔍 常见问题

### Q: 代理无法连接怎么办？

A: 请按以下步骤排查：

1. 确保容器已启动：`docker-compose ps`
2. 查看容器日志：`docker-compose logs warp-socks`
3. 确保防火墙未阻止 1080 端口
4. 检查宿主机是否能连接：`telnet 127.0.0.1 1080`

### Q: 如何修改代理端口？

A: 编辑 `docker-compose.yml`，修改 `SOCKS_PORT` 环境变量和端口映射：

```yaml
environment:
  - SOCKS_PORT=9090
ports:
  - "9090:9090"
```

### Q: 如何更改 IP 更换频率？

A: 编辑 `docker-compose.yml`，修改 `RESTART_INTERVAL` 环境变量（秒为单位）：

```yaml
environment:
  - RESTART_INTERVAL=1800  # 改为 30 分钟
```

### Q: 容器占用资源很大怎么办？

A: 可以在 `docker-compose.yml` 中添加资源限制：

```yaml
services:
  warp-socks:
    ...
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### Q: 如何确认 IP 是否成功更换？

A: 运行以下命令多次，观察返回的 IP 是否变化：

```bash
for i in {1..5}; do 
  echo "Check $i:"
  curl -s -x socks5://127.0.0.1:1080 https://api.ipify.org
  sleep 2
done
```

## ⚠️ 注意事项

1. **权限要求** - 容器需要 root 权限运行（`privileged: true`）以配置网络
2. **网络配置** - IP 更换过程中可能会有短暂的连接中断
3. **Cloudflare ToS** - 使用本项目需遵守 Cloudflare WARP 服务条款
4. **检测风险** - 频繁更换 IP 可能被某些服务检测为异常活动
5. **地区限制** - 某些地区的 Cloudflare WARP 可能受到限制
6. **首次启动** - 首次启动可能需要 1-2 分钟来初始化 WARP 服务

## 🔐 安全建议

- 不要将代理端口暴露到互联网，仅用于本地或受信任的网络
- 定期检查容器日志以发现异常活动
- 使用防火墙限制对代理端口的访问
- 定期更新 Docker 镜像以获取最新的安全补丁

## 📝 许可证

MIT License - 详见 LICENSE 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进本项目！

## 📧 联系方式

如有问题或建议，请通过 Issue 跟踪系统联系我们。

---

**提示**：如果这个项目对你有帮助，请给一个 Star ⭐ 来支持我们！
