PARTITIONS="uboot waveform trust misc dtbo vbmeta boot recovery metadata cache super"
BUILT_IMAGES="uboot boot recovery misc dtbo vbmeta super waveform"
PRODUCT_OUT="rockdev/Image-aosp_pinenote"

contains() {
    [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]] && exit 0 || exit 1
}