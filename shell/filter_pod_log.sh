#!/bin/bash

# 检查是否传入了至少一个参数
if [ "$#" -lt 1 ]; then
    echo "Usage: \$0 <search_keyword> [<partial_pod_name_1> ...]"
    exit 1
fi

# 提取搜索关键词和部分Pod名字列表
search_keyword=$1
shift
partial_pod_names=("$@")

# 临时文件存储匹配的日志条目
temp_file=$(mktemp)

# 如果没有传入部分Pod名字，获取所有Pod
if [ "${#partial_pod_names[@]}" -eq 0 ]; then
    echo "No pod name provided, searching logs in all pods."
    pods=$(kubectl get pods -n mxdr | awk '{if(NR>1)print $1}')
else
    # 获取所有匹配的Pod
    for partial_pod_name in "${partial_pod_names[@]}"; do
        echo "Searching for pods matching: $partial_pod_name"
        pods+=$(kubectl get pods -n mxdr | grep "$partial_pod_name" | awk '{print $1}')$'\n'
    done
fi

# 检查是否找到了任何Pod
if [ -z "$pods" ]; then
    echo "No pods found."
    exit 1
fi

# 遍历所有匹配的Pod并搜索日志
for pod in $pods; do
    echo "Checking logs for pod: $pod"
    kubectl logs "$pod" -n mxdr | grep -i "$search_keyword" >> "$temp_file"
done

# 按时间排序日志条目并输出
echo "Sorting logs by time..."
sort -t '|' -k1,1 "$temp_file"

# 删除临时文件
rm "$temp_file"

echo "-----------------------------------"

