#!/bin/bash
##################################################################
# Creates a parameter.txt file for generating the gpt partitions #
##################################################################

# We do not include userdata as it is considered default
source shared_vals.sh

START_BLOCK=4000
CURRENT_BLOCK=$START_BLOCK
CURRENT_BLOCK_HEX=$(printf "0x%08x" $CURRENT_BLOCK)

# We will start by dumping the header information
echo "FIRMWARE_VER: 11.0" > $PRODUCT_OUT/parameter.txt
echo "MACHINE_MODEL: rk3566_eink" >> $PRODUCT_OUT/parameter.txt
echo "MACHINE_ID: 007" >> $PRODUCT_OUT/parameter.txt
echo "MANUFACTURER: rockchip" >> $PRODUCT_OUT/parameter.txt
echo "MAGIC: 0x5041524B" >> $PRODUCT_OUT/parameter.txt
echo "ATAG: 0x00200800" >> $PRODUCT_OUT/parameter.txt
echo "MACHINE: pinenote" >> $PRODUCT_OUT/parameter.txt
echo "CHECK_MASK: 0x80" >> $PRODUCT_OUT/parameter.txt
echo "PWR_HLD: 0,0,A,0,1" >> $PRODUCT_OUT/parameter.txt
echo "TYPE: GPT" >> $PRODUCT_OUT/parameter.txt
echo -n "CMDLINE:mtdparts=rk29xxnand:" >> $PRODUCT_OUT/parameter.txt

# We loop through each partition and calculate the start block and the block size
# Some of the partitions need a set size (e.g. cache and super) the reset will be calculated
# based on the size of the partition
for PARTITION in $PARTITIONS; do
    [ ! -f $PRODUCT_OUT/$PARTITION.img ] && echo $BUILT_IMAGES | grep -q $PARTITION && continue
    if [ $? -eq 0 ]; then
        echo "Error: $PARTITION.img does not exist"
        echo "Ensure that it has been built and is in $PRODUCT_OUT"
        exit 1
    fi
    BYTE_SIZE=$(stat -c%s $PRODUCT_OUT/$PARTITION.img 2>/dev/null)
    # We now have a switch statement to handle the different partitions
    case $PARTITION in
        super)
            BYTE_SIZE=3263168512
            ;;
        cache)
            BYTE_SIZE=3263168512
            ;;
        metadata)
            BYTE_SIZE=16777216
            ;;
        trust)
            BYTE_SIZE=4194304
            ;;
        # Default just exit
        *)
            ;;
    esac
    # Calculating the block size
    BLOCK_SIZE=$(($BYTE_SIZE / 512))
    # If the block size is not a multiple of 512, we need to round up
    if [ $((BYTE_SIZE % 512)) -ne 0 ]; then
        BLOCK_SIZE=$(($BLOCK_SIZE + 1))
    fi
    # Generating the hex representation of the block size(padded to 8 characters)
    BLOCK_SIZE_HEX=$(printf "0x%08x" $BLOCK_SIZE)
    # Get the current block in hex
    
    # Writing out the partition information
    echo -n "$BLOCK_SIZE_HEX@$CURRENT_BLOCK_HEX($PARTITION)," >> $PRODUCT_OUT/parameter.txt
    # Incrementing the current block
    CURRENT_BLOCK=$(($CURRENT_BLOCK + $BLOCK_SIZE))
    CURRENT_BLOCK_HEX=$(printf "0x%08x" $CURRENT_BLOCK)
done

# Now we write the userdata partition
echo "-@$CURRENT_BLOCK_HEX(userdata:grow)" >> $PRODUCT_OUT/parameter.txt