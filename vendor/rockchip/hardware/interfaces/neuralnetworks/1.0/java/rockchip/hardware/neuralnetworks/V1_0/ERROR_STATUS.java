package rockchip.hardware.neuralnetworks.V1_0;


public final class ERROR_STATUS {
    public static final int RKNN_SUCC = 0;
    public static final int RKNN_ERR_FAIL = 1 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_SUCC implicitly + 1 */;
    public static final int RKNN_ERR_TIMEOUT = 2 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_FAIL implicitly + 1 */;
    public static final int RKNN_ERR_DEVICE_UNAVAILABLE = 3 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_TIMEOUT implicitly + 1 */;
    public static final int RKNN_ERR_MALLOC_FAIL = 4 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_DEVICE_UNAVAILABLE implicitly + 1 */;
    public static final int RKNN_ERR_PARAM_INVALID = 5 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_MALLOC_FAIL implicitly + 1 */;
    public static final int RKNN_ERR_MODEL_INVALID = 6 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_PARAM_INVALID implicitly + 1 */;
    public static final int RKNN_ERR_CTX_INVALID = 7 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_MODEL_INVALID implicitly + 1 */;
    public static final int RKNN_ERR_INPUT_INVALID = 8 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_CTX_INVALID implicitly + 1 */;
    public static final int RKNN_ERR_OUTPUT_INVALID = 9 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_INPUT_INVALID implicitly + 1 */;
    public static final int RKNN_ERR_DEVICE_UNMATCH = 10 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_OUTPUT_INVALID implicitly + 1 */;
    public static final int RKNN_ERR_INCOMPATILE_PRE_COMPILE_MODEL = 11 /* ::rockchip::hardware::neuralnetworks::V1_0::ERROR_STATUS.RKNN_ERR_DEVICE_UNMATCH implicitly + 1 */;
    public static final String toString(int o) {
        if (o == RKNN_SUCC) {
            return "RKNN_SUCC";
        }
        if (o == RKNN_ERR_FAIL) {
            return "RKNN_ERR_FAIL";
        }
        if (o == RKNN_ERR_TIMEOUT) {
            return "RKNN_ERR_TIMEOUT";
        }
        if (o == RKNN_ERR_DEVICE_UNAVAILABLE) {
            return "RKNN_ERR_DEVICE_UNAVAILABLE";
        }
        if (o == RKNN_ERR_MALLOC_FAIL) {
            return "RKNN_ERR_MALLOC_FAIL";
        }
        if (o == RKNN_ERR_PARAM_INVALID) {
            return "RKNN_ERR_PARAM_INVALID";
        }
        if (o == RKNN_ERR_MODEL_INVALID) {
            return "RKNN_ERR_MODEL_INVALID";
        }
        if (o == RKNN_ERR_CTX_INVALID) {
            return "RKNN_ERR_CTX_INVALID";
        }
        if (o == RKNN_ERR_INPUT_INVALID) {
            return "RKNN_ERR_INPUT_INVALID";
        }
        if (o == RKNN_ERR_OUTPUT_INVALID) {
            return "RKNN_ERR_OUTPUT_INVALID";
        }
        if (o == RKNN_ERR_DEVICE_UNMATCH) {
            return "RKNN_ERR_DEVICE_UNMATCH";
        }
        if (o == RKNN_ERR_INCOMPATILE_PRE_COMPILE_MODEL) {
            return "RKNN_ERR_INCOMPATILE_PRE_COMPILE_MODEL";
        }
        return "0x" + Integer.toHexString(o);
    }

    public static final String dumpBitfield(int o) {
        java.util.ArrayList<String> list = new java.util.ArrayList<>();
        int flipped = 0;
        list.add("RKNN_SUCC"); // RKNN_SUCC == 0
        if ((o & RKNN_ERR_FAIL) == RKNN_ERR_FAIL) {
            list.add("RKNN_ERR_FAIL");
            flipped |= RKNN_ERR_FAIL;
        }
        if ((o & RKNN_ERR_TIMEOUT) == RKNN_ERR_TIMEOUT) {
            list.add("RKNN_ERR_TIMEOUT");
            flipped |= RKNN_ERR_TIMEOUT;
        }
        if ((o & RKNN_ERR_DEVICE_UNAVAILABLE) == RKNN_ERR_DEVICE_UNAVAILABLE) {
            list.add("RKNN_ERR_DEVICE_UNAVAILABLE");
            flipped |= RKNN_ERR_DEVICE_UNAVAILABLE;
        }
        if ((o & RKNN_ERR_MALLOC_FAIL) == RKNN_ERR_MALLOC_FAIL) {
            list.add("RKNN_ERR_MALLOC_FAIL");
            flipped |= RKNN_ERR_MALLOC_FAIL;
        }
        if ((o & RKNN_ERR_PARAM_INVALID) == RKNN_ERR_PARAM_INVALID) {
            list.add("RKNN_ERR_PARAM_INVALID");
            flipped |= RKNN_ERR_PARAM_INVALID;
        }
        if ((o & RKNN_ERR_MODEL_INVALID) == RKNN_ERR_MODEL_INVALID) {
            list.add("RKNN_ERR_MODEL_INVALID");
            flipped |= RKNN_ERR_MODEL_INVALID;
        }
        if ((o & RKNN_ERR_CTX_INVALID) == RKNN_ERR_CTX_INVALID) {
            list.add("RKNN_ERR_CTX_INVALID");
            flipped |= RKNN_ERR_CTX_INVALID;
        }
        if ((o & RKNN_ERR_INPUT_INVALID) == RKNN_ERR_INPUT_INVALID) {
            list.add("RKNN_ERR_INPUT_INVALID");
            flipped |= RKNN_ERR_INPUT_INVALID;
        }
        if ((o & RKNN_ERR_OUTPUT_INVALID) == RKNN_ERR_OUTPUT_INVALID) {
            list.add("RKNN_ERR_OUTPUT_INVALID");
            flipped |= RKNN_ERR_OUTPUT_INVALID;
        }
        if ((o & RKNN_ERR_DEVICE_UNMATCH) == RKNN_ERR_DEVICE_UNMATCH) {
            list.add("RKNN_ERR_DEVICE_UNMATCH");
            flipped |= RKNN_ERR_DEVICE_UNMATCH;
        }
        if ((o & RKNN_ERR_INCOMPATILE_PRE_COMPILE_MODEL) == RKNN_ERR_INCOMPATILE_PRE_COMPILE_MODEL) {
            list.add("RKNN_ERR_INCOMPATILE_PRE_COMPILE_MODEL");
            flipped |= RKNN_ERR_INCOMPATILE_PRE_COMPILE_MODEL;
        }
        if (o != flipped) {
            list.add("0x" + Integer.toHexString(o & (~flipped)));
        }
        return String.join(" | ", list);
    }

};

