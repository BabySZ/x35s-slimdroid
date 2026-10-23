#!/bin/bash
source shared_vals.sh
echo "******* Flashing AOSP to PineNote *******"

echo "Checking if the device is connected and in Maskrom mode"
while true; do
    # We are running rkdeveloptool list to see if we have a device connected
    # and what mode it is in (Maskrom or Loader)
    # If we are in Maskrom mode, we can continue
    # If we are in Loader mode, we can reboot into Maskrom
    # If we are not in Maskrom or Loader mode, we will wait and try again
    DEVICE_LIST=$(rkdeveloptool list 2>/dev/null)
    if echo $DEVICE_LIST | grep -q "Maskrom"; then
        echo "Device ready"
        break
    elif echo $DEVICE_LIST | grep -q "Loader"; then
        echo "Device in Loader mode, rebooting into Maskrom"
        rkdeveloptool reboot-maskrom
    else
        echo "Device not found, please connect a device"
    fi
    sleep 2
done

echo "Loading spl loader"
timeout 15 rkdeveloptool db rockdev/Image-aosp_pinenote/MiniLoaderAll.bin
if [ $? -ne 0 ]; then
    echo "Failed to load spl loader"
    exit 1
fi

echo "Erasing flash"
rkdeveloptool erase-flash
if [ $? -ne 0 ]; then
    echo "Failed to erase flash"
    exit 1
fi

echo "Writing gpt partitions"
timeout 15 rkdeveloptool gpt $PRODUCT_OUT/parameter.txt
if [ $? -ne 0 ]; then
    echo "Failed to write partition table"
    echo "Aborting..."
    exit 1
fi

# Now we loop through each partition and restore it
for partition in $BUILT_IMAGES; do
    echo "Writing $partition"
    rkdeveloptool write-partition $partition $PRODUCT_OUT/$partition.img
    if [ $? -ne 0 ]; then
        echo "Failed to write $partition"
        echo "Aborting..."
        exit 1
    fi
done

echo "Upgrading loader"
# This step is necessary since the loader is deleted with the erase flash command
timeout 15 rkdeveloptool ul rockdev/Image-aosp_pinenote/MiniLoaderAll.bin
if [ $? -ne 0 ]; then
    echo "Failed to upgrade loader"
    exit 1
fi

echo "DONE: You can now reboot the device"
echo "******* Done *******"