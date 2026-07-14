# Image Sync

通过 GitHub Actions 自动将境外开源镜像（含 ARM 架构）同步至阿里云个人版 ACR。

## 使用方法

1. 编辑 `images.txt`，每行添加一个镜像地址
2. `git add images.txt && git commit -m "add: <镜像名>"`
3. `git push origin main`
4. 等待 Gitee → GitHub 自动同步（1-3 分钟）
5. GitHub Actions 自动触发，在 Actions 页面查看进度

## images.txt 格式

```text
# 注释行
源镜像:tag                      # 目标镜像同名
nginx:1.25-alpine my-nginx:v1  # 自定义目标名
```

## 手动触发同步单个镜像

GitHub 仓库 → Actions → Sync Images to ACR → Run workflow → 输入镜像地址

## 验证多架构

```bash
docker manifest inspect <ACR_REGISTRY>/<ACR_NAMESPACE>/alpine:3.18
```

## 所需 GitHub Secrets

| Secret | 说明 |
|--------|------|
| ACR_REGISTRY | ACR 地址，如 registry.cn-hangzhou.aliyuncs.com |
| ACR_NAMESPACE | 命名空间名 |
| ACR_USERNAME | ACR 用户名 |
| ACR_PASSWORD | ACR 密码 |
