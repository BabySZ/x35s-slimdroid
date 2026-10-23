package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNN_QUERY_CMD {
    public static final int RKNN_QUERY_IN_OUT_NUM = 0;
    /*
     * query the number of input & output tensor.
     */
    public static final int RKNN_QUERY_INPUT_ATTR = 1 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_QUERY_CMD.RKNN_QUERY_IN_OUT_NUM implicitly + 1 */;
    /*
     * query the attribute of input tensor.
     */
    public static final int RKNN_QUERY_OUTPUT_ATTR = 2 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_QUERY_CMD.RKNN_QUERY_INPUT_ATTR implicitly + 1 */;
    /*
     * query the attribute of output tensor.
     */
    public static final int RKNN_QUERY_PERF_DETAIL = 3 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_QUERY_CMD.RKNN_QUERY_OUTPUT_ATTR implicitly + 1 */;
    /*
     * query the detail performance, need set
     * RKNN_FLAG_COLLECT_PERF_MASK when call rknn_init,
     * this query needs to be valid after rknn_outputs_get.
     */
    public static final int RKNN_QUERY_PERF_RUN = 4 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_QUERY_CMD.RKNN_QUERY_PERF_DETAIL implicitly + 1 */;
    /*
     * query the time of run,
     * this query needs to be valid after rknn_outputs_get.
     */
    public static final int RKNN_QUERY_SDK_VERSION = 5 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_QUERY_CMD.RKNN_QUERY_PERF_RUN implicitly + 1 */;
    /*
     * query the sdk & driver version
     */
    public static final int RKNN_QUERY_CMD_MAX = 6 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_QUERY_CMD.RKNN_QUERY_SDK_VERSION implicitly + 1 */;
    public static final String toString(int o) {
        if (o == RKNN_QUERY_IN_OUT_NUM) {
            return "RKNN_QUERY_IN_OUT_NUM";
        }
        if (o == RKNN_QUERY_INPUT_ATTR) {
            return "RKNN_QUERY_INPUT_ATTR";
        }
        if (o == RKNN_QUERY_OUTPUT_ATTR) {
            return "RKNN_QUERY_OUTPUT_ATTR";
        }
        if (o == RKNN_QUERY_PERF_DETAIL) {
            return "RKNN_QUERY_PERF_DETAIL";
        }
        if (o == RKNN_QUERY_PERF_RUN) {
            return "RKNN_QUERY_PERF_RUN";
        }
        if (o == RKNN_QUERY_SDK_VERSION) {
            return "RKNN_QUERY_SDK_VERSION";
        }
        if (o == RKNN_QUERY_CMD_MAX) {
            return "RKNN_QUERY_CMD_MAX";
        }
        return "0x" + Integer.toHexString(o);
    }

    public static final String dumpBitfield(int o) {
        java.util.ArrayList<String> list = new java.util.ArrayList<>();
        int flipped = 0;
        list.add("RKNN_QUERY_IN_OUT_NUM"); // RKNN_QUERY_IN_OUT_NUM == 0
        if ((o & RKNN_QUERY_INPUT_ATTR) == RKNN_QUERY_INPUT_ATTR) {
            list.add("RKNN_QUERY_INPUT_ATTR");
            flipped |= RKNN_QUERY_INPUT_ATTR;
        }
        if ((o & RKNN_QUERY_OUTPUT_ATTR) == RKNN_QUERY_OUTPUT_ATTR) {
            list.add("RKNN_QUERY_OUTPUT_ATTR");
            flipped |= RKNN_QUERY_OUTPUT_ATTR;
        }
        if ((o & RKNN_QUERY_PERF_DETAIL) == RKNN_QUERY_PERF_DETAIL) {
            list.add("RKNN_QUERY_PERF_DETAIL");
            flipped |= RKNN_QUERY_PERF_DETAIL;
        }
        if ((o & RKNN_QUERY_PERF_RUN) == RKNN_QUERY_PERF_RUN) {
            list.add("RKNN_QUERY_PERF_RUN");
            flipped |= RKNN_QUERY_PERF_RUN;
        }
        if ((o & RKNN_QUERY_SDK_VERSION) == RKNN_QUERY_SDK_VERSION) {
            list.add("RKNN_QUERY_SDK_VERSION");
            flipped |= RKNN_QUERY_SDK_VERSION;
        }
        if ((o & RKNN_QUERY_CMD_MAX) == RKNN_QUERY_CMD_MAX) {
            list.add("RKNN_QUERY_CMD_MAX");
            flipped |= RKNN_QUERY_CMD_MAX;
        }
        if (o != flipped) {
            list.add("0x" + Integer.toHexString(o & (~flipped)));
        }
        return String.join(" | ", list);
    }

};

