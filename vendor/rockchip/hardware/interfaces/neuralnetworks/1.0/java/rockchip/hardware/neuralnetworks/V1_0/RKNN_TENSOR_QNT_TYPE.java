package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNN_TENSOR_QNT_TYPE {
    public static final int RKNN_TENSOR_QNT_NONE = 0;
    /*
     * none.
     */
    public static final int RKNN_TENSOR_QNT_DFP = 1 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_QNT_TYPE.RKNN_TENSOR_QNT_NONE implicitly + 1 */;
    /*
     * dynamic fixed point.
     */
    public static final int RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC = 2 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_QNT_TYPE.RKNN_TENSOR_QNT_DFP implicitly + 1 */;
    /*
     * asymmetric affine.
     */
    public static final int RKNN_TENSOR_QNT_MAX = 3 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_QNT_TYPE.RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC implicitly + 1 */;
    public static final String toString(int o) {
        if (o == RKNN_TENSOR_QNT_NONE) {
            return "RKNN_TENSOR_QNT_NONE";
        }
        if (o == RKNN_TENSOR_QNT_DFP) {
            return "RKNN_TENSOR_QNT_DFP";
        }
        if (o == RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC) {
            return "RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC";
        }
        if (o == RKNN_TENSOR_QNT_MAX) {
            return "RKNN_TENSOR_QNT_MAX";
        }
        return "0x" + Integer.toHexString(o);
    }

    public static final String dumpBitfield(int o) {
        java.util.ArrayList<String> list = new java.util.ArrayList<>();
        int flipped = 0;
        list.add("RKNN_TENSOR_QNT_NONE"); // RKNN_TENSOR_QNT_NONE == 0
        if ((o & RKNN_TENSOR_QNT_DFP) == RKNN_TENSOR_QNT_DFP) {
            list.add("RKNN_TENSOR_QNT_DFP");
            flipped |= RKNN_TENSOR_QNT_DFP;
        }
        if ((o & RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC) == RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC) {
            list.add("RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC");
            flipped |= RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC;
        }
        if ((o & RKNN_TENSOR_QNT_MAX) == RKNN_TENSOR_QNT_MAX) {
            list.add("RKNN_TENSOR_QNT_MAX");
            flipped |= RKNN_TENSOR_QNT_MAX;
        }
        if (o != flipped) {
            list.add("0x" + Integer.toHexString(o & (~flipped)));
        }
        return String.join(" | ", list);
    }

};

