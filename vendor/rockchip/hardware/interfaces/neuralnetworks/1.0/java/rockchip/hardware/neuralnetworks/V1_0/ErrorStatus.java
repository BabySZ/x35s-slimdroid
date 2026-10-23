package rockchip.hardware.neuralnetworks.V1_0;


public final class ErrorStatus {
    public static final int OK = 0;
    public static final int DEVICE_UNAVAILABLE = 1 /* ::rockchip::hardware::neuralnetworks::V1_0::ErrorStatus.OK implicitly + 1 */;
    public static final int GENERAL_FAILURE = 2 /* ::rockchip::hardware::neuralnetworks::V1_0::ErrorStatus.DEVICE_UNAVAILABLE implicitly + 1 */;
    public static final int INVALID_ARGUMENTS = 3 /* ::rockchip::hardware::neuralnetworks::V1_0::ErrorStatus.GENERAL_FAILURE implicitly + 1 */;
    public static final int INVALID_ARGUMENT = 4 /* ::rockchip::hardware::neuralnetworks::V1_0::ErrorStatus.INVALID_ARGUMENTS implicitly + 1 */;
    public static final String toString(int o) {
        if (o == OK) {
            return "OK";
        }
        if (o == DEVICE_UNAVAILABLE) {
            return "DEVICE_UNAVAILABLE";
        }
        if (o == GENERAL_FAILURE) {
            return "GENERAL_FAILURE";
        }
        if (o == INVALID_ARGUMENTS) {
            return "INVALID_ARGUMENTS";
        }
        if (o == INVALID_ARGUMENT) {
            return "INVALID_ARGUMENT";
        }
        return "0x" + Integer.toHexString(o);
    }

    public static final String dumpBitfield(int o) {
        java.util.ArrayList<String> list = new java.util.ArrayList<>();
        int flipped = 0;
        list.add("OK"); // OK == 0
        if ((o & DEVICE_UNAVAILABLE) == DEVICE_UNAVAILABLE) {
            list.add("DEVICE_UNAVAILABLE");
            flipped |= DEVICE_UNAVAILABLE;
        }
        if ((o & GENERAL_FAILURE) == GENERAL_FAILURE) {
            list.add("GENERAL_FAILURE");
            flipped |= GENERAL_FAILURE;
        }
        if ((o & INVALID_ARGUMENTS) == INVALID_ARGUMENTS) {
            list.add("INVALID_ARGUMENTS");
            flipped |= INVALID_ARGUMENTS;
        }
        if ((o & INVALID_ARGUMENT) == INVALID_ARGUMENT) {
            list.add("INVALID_ARGUMENT");
            flipped |= INVALID_ARGUMENT;
        }
        if (o != flipped) {
            list.add("0x" + Integer.toHexString(o & (~flipped)));
        }
        return String.join(" | ", list);
    }

};

