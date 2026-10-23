#!/system/bin/sh
# RMX35K LED 状态机模块加载器 (v6.1, 参数喂符号地址 + 300ms 周期重刷)
LOG=/data/local/tmp/led_lsm.log
KO=/system/lib/modules/rk817_lsm.ko
[ -f $KO ] || KO=/data/local/tmp/rk817_lsm.ko

echo "$(date) load_led_lsm start" >> $LOG

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
# 等 boot 稳定, 避开 ~19.5s 的 usb none 窗口
U=$(cut -d. -f1 /proc/uptime)
[ "$U" -lt 30 ] && sleep $((30-U))

echo 0 > /proc/sys/kernel/kptr_restrict 2>/dev/null

KS=$(cat /proc/kallsyms)
get() { echo "$KS" | grep -E " (T|t|B|b|D|d|R|r) $1\$" | head -1 | cut -d' ' -f1; }

GTD=$(get gpio_to_desc)
GSRV=$(get gpiod_set_raw_value)
GSV=$(get gpiod_set_value)
PSGP=$(get power_supply_get_property)
PSPU=$(get power_supply_put)
PSGN=$(get power_supply_get_by_name)
PSREG=$(get power_supply_reg_notifier)
PSUNREG=$(get power_supply_unreg_notifier)
DTS=$(get del_timer_sync)
RDW=$(get redled_work)
MT=$(get mod_timer)
JF=$(get jiffies)

echo "$(date) gtd=$GTD gsrv=$GSRV gsv=$GSV psgp=$PSGP rdw=$RDW mt=$MT jf=$JF" >> $LOG

if [ -z "$GTD" ] || [ -z "$GSRV" ] || [ -z "$GSV" ] || [ -z "$PSGP" ] || [ -z "$RDW" ] || [ -z "$MT" ] || [ -z "$JF" ]; then
    echo "$(date) ERROR: symbol missing" >> $LOG
    exit 1
fi

insmod $KO gtd=0x$GTD gsrv=0x$GSRV gsv=0x$GSV psgp=0x$PSGP pspu=0x$PSPU \
    psgn=0x$PSGN psreg=0x$PSREG psunreg=0x$PSUNREG dts=0x$DTS rdw=0x$RDW \
    mt=0x$MT jf=0x$JF
echo "$(date) insmod rc=$?" >> $LOG
