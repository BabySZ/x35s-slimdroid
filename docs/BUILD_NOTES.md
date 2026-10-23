# 构建与整合说明（补充 README）

## 整合步骤速查

```bash
cd /data/aosp
rsync -a <本仓库>/device/  device/
rsync -a <本仓库>/vendor/  vendor/
rsync -a <本仓库>/hardware/ hardware/
cp -a <本仓库>/build-patches/aosp/. .
```

## build.sh 的 flock 垫片

`build.sh` 假设 `flockshim.so` 位于
`/mnt/nfs/srv/share/Ubuntu/rmx35k/scripts/flockshim.so`。
若路径不同，直接改脚本里的 `FLOCKSHIM=` 变量，或复制到该路径。

## 生成天马 metafiles

```bash
python3 docs/evidence/es2pegasus.py --help
```

输出为 Pegasus 可读取的 `*.metadata.pegasus.txt`，launch 行已含 `-e CONFIGFILE`。

## 刷机后的校验脚本要点

- `getprop sys.boot_completed` → 1
- `md5sum /system/usr/keylayout/Generic.kl` → `47001b5a46382d3cff48d38da5330779`
- `md5sum /vendor/etc/fstab.rk30board` → `81ec1ced934d5d3ec40a1330fe982d57`
- `md5sum /vendor/etc/init/hw/init.rk356x.rc` → `e8962d844ea56e37b0836712cc88f24d`
- `ls /vendor/bin/wificond` → 不存在
- `cat /sys/power/wake_lock` → 空

## 已知问题

- `.repo` 元数据残缺（`project-objects` 大量断链），本仓库是从源码快照重建的，
  不含上游 git 历史。AOSP 上游历史请以 `android-11.0.0_r48` 官方 tag 为准。
- `docs/evidence/` 中引用的部分本地路径（如 `/data/rmx35k_work/`）在本仓库外，
  仅供理解证据链，不随仓库分发。
