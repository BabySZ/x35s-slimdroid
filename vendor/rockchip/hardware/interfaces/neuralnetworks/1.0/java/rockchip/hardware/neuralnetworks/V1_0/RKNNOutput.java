package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNNOutput {
    public byte want_float = 0;
    /*
     * want transfer output data to float
     */
    public byte is_prealloc = 0;
    /*
     * whether buf is pre-allocated.
     * if TRUE, the following variables need to be set.
     * if FALSE, the following variables do not need to be set.
     */
    public int index = 0;
    /*
     * the output index.
     */
    public rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer buf = new rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer();
    /*
     * the output buf for index.
     * when is_prealloc = FALSE and rknn_outputs_release called,
     * this buf pointer will be free and don't use it anymore.
     */
    public int size = 0;

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RKNNOutput.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RKNNOutput other = (rockchip.hardware.neuralnetworks.V1_0.RKNNOutput)otherObject;
        if (this.want_float != other.want_float) {
            return false;
        }
        if (this.is_prealloc != other.is_prealloc) {
            return false;
        }
        if (this.index != other.index) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.buf, other.buf)) {
            return false;
        }
        if (this.size != other.size) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.want_float), 
                android.os.HidlSupport.deepHashCode(this.is_prealloc), 
                android.os.HidlSupport.deepHashCode(this.index), 
                android.os.HidlSupport.deepHashCode(this.buf), 
                android.os.HidlSupport.deepHashCode(this.size));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".want_float = ");
        builder.append(this.want_float);
        builder.append(", .is_prealloc = ");
        builder.append(this.is_prealloc);
        builder.append(", .index = ");
        builder.append(this.index);
        builder.append(", .buf = ");
        builder.append(this.buf);
        builder.append(", .size = ");
        builder.append(this.size);
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(48 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RKNNOutput> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RKNNOutput> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 48,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RKNNOutput _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RKNNOutput();
                ((rockchip.hardware.neuralnetworks.V1_0.RKNNOutput) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 48);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        want_float = _hidl_blob.getInt8(_hidl_offset + 0);
        is_prealloc = _hidl_blob.getInt8(_hidl_offset + 1);
        index = _hidl_blob.getInt32(_hidl_offset + 4);
        ((rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer) buf).readEmbeddedFromParcel(parcel, _hidl_blob, _hidl_offset + 8);
        size = _hidl_blob.getInt32(_hidl_offset + 40);
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(48 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RKNNOutput> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 48));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 48);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putInt8(_hidl_offset + 0, want_float);
        _hidl_blob.putInt8(_hidl_offset + 1, is_prealloc);
        _hidl_blob.putInt32(_hidl_offset + 4, index);
        buf.writeEmbeddedToBlob(_hidl_blob, _hidl_offset + 8);
        _hidl_blob.putInt32(_hidl_offset + 40, size);
    }
};

