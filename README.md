# nerf-3d_Gaussian
基于 NeRF 与 3D Gaussian Splatting 的三维重建

本项目以真实拍摄的雕像图像为输入，利用 NeRF 及其两个加速版本（Instant-NGP 和 Splatfacto）完成静态场景的三维重建与新视角图像合成。图像的相机位姿信息通过 COLMAP 工具获得，所有模型训练与渲染基于 [Nerfstudio](https://docs.nerf.studio) 框架实现。在统一的数据配置下，对不同方法进行了训练、效果比较与可视化分析。

---

## 项目目录结构


---
## 文件说明

## 数据准备说明
- **COLMAP 重建**：
  - 在无图形界面的环境下，手动编排匹配对并使用 COLMAP 进行特征提取与稀疏重建；
  - 生成的二进制文件位于 `processed/colmap/sparse/0/` 中。
- **数据转换**：
  - 使用脚本将 COLMAP 输出转换为 Nerfstudio 可用的 `transforms.json` 文件；
  - 生成的 `family_transforms/` 文件夹即为各模型训练的数据路径。

---

## 模型训练方法说明

以下为使用 Nerfstudio 命令行工具训练三种模型的示例：

### Nerfacto（基础 NeRF 方法）

```bash
ns-train nerfacto \
  --data /data1/xuao/NeRF_homework/family_transforms \
  --experiment-name family_transforms
```

### Instant-NGP（基于哈希编码的加速方法）

```bash
ns-train instant-ngp \
  --data /data1/xuao/NeRF_homework/family_transforms \
  --experiment-name family_transforms
```

### Splatfacto（基于高斯体元的显式方法）

```bash
ns-train splatfacto \
  --data /data1/xuao/NeRF_homework/family_transforms \
  --experiment-name family_transforms
```

---

## 渲染与结果可视化

### 启动交互式查看器（可用于自由视角浏览）

```bash
ns-viewer \
  --load-config nerf_outputs/family_transforms/[method]/[run_id]/config.yml
```

### 渲染指定相机路径并导出为视频

```bash
ns-render camera-path \
  --load-config nerf_outputs/family_transforms/instant-ngp/.../config.yml \
  --camera-path-filename family_transforms/camera_paths/2025-06-22-21-23-26.json \
  --output-path renders/family_transforms/2025-06-22-21-23-26.mp4
```

