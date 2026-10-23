package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNNDeviceID {
    public int n_devices = 0;
    /*
     * the number of devices.
     */
    public String[/* 256 */] types = new String[256];
    /*
     * the array of device type.
     */
    public String[/* 256 */] ids = new String[256];

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RKNNDeviceID.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RKNNDeviceID other = (rockchip.hardware.neuralnetworks.V1_0.RKNNDeviceID)otherObject;
        if (this.n_devices != other.n_devices) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.types, other.types)) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.ids, other.ids)) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.n_devices), 
                android.os.HidlSupport.deepHashCode(this.types), 
                android.os.HidlSupport.deepHashCode(this.ids));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".n_devices = ");
        builder.append(this.n_devices);
        builder.append(", .types = ");
        builder.append(java.util.Arrays.toString(this.types));
        builder.append(", .ids = ");
        builder.append(java.util.Arrays.toString(this.ids));
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(8200 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RKNNDeviceID> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RKNNDeviceID> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 8200,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RKNNDeviceID _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RKNNDeviceID();
                ((rockchip.hardware.neuralnetworks.V1_0.RKNNDeviceID) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 8200);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        n_devices = _hidl_blob.getInt32(_hidl_offset + 0);
        {
            long _hidl_array_offset_0 = _hidl_offset + 8;
            for (int _hidl_index_0_0 = 0; _hidl_index_0_0 < 256; ++_hidl_index_0_0) {
                ((String[/* 256 */]) types)[_hidl_index_0_0] = _hidl_blob.getString(_hidl_array_offset_0);

                parcel.readEmbeddedBuffer(
                        ((String) ((String[/* 256 */]) types)[_hidl_index_0_0]).getBytes().length + 1,
                        _hidl_blob.handle(),
                        _hidl_array_offset_0 + 0 /* offsetof(hidl_string, mBuffer) */,false /* nullable */);

                _hidl_array_offset_0 += 16;
            }
        }
        {
            long _hidl_array_offset_0 = _hidl_offset + 4104;
            for (int _hidl_index_0_0 = 0; _hidl_index_0_0 < 256; ++_hidl_index_0_0) {
                ((String[/* 256 */]) ids)[_hidl_index_0_0] = _hidl_blob.getString(_hidl_array_offset_0);

                parcel.readEmbeddedBuffer(
                        ((String) ((String[/* 256 */]) ids)[_hidl_index_0_0]).getBytes().length + 1,
                        _hidl_blob.handle(),
                        _hidl_array_offset_0 + 0 /* offsetof(hidl_string, mBuffer) */,false /* nullable */);

                _hidl_array_offset_0 += 16;
            }
        }
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(8200 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RKNNDeviceID> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 8200));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 8200);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putInt32(_hidl_offset + 0, n_devices);
        {
            long _hidl_array_offset_0 = _hidl_offset + 8;
            for (int _hidl_index_0_0 = 0; _hidl_index_0_0 < 256; ++_hidl_index_0_0) {
                _hidl_blob.putString(_hidl_array_offset_0, ((String[/* 256 */]) types)[_hidl_index_0_0]);
                _hidl_array_offset_0 += 16;
            }
        }
        {
            long _hidl_array_offset_0 = _hidl_offset + 4104;
            for (int _hidl_index_0_0 = 0; _hidl_index_0_0 < 256; ++_hidl_index_0_0) {
                _hidl_blob.putString(_hidl_array_offset_0, ((String[/* 256 */]) ids)[_hidl_index_0_0]);
                _hidl_array_offset_0 += 16;
            }
        }
    }
};

