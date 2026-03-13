#!/bin/bash

# 默认 3600 秒 (1小时) 更换一次
INTERVAL=${RESTART_INTERVAL:-3600}

while true; do
    sleep $INTERVAL
    echo "[$(date)] 开始更换 WARP IP..."
    
    # 彻底注销并重新注册以确保获取新的节点/IP
    warp-cli --accept-tos disconnect
    warp-cli --accept-tos registration delete
    warp-cli --accept-tos registration new
    
    # 重新配置代理模式
    warp-cli --accept-tos mode proxy
    warp-cli --accept-tos proxy port 10080
    warp-cli --accept-tos connect
    
    echo "[$(date)] WARP IP 更换完成！"
done