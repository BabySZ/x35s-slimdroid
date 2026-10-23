#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
es2pegasus.py -- 把 EmulationStation 的 gamelist.xml 转换成 Pegasus 原生的
metadata.pegasus.txt。

背景 / 依据(全部来自上游源码, 不是猜的):
  * Pegasus 的 Android 版 **没有编译** EmulationStation(es2) provider。
    src/backend/AppSettings.cpp 里 es2 相关代码被 `#ifdef WITH_COMPAT_ES2` 包住;
    出货的 libpegasus-fe_arm64-v8a.so 里搜不到 EmulationStation/gamelist.xml/Es2Provider
    任何字符串。=> 必须自己做格式转换。
  * Pegasus 只认这些元数据文件名 (src/backend/providers/pegasus_metadata/PegasusProvider.cpp):
        metadata.pegasus.txt / metadata.txt
        *.metadata.pegasus.txt / *.metadata.txt
    并且是 **非递归** 地在每个 game dir 以及 <配置目录>/metafiles/ 下查找。
  * 资产(封面等)的 key 必须是 `assets.<type>`, type 见
    src/backend/PegasusAssets.cpp 的 str_to_type()。
    注意: ES 的 `image` / `thumbnail` **不是** 合法的 Pegasus asset key。
  * `file :` 的相对路径按 **元数据文件所在目录** 解析
    (PegasusMetadata.cpp: QFileInfo(ps.dir, line))。
  * Android 上 launch 命令必须以 `am start` 开头, 走 JNI 直接构造 Intent
    (ProcessLauncher.cpp + AndroidHelpers.cpp + IntentHelper.java)。
  * RetroArch 从 intent 里读两个 String extra: `ROM` 和 `LIBRETRO`
    (pkg/android/phoenix/src/com/retroarch/browser/retroactivity/RetroActivityFuture.java)。
    已在本机实测通过。

用法:
    es2pegasus.py <gamelist.xml> <输出目录> --system nes [--root /mnt/media_rw/tfcard/AURKNIX/nes]
                   [--core fceumm] [--collection 名称]
