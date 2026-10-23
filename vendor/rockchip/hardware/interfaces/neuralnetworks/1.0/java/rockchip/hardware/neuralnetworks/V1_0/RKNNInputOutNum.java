package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNNInputOutNum {
    public int n_input = 0;
    /*
     * the number of input.
     */
    public int n_output = 0;

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RKNNInputOutNum.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RKNNInputOutNum other = (rockchip.hardware.neuralnetworks.V1_0.RKNNInputOutNum)otherObject;
        if (this.n_input != other.n_input) {
            return false;
        }
        if (this.n_output != other.n_output) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.n_input), 
                android.os.HidlSupport.deepHashCode(this.n_output));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".n_input = ");
        builder.append(this.n_input);
        builder.append(", .n_output = ");
        builder.append(this.n_output);
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(8 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RKNNInputOutNum> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RKNNInputOutNum> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 8,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RKNNInputOutNum _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RKNNInputOutNum();
                ((rockchip.hardware.neuralnetworks.V1_0.RKNNInputOutNum) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 8);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        n_input = _hidl_blob.getInt32(_hidl_offset + 0);
        n_output = _hidl_blob.getInt32(_hidl_offset + 4);
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(8 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RKNNInputOutNum> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 8));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 8);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putInt32(_hidl_offset + 0, n_input);
        _hidl_blob.putInt32(_hidl_offset + 4, n_output);
    }
};

