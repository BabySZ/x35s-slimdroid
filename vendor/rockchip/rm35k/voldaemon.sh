#!/system/bin/sh
# voldaemon 3.0 — 精简版
# 1) 音量键(/dev/input/event2): 直接调 AudioService(绕过固件 PWM 吞键 bug)
# 2) 音量+ 和 音量- 同时按下 → 发送 BACK 键

LOG=/data/local/tmp/voldaemon.log
CODE=10   # AudioService.setStreamVolume transact id (本机实测)
STREAM=3
DEVICE=2

vol_step() {
    CUR=$(settings get system volume_music_speaker)
    case "$CUR" in ''|*[!0-9]*) CUR=9 ;; esac
    NEW=$((CUR + $1))
    [ $NEW -gt 15 ] && NEW=15
    [ $NEW -lt 0 ] && NEW=0
    service call audio $CODE i32 $STREAM i32 $NEW i32 $DEVICE >/dev/null
    settings put system volume_music_speaker $NEW
    echo "$(date) volume $CUR->$NEW" >> $LOG
}

UP=0
DOWN=0
echo "$(date) voldaemon 3.0 start (vol + volcombo=BACK)" >> $LOG

getevent -ql /dev/input/event2 | while read typ code val; do
    case "$code" in
        KEY_VOLUMEUP)
            if [ "$val" = "DOWN" ]; then
                UP=1
                if [ $DOWN -eq 1 ]; then
                    echo "$(date) VOL+ & VOL- -> BACK" >> $LOG
                    input keyevent 4
                else
                    vol_step 1
                fi
            else
                UP=0
            fi
            ;;
        KEY_VOLUMEDOWN)
            if [ "$val" = "DOWN" ]; then
                DOWN=1
                if [ $UP -eq 1 ]; then
                    echo "$(date) VOL+ & VOL- -> BACK" >> $LOG
                    input keyevent 4
                else
                    vol_step -1
                fi
            else
                DOWN=0
            fi
            ;;
    esac
done
