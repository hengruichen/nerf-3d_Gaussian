#!/bin/bash

CSV_PATH="gaussian-splatting/search_config.csv"
OUTPUT_ROOT="gaussian-splatting/train_output"
SUMMARY_CSV="${OUTPUT_ROOT}/summary.csv"
DATA_PATH="gaussian-splatting/data/Family"
TRAIN_SCRIPT="gaussian-splatting/train.py"
RENDER_SCRIPT="gaussian-splatting/render.py"  # Add render script path
METRICS_SCRIPT="gaussian-splatting/metrics.py"

# 检查 summary.csv 是否存在，不存在就写表头
if [ ! -f $SUMMARY_CSV ]; then
  echo "experiment,psnr,ssim,lpips,time(s)" > $SUMMARY_CSV
fi

# 逐行读取 CSV 文件（跳过第一行表头）
# 逐行读取 CSV 文件（跳过第一行表头）
tail -n +2 "$CSV_PATH" | while IFS=',' read -r position_lr_init feature_lr opacity_lr iterations
do
  # 去除多余的空格或换行符
  iterations=$(echo $iterations | tr -d '\r')  # 处理 Windows 风格换行符
  # 设置实验名称和输出路径
  # 替换 feature_lr 中的小数点为下划线
  position_lr_init_safe=$(echo $position_lr_init | sed 's/\./_/g')
  feature_lr_safe=$(echo $feature_lr | sed 's/\./_/g')
  opacity_lr_safe=$(echo $opacity_lr | sed 's/\./_/g')
  # 设置实验名称和输出路径
  EXP_NAME="family_pos${position_lr_init_safe}_fea${feature_lr_safe}_opa${opacity_lr_safe}_iter${iterations}dece"
  OUTPUT_DIR="${OUTPUT_ROOT}/${EXP_NAME}"

  # 如果已经完成过该实验（metrics.txt存在），就跳过
  if [ -d "${OUTPUT_DIR}/point_cloud" ]; then
    echo "⏭ Skipping ${EXP_NAME}, already completed."
    continue
  fi

  echo "🔧 Running experiment: ${EXP_NAME}"

  # 记录开始时间
  start_time=$(date +%s)

  # 训练
  python $TRAIN_SCRIPT \
    -s $DATA_PATH \
    -m $OUTPUT_DIR \
    --position_lr_init $position_lr_init \
    --feature_lr $feature_lr \
    --opacity_lr $opacity_lr \
    --iterations $iterations \
    --test_iterations 7000 15000 30000 \
    --eval

  # 训练完成后，先执行 render.py
  echo "🔧 Rendering images for experiment: ${EXP_NAME}"
  python $RENDER_SCRIPT -m $OUTPUT_DIR

  # 记录结束时间
  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # 获取 metrics
  METRIC_LOG=$(python $METRICS_SCRIPT -m $OUTPUT_DIR)
  echo "测试结果:${METRIC_LOG}"
  PSNR=$(echo "$METRIC_LOG" | grep "PSNR" | awk '{print $3}')
  SSIM=$(echo "$METRIC_LOG" | grep "SSIM" | awk '{print $3}')
  LPIPS=$(echo "$METRIC_LOG" | grep "LPIPS" | awk '{print $2}')

  # 写入单独日志文件
  echo "Training time: ${duration} seconds" > ${OUTPUT_DIR}/train.log
  echo "$METRIC_LOG" >> ${OUTPUT_DIR}/metrics.txt

  # 追加到 summary.csv
  echo "${EXP_NAME},${PSNR},${SSIM},${LPIPS},${duration}" >> $SUMMARY_CSV
  echo "✅ Completed: ${EXP_NAME}"
done
