package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNNHWBuffer {
    public int type = 0;
    public int counter = 0;
    public int bufferID = 0;
    public int size = 0;
    public java.util.ArrayList<Long> data = new java.util.ArrayList<Long>();

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer other = (rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer)otherObject;
        if (this.type != other.type) {
            return false;
        }
        if (this.counter != other.counter) {
            return false;
        }
        if (this.bufferID != other.bufferID) {
            return false;
        }
        if (this.size != other.size) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.data, other.data)) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.type), 
                android.os.HidlSupport.deepHashCode(this.counter), 
                android.os.HidlSupport.deepHashCode(this.bufferID), 
                android.os.HidlSupport.deepHashCode(this.size), 
                android.os.HidlSupport.deepHashCode(this.data));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".type = ");
        builder.append(rockchip.hardware.neuralnetworks.V1_0.RKNN_HW_BUFFER_TYPE.toString(this.type));
        builder.append(", .counter = ");
        builder.append(this.counter);
        builder.append(", .bufferID = ");
        builder.append(this.bufferID);
        builder.append(", .size = ");
        builder.append(this.size);
        builder.append(", .data = ");
        builder.append(this.data);
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(32 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RKNNHWBuffer> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RKNNHWBuffer> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 32,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer();
                ((rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 32);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        type = _hidl_blob.getInt32(_hidl_offset + 0);
        counter = _hidl_blob.getInt32(_hidl_offset + 4);
        bufferID = _hidl_blob.getInt32(_hidl_offset + 8);
        size = _hidl_blob.getInt32(_hidl_offset + 12);
        {
            int _hidl_vec_size = _hidl_blob.getInt32(_hidl_offset + 16 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 8,_hidl_blob.handle(),
                    _hidl_offset + 16 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            ((java.util.ArrayList<Long>) data).clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                long _hidl_vec_element = 0L;
                _hidl_vec_element = childBlob.getInt64(_hidl_index_0 * 8);
                ((java.util.ArrayList<Long>) data).add(_hidl_vec_element);
            }
        }
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(32 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RKNNHWBuffer> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 32));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 32);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putInt32(_hidl_offset + 0, type);
        _hidl_blob.putInt32(_hidl_offset + 4, counter);
        _hidl_blob.putInt32(_hidl_offset + 8, bufferID);
        _hidl_blob.putInt32(_hidl_offset + 12, size);
        {
            int _hidl_vec_size = data.size();
            _hidl_blob.putInt32(_hidl_offset + 16 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(_hidl_offset + 16 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 8));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                childBlob.putInt64(_hidl_index_0 * 8, data.get(_hidl_index_0));
            }
            _hidl_blob.putBlob(_hidl_offset + 16 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }
    }
};

