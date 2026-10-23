package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNN_HW_BUFFER_TYPE {
    public static final int HW_BUFFER_DRM = 0;
    public static final int HW_BUFFER_ION = 1 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_HW_BUFFER_TYPE.HW_BUFFER_DRM implicitly + 1 */;
    public static final int HW_BUFFER_ASHMEM = 2 /* ::rockchip::hardware::neuralnetworks::V1_0::RKNN_HW_BUFFER_TYPE.HW_BUFFER_ION implicitly + 1 */;
    public static final String toString(int o) {
        if (o == HW_BUFFER_DRM) {
            return "HW_BUFFER_DRM";
        }
        if (o == HW_BUFFER_ION) {
            return "HW_BUFFER_ION";
        }
        if (o == HW_BUFFER_ASHMEM) {
            return "HW_BUFFER_ASHMEM";
        }
        return "0x" + Integer.toHexString(o);
    }

    public static final String dumpBitfield(int o) {
        java.util.ArrayList<String> list = new java.util.ArrayList<>();
        int flipped = 0;
        list.add("HW_BUFFER_DRM"); // HW_BUFFER_DRM == 0
        if ((o & HW_BUFFER_ION) == HW_BUFFER_ION) {
            list.add("HW_BUFFER_ION");
            flipped |= HW_BUFFER_ION;
        }
        if ((o & HW_BUFFER_ASHMEM) == HW_BUFFER_ASHMEM) {
            list.add("HW_BUFFER_ASHMEM");
            flipped |= HW_BUFFER_ASHMEM;
        }
        if (o != flipped) {
            list.add("0x" + Integer.toHexString(o & (~flipped)));
        }
        return String.join(" | ", list);
    }

};

