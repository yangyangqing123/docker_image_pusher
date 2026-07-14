#!/usr/bin/env bash
set +e  # 不因单个镜像失败而中断，收集结果后统一报告

# ─── 配置 ───
MAX_RETRIES=3
TIMEOUT="10m"

# ─── 读取待同步镜像列表 ───
if [ -n "$INPUT_IMAGE" ]; then
  # 手动触发：同步指定镜像
  IMAGES="$INPUT_IMAGE"
else
  # 自动触发：读取 images.txt，去除注释和空行
  IMAGES=$(grep -v '^#' images.txt | grep -v '^[[:space:]]*$')
fi

SUCCESS=0
FAIL=0
FAILED_IMAGES=""

# ─── 同步单个镜像函数 ───
sync_image() {
  local line="$1"
  local src_image dst_image

  # 解析 "源镜像 目标镜像名" 或仅 "源镜像"
  if echo "$line" | grep -q ' '; then
    src_image=$(echo "$line" | awk '{print $1}')
    dst_image=$(echo "$line" | awk '{print $2}')
  else
    src_image="$line"
    dst_image="$line"
  fi

  local full_src="docker://${src_image}"
  local full_dest="docker://${ACR_REGISTRY}/${ACR_NAMESPACE}/${dst_image}"

  echo "━━━ 同步: ${src_image} → ${ACR_NAMESPACE}/${dst_image}"

  for attempt in $(seq 1 $MAX_RETRIES); do
    if skopeo copy --all \
      --command-timeout="$TIMEOUT" \
      "$full_src" "$full_dest"; then
      echo "  ✓ 成功 (第 ${attempt} 次尝试)"
      return 0
    else
      echo "  ✗ 第 ${attempt} 次失败"
      [ "$attempt" -lt "$MAX_RETRIES" ] && sleep 5
    fi
  done

  echo "  ✗ ${MAX_RETRIES} 次尝试均失败"
  return 1
}

# ─── 遍历同步 ───
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if sync_image "$line"; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED_IMAGES="${FAILED_IMAGES}\n  - ${line}"
  fi
done <<< "$IMAGES"

# ─── 输出汇总报告 ───
echo ""
echo "════════════════════════════════════════════════"
echo "同步报告: ✓ ${SUCCESS} 成功, ✗ ${FAIL} 失败"
if [ "$FAIL" -gt 0 ]; then
  echo -e "失败镜像:${FAILED_IMAGES}"
  echo "════════════════════════════════════════════════"
  exit 1
fi
echo "════════════════════════════════════════════════"
