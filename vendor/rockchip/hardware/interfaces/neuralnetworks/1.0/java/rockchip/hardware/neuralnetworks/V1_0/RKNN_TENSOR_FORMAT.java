package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNN_TENSOR_FORMAT {
    public static final int RKNN_TENSOR_NCHW = 0;
    /*
     * data format is NCHW.
     */
    public static final int RKNN_TENSOR_NHWC = 1 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_FORMAT.RKNN_TENSOR_NCHW implicitly + 1 */;
    /*
     * data format is NHWC.
     */
    public static final int RKNN_TENSOR_FORMAT_MAX = 2 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_FORMAT.RKNN_TENSOR_NHWC implicitly + 1 */;
    public static final String toString(int o) {
        if (o == RKNN_TENSOR_NCHW) {
            return "RKNN_TENSOR_NCHW";
        }
        if (o == RKNN_TENSOR_NHWC) {
            return "RKNN_TENSOR_NHWC";
        }
        if (o == RKNN_TENSOR_FORMAT_MAX) {
            return "RKNN_TENSOR_FORMAT_MAX";
        }
        return "0x" + Integer.toHexString(o);
    }

    public static final String dumpBitfield(int o) {
        java.util.ArrayList<String> list = new java.util.ArrayList<>();
        int flipped = 0;
        list.add("RKNN_TENSOR_NCHW"); // RKNN_TENSOR_NCHW == 0
        if ((o & RKNN_TENSOR_NHWC) == RKNN_TENSOR_NHWC) {
            list.add("RKNN_TENSOR_NHWC");
            flipped |= RKNN_TENSOR_NHWC;
        }
        if ((o & RKNN_TENSOR_FORMAT_MAX) == RKNN_TENSOR_FORMAT_MAX) {
            list.add("RKNN_TENSOR_FORMAT_MAX");
            flipped |= RKNN_TENSOR_FORMAT_MAX;
        }
        if (o != flipped) {
            list.add("0x" + Integer.toHexString(o & (~flipped)));
        }
        return String.join(" | ", list);
    }

};

