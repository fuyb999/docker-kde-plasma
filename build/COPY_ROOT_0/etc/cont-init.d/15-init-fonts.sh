#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/aura-dev/etc/environment.sh

export ADDON_FONTS_DIR="${XDG_ADDONS_HOME}/fonts"

HOME_FONT="$HOME/.fonts"
MOST_DISTROS="/usr/share/fonts"
RHL5="/usr/X11R6/lib/X11/fonts"
RHL6="/usr/X11R6/lib/X11/fonts"

if test -e $MOST_DISTROS ; then
        FONT_PATH=$MOST_DISTROS
elif test -e $RHL5 ; then
        FONT_PATH=$RHL5
elif test -e $RHL6 ; then
        FONT_PATH=$RHL6
else
        FONT_PATH=$HOME_FONT
fi

FONT_PATH="$FONT_PATH/custom-fonts"

if [ ! -d "$FONT_PATH" ]; then
  echo "Creating $FONT_PATH Font Directory..."
  sudo mkdir -p $FONT_PATH
fi

# 获取当前已缓存的字体列表
echo "Checking existing font cache..."
CACHED_FONTS=$(fc-list --format="%{file}\n" 2>/dev/null | sort)

# 计数器
INSTALLED_COUNT=0
SKIPPED_COUNT=0

echo "Checking and installing fonts..."

# 查找所有字体文件
find "$ADDON_FONTS_DIR" -type f \( -name "*.ttf" -o -name "*.TTF" -o -name "*.ttc" -o -name "*.otf" -o -name "*.woff" -o -name "*.woff2" \) | while read -r font_file; do
    font_filename=$(basename "$font_file")
    dest_file="$FONT_PATH/$font_filename"

    # 检查字体是否已经在目标目录且未被修改
    if [ -f "$dest_file" ]; then
        # 比较源文件和目标文件的MD5校验和
        src_md5=$(md5sum "$font_file" | cut -d' ' -f1)
        dest_md5=$(md5sum "$dest_file" | cut -d' ' -f1 2>/dev/null || echo "")

        if [ "$src_md5" = "$dest_md5" ]; then
            # 文件已存在且相同，检查是否已缓存
            if echo "$CACHED_FONTS" | grep -q "$dest_file"; then
                echo "✓ Already cached: $font_filename"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
        fi
    fi

    # 检查字体是否已在系统缓存中（通过不同路径）
    font_already_cached=false
    while IFS= read -r cached_font; do
        if [ -f "$cached_font" ]; then
            cached_md5=$(md5sum "$cached_font" | cut -d' ' -f1 2>/dev/null || echo "")
            src_md5=$(md5sum "$font_file" | cut -d' ' -f1)
            if [ "$cached_md5" = "$src_md5" ]; then
                font_already_cached=true
                break
            fi
        fi
    done <<< "$CACHED_FONTS"

    if [ "$font_already_cached" = true ]; then
        echo "✓ Already cached elsewhere: $font_filename"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    else
        # 复制字体文件
        echo "↑ Installing: $font_filename"
        sudo cp "$font_file" "$dest_file"
        sudo chmod 644 "$dest_file"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
done

# 由于while循环在子shell中运行，我们需要另一种方式来获取计数
# 重新计算实际安装和跳过的数量
ACTUAL_INSTALLED=0
ACTUAL_SKIPPED=0

for font_file in "$ADDON_FONTS_DIR"/*.ttf "$ADDON_FONTS_DIR"/*.TTF "$ADDON_FONTS_DIR"/*.ttc "$ADDON_FONTS_DIR"/*.otf "$ADDON_FONTS_DIR"/*.woff "$ADDON_FONTS_DIR"/*.woff2; do
    [ -e "$font_file" ] || continue  # 处理没有匹配文件的情况

    font_filename=$(basename "$font_file")
    dest_file="$FONT_PATH/$font_filename"

    if [ -f "$dest_file" ]; then
        src_md5=$(md5sum "$font_file" | cut -d' ' -f1)
        dest_md5=$(md5sum "$dest_file" | cut -d' ' -f1 2>/dev/null || echo "")

        if [ "$src_md5" = "$dest_md5" ] && echo "$CACHED_FONTS" | grep -q "$dest_file"; then
            ACTUAL_SKIPPED=$((ACTUAL_SKIPPED + 1))
        else
            ACTUAL_INSTALLED=$((ACTUAL_INSTALLED + 1))
        fi
    else
        ACTUAL_INSTALLED=$((ACTUAL_INSTALLED + 1))
    fi
done

echo "Font installation summary:"
echo "  Installed: $ACTUAL_INSTALLED"
echo "  Skipped (already cached): $ACTUAL_SKIPPED"

if [ $ACTUAL_INSTALLED -gt 0 ]; then
    echo "Rebuilding Font Cache..."
    sudo fc-cache -vfs
    echo "Font cache updated."
else
    echo "No new fonts to cache."
fi

echo "Installation Finished."

# vim:ft=sh:ts=4:sw=4:et:sts=4