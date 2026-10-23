package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNN_TENSOR_TYPE {
    public static final int RKNN_TENSOR_FLOAT32 = 0;
    /*
     * data type is float32.
     */
    public static final int RKNN_TENSOR_FLOAT16 = 1 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_TYPE.RKNN_TENSOR_FLOAT32 implicitly + 1 */;
    /*
     * data type is float16.
     */
    public static final int RKNN_TENSOR_INT8 = 2 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_TYPE.RKNN_TENSOR_FLOAT16 implicitly + 1 */;
    /*
     * data type is int8.
     */
    public static final int RKNN_TENSOR_UINT8 = 3 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_TYPE.RKNN_TENSOR_INT8 implicitly + 1 */;
    /*
     * data type is uint8.
     */
    public static final int RKNN_TENSOR_INT16 = 4 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_TYPE.RKNN_TENSOR_UINT8 implicitly + 1 */;
    /*
     * data type is int16.
     */
    public static final int RKNN_TENSOR_TYPE_MAX = 5 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_TENSOR_TYPE.RKNN_TENSOR_INT16 implicitly + 1 */;
    public static final String toString(int o) {
        if (o == RKNN_TENSOR_FLOAT32) {
            return "RKNN_TENSOR_FLOAT32";
        }
        if (o == RKNN_TENSOR_FLOAT16) {
            return "RKNN_TENSOR_FLOAT16";
        }
        if (o == RKNN_TENSOR_INT8) {
            return "RKNN_TENSOR_INT8";
        }
        if (o == RKNN_TENSOR_UINT8) {
            return "RKNN_TENSOR_UINT8";
        }
        if (o == RKNN_TENSOR_INT16) {
            return "RKNN_TENSOR_INT16";
        }
        if (o == RKNN_TENSOR_TYPE_MAX) {
            return "RKNN_TENSOR_TYPE_MAX";
        }
        return "0x" + Integer.toHexString(o);
    }

    public static final String dumpBitfield(int o) {
        java.util.ArrayList<String> list = new java.util.ArrayList<>();
        int flipped = 0;
        list.add("RKNN_TENSOR_FLOAT32"); // RKNN_TENSOR_FLOAT32 == 0
        if ((o & RKNN_TENSOR_FLOAT16) == RKNN_TENSOR_FLOAT16) {
            list.add("RKNN_TENSOR_FLOAT16");
            flipped |= RKNN_TENSOR_FLOAT16;
        }
        if ((o & RKNN_TENSOR_INT8) == RKNN_TENSOR_INT8) {
            list.add("RKNN_TENSOR_INT8");
            flipped |= RKNN_TENSOR_INT8;
        }
        if ((o & RKNN_TENSOR_UINT8) == RKNN_TENSOR_UINT8) {
            list.add("RKNN_TENSOR_UINT8");
            flipped |= RKNN_TENSOR_UINT8;
        }
        if ((o & RKNN_TENSOR_INT16) == RKNN_TENSOR_INT16) {
            list.add("RKNN_TENSOR_INT16");
            flipped |= RKNN_TENSOR_INT16;
        }
        if ((o & RKNN_TENSOR_TYPE_MAX) == RKNN_TENSOR_TYPE_MAX) {
            list.add("RKNN_TENSOR_TYPE_MAX");
            flipped |= RKNN_TENSOR_TYPE_MAX;
        }
        if (o != flipped) {
            list.add("0x" + Integer.toHexString(o & (~flipped)));
        }
        return String.join(" | ", list);
    }

};

