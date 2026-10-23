package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNNInput {
    public int index = 0;
    /*
     * the input index.
     */
    public rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer buf = new rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer();
    /*
     * the input buf for index.
     */
    public int size = 0;
    /*
     * the size of input buf.
     */
    public byte pass_through = 0;
    /*
     * pass through mode.
     * if TRUE, the buf data is passed directly to the input node of the rknn model
     * without any conversion. the following variables do not need to be set.
     * if FALSE, the buf data is converted into an input consistent with the model
     * according to the following type and fmt. so the following variables
     * need to be set.
     */
    public int type = 0;
    /*
     * the data type of input buf.
     */
    public int fmt = 0;

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RKNNInput.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RKNNInput other = (rockchip.hardware.neuralnetworks.V1_0.RKNNInput)otherObject;
        if (this.index != other.index) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.buf, other.buf)) {
            return false;
        }
        if (this.size != other.size) {
            return false;
        }
        if (this.pass_through != other.pass_through) {
            return false;
        }
        if (this.type != other.type) {
            return false;
        }
        if (this.fmt != other.fmt) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.index), 
                android.os.HidlSupport.deepHashCode(this.buf), 
                android.os.HidlSupport.deepHashCode(this.size), 
                android.os.HidlSupport.deepHashCode(this.pass_through), 
                android.os.HidlSupport.deepHashCode(this.type), 
                android.os.HidlSupport.deepHashCode(this.fmt));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".index = ");
        builder.append(this.index);
        builder.append(", .buf = ");
        builder.append(this.buf);
        builder.append(", .size = ");
        builder.append(this.size);
        builder.append(", .pass_through = ");
        builder.append(this.pass_through);
        builder.append(", .type = ");
        builder.append(rockchip.hardware.neuralnetworks.V1_0.RKNN_TENSOR_TYPE.toString(this.type));
        builder.append(", .fmt = ");
        builder.append(rockchip.hardware.neuralnetworks.V1_0.RKNN_TENSOR_FORMAT.toString(this.fmt));
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(56 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RKNNInput> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RKNNInput> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 56,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RKNNInput _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RKNNInput();
                ((rockchip.hardware.neuralnetworks.V1_0.RKNNInput) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 56);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        index = _hidl_blob.getInt32(_hidl_offset + 0);
        ((rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer) buf).readEmbeddedFromParcel(parcel, _hidl_blob, _hidl_offset + 8);
        size = _hidl_blob.getInt32(_hidl_offset + 40);
        pass_through = _hidl_blob.getInt8(_hidl_offset + 44);
        type = _hidl_blob.getInt32(_hidl_offset + 48);
        fmt = _hidl_blob.getInt32(_hidl_offset + 52);
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(56 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RKNNInput> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 56));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 56);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putInt32(_hidl_offset + 0, index);
        buf.writeEmbeddedToBlob(_hidl_blob, _hidl_offset + 8);
        _hidl_blob.putInt32(_hidl_offset + 40, size);
        _hidl_blob.putInt8(_hidl_offset + 44, pass_through);
        _hidl_blob.putInt32(_hidl_offset + 48, type);
        _hidl_blob.putInt32(_hidl_offset + 52, fmt);
    }
};