"""

import argparse
import os
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET

# --------------------------------------------------------------------------
# ES 的 asset 标签 -> Pegasus 的 assets.<type>
# 只映射语义明确、且 Pegasus 认识的类型。ES 的 image/thumbnail 都当作"封面",
# Pegasus 里叫 boxFront; 视频/手册/地图 ES 有而 Pegasus 没有对应类型, 丢弃。
# --------------------------------------------------------------------------
ASSET_MAP = {
    "image":     "boxFront",
    "thumbnail": "boxFront",
    "boxart":    "boxFront",
    "marquee":   "logo",          # PegasusAssets.cpp: marquee -> ARCADE_MARQUEE
    "fanart":    "background",
    "boxback":   "boxBack",
    "video":     "video",
    "screenshot": "screenshot",
    "titleshot": "titlescreen",
    "cartridge": "cartridge",
    "manual":    None,   # Pegasus 无此类型
    "map":       None,
    "wheel":     "logo",
    "box":       "boxFull",
    "disc":      "cartridge",
}

# ES 的 releasedate 形如 19911102T000000 -> Pegasus release : 1991-11-02
RX_ESDATE = re.compile(r"^(\d{4})(\d{2})(\d{2})T")

# Pegasus 的 metadata 是"行式"格式: key : value, 反斜杠转义。
# 参考 PegasusMetadata.cpp 的 metafile 解析器。值里的换行要写成 \n。


def esc(s: str) -> str:
    """转义 Pegasus 行式格式里的值。"""
    if s is None:
        return ""
    s = s.replace("\\", "\\\\")
    s = s.replace("\r\n", "\n").replace("\r", "\n")
    s = s.replace("\n", "\\n")
    return s.strip()


def norm_rating(txt):
    """ES 的 rating 是 0..1 的小数; Pegasus 也接受 0..1 小数, 原样传。"""
    t = (txt or "").strip()
    if not t:
        return None
    try:
        v = float(t)
    except ValueError:
        return None
    v = max(0.0, min(1.0, v))
    return f"{v:g}"


def norm_date(txt):
    t = (txt or "").strip()
    if not t:
        return None
    m = RX_ESDATE.match(t)
    if m:
        y, mo, d = m.group(1), m.group(2), m.group(3)
        if mo == "00":
            return y
        if d == "00":
            return f"{y}-{mo}"
        return f"{y}-{mo}-{d}"
    # 兜底: 已经是 YYYY-MM-DD
    m2 = re.match(r"^(\d{4})-(\d{1,2})-(\d{1,2})$", t)
    if m2:
        return f"{m2.group(1)}-{int(m2.group(2)):02d}-{int(m2.group(3)):02d}"
    return None


def norm_players(txt):
    """ES: '1'、'1-2'、'1-4'。Pegasus 的 players 用 rx_count_range 解析, 同格式。"""
    t = (txt or "").strip()
    return t if re.match(r"^\d+(-\d+)?$", t) else None


def asset_relpath(path_val: str):
    """
    ES 里的资源路径形如 './images/foo-image.png' 或 'images/foo.png'。
    转成相对 gamelist 所在目录(也就是 system 目录)的相对路径。
    """
    p = (path_val or "").strip()
    if not p:
        return None
    if p.startswith("./"):
        p = p[2:]
    return p or None


def load_manifest(path):
    """
    可选: 设备上 `find . -type f` 输出的相对路径清单。
    主机看不到 TF 卡时, 用它做资产存在性校验(比反复 adb 快几千倍)。
    返回 set, 元素形如 'nes/images/foo-image.png'(相对 AURKNIX, 已去 './')。
    """
    if not path:
        return None
    s = set()
    with open(path, encoding="utf-8", errors="surrogateescape") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            if line.startswith("./"):
                line = line[2:]
            s.add(line)
    return s


def convert(gamelist, outdir, system, root, core, collection_name,
            missing_report=None, manifest=None, abs_prefix=None,
            require_files=False):
    tree = ET.parse(gamelist)
    r = tree.getroot()

    out = []
    w = out.append

    # ---- collection 头 ----
    # launch 是"本合集默认启动命令", 每条 game 也可以覆盖。
    # Android 上必须 am start 开头; 用 {file.path} 占位, Pegasus 会替换成绝对路径。
    if core:
        w(f"collection : {collection_name}")
        w(f"shortname : {system}")
        w(f"extension : {exts_hint(system)}")
        # R33 修正: 必须显式传 -e CONFIGFILE, 否则 RetroArch 读不到用户的
        # retroarch.cfg, 会退回内置默认值 —— 表现为画面全屏(非 1:1)、
        # 无虚拟手柄、机身方向键失效 (ABCD/投币/开始仍可用, 易误判为手柄问题)。
        # 该参数为 Pegasus 官方文档 platform-android 中 RetroArch 标准启动命令的一部分。
        w(f"launch : am start -a android.intent.action.VIEW "
          f"-n com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture "
          f"-e ROM {{file.path}} "
          f"-e LIBRETRO /data/data/com.retroarch.aarch64/cores/{core}_libretro_android.so "
          f"-e CONFIGFILE /storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg")
        w("")

    stats = {"games": 0, "assets": 0, "skipped_no_file": 0,
                 "unknown_assets": 0, "skipped_no_game": 0}
    unknown = set()

    for g in r.findall("game"):
        path = (g.findtext("path") or "").strip()
        if not path:
            continue
        # 目录条目(合集介绍页)跳过 -- Pegasus 里没有对应概念
        if os.path.splitext(path)[1] == "":
            continue

        rel = path[2:] if path.startswith("./") else path
        absfile = os.path.join(root, rel)

        # 关键: Pegasus 把 `file :` 的相对路径按 **元数据文件所在目录** 解析
        # (PegasusMetadata.cpp: QFileInfo(ps.dir, line))。元数据放在
        # <配置目录>/metafiles/ 下, 那个目录里没有 ROM, 所以必须写绝对路径。
        file_val = f"{abs_prefix.rstrip('/')}/{rel}" if abs_prefix else rel

        # 卡上确实没有这个 ROM 时跳过 (ES 的 gamelist 常引用未拷贝的文件)
        if require_files and manifest is not None and f"{system}/{rel}" not in manifest:
            stats["skipped_no_game"] += 1
            continue

        name = (g.findtext("name") or "").strip()
        if not name:
            name = os.path.splitext(os.path.basename(rel))[0]

        w(f"game : {esc(name)}")
        w(f"file : {file_val}")

        # ---- 文本元数据 ----
        for es_tag, pg_key in (
            ("developer", "developer"),
            ("publisher", "publisher"),
            ("genre", "genre"),
        ):
            v = (g.findtext(es_tag) or "").strip()
            if v:
                w(f"{pg_key} : {esc(v)}")

        d = norm_date(g.findtext("releasedate"))
        if d:
            w(f"release : {d}")
        rt = norm_rating(g.findtext("rating"))
        if rt:
            w(f"rating : {rt}")
        pl = norm_players(g.findtext("players"))
        if pl:
            w(f"players : {pl}")

        desc = (g.findtext("desc") or "").strip()
        if desc:
            w(f"summary : {esc(desc[:300])}")
            if len(desc) > 300:
                w(f"description : {esc(desc)}")

        # ---- 资产 ----
        seen = set()
        for child in g:
            t = child.tag
            if t not in ASSET_MAP:
                continue
            if not (child.text or "").strip():
                continue
            pgt = ASSET_MAP[t]
            if pgt is None:
                continue
            rp = asset_relpath(child.text)
            if not rp:
                continue
            if manifest is not None:
                ok = f"{system}/{rp}" in manifest
            else:
                ok = os.path.exists(os.path.join(root, rp))
            if not ok:
                stats["skipped_no_file"] += 1
                if missing_report is not None:
                    missing_report.append((system, rel, rp))
                continue
            key = f"{pgt}|{rp}"
            if key in seen:
                continue
            seen.add(key)
            asset_val = f"{abs_prefix.rstrip('/')}/{rp}" if abs_prefix else rp
            w(f"assets.{pgt} : {asset_val}")
            stats["assets"] += 1

        w("")
        stats["games"] += 1

    os.makedirs(outdir, exist_ok=True)
    dst = os.path.join(outdir, f"{system}.metadata.pegasus.txt")
    with open(dst, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")

    return dst, stats, unknown


def exts_hint(system):
    m = {
        "nes": "nes zip", "snes": "sfc smc zip", "gb": "gb zip", "gbc": "gbc zip",
        "gba": "gba zip", "megadrive": "md bin gen zip", "arcade": "zip",
        "fbneo": "7z zip", "cps1": "zip", "cps2": "zip", "cps3": "zip",
        "n64": "z64 n64 v64 rom", "psx": "pbp cue bin chd", "psp": "iso cso",
        "nds": "nds zip", "pcengine": "pce zip",
    }
    return m.get(system, "*")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("gamelist")
    ap.add_argument("outdir")
    ap.add_argument("--system", required=True)
    ap.add_argument("--root", required=True,
                    help="system 目录绝对路径 (gamelist 所在目录)")
    ap.add_argument("--core", default=None,
                    help="RetroArch core 名, 如 fceumm / fbneo")
    ap.add_argument("--collection", default=None)
    ap.add_argument("--manifest", default=None,
                    help="可选: 设备端 find . -type f 的相对路径清单, 用于离线校验")
    ap.add_argument("--abs-prefix", default=None,
                    help="把 file:/assets.* 写成 <abs-prefix>/<相对路径>; "
                         "元数据放在 <配置目录>/metafiles/ 时必须用绝对路径")
    ap.add_argument("--missing-out", default=None,
                    help="可选: 把缺失资产明细写到此文件")
    ap.add_argument("--require-files", action="store_true",
                    help="跳过卡上不存在的 ROM (需要 --manifest)")
    a = ap.parse_args()
    coll = a.collection or a.system.upper()
    man = load_manifest(a.manifest)
    miss = [] if a.missing_out else None
    dst, stats, unknown = convert(
        a.gamelist, a.outdir, a.system, a.root, a.core, coll,
        missing_report=miss, manifest=man, abs_prefix=a.abs_prefix,
        require_files=a.require_files)
    if a.missing_out and miss:
        with open(a.missing_out, "w", encoding="utf-8") as f:
            for s, g, r in miss:
                f.write(f"{s}\t{g}\t{r}\n")
    print(f"[OK] {a.system}: {dst}")
    print(f"     games={stats['games']} assets={stats['assets']} "
          f"asset_missing={stats['skipped_no_file']} "
          f"rom_missing={stats['skipped_no_game']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
