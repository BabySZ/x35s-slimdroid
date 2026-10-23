package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNNModel {
    public String name = new String();
    public String path = new String();
    public rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer modelData = new rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer();

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RKNNModel.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RKNNModel other = (rockchip.hardware.neuralnetworks.V1_0.RKNNModel)otherObject;
        if (!android.os.HidlSupport.deepEquals(this.name, other.name)) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.path, other.path)) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.modelData, other.modelData)) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.name), 
                android.os.HidlSupport.deepHashCode(this.path), 
                android.os.HidlSupport.deepHashCode(this.modelData));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".name = ");
        builder.append(this.name);
        builder.append(", .path = ");
        builder.append(this.path);
        builder.append(", .modelData = ");
        builder.append(this.modelData);
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(64 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RKNNModel> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RKNNModel> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 64,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RKNNModel _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RKNNModel();
                ((rockchip.hardware.neuralnetworks.V1_0.RKNNModel) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 64);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        name = _hidl_blob.getString(_hidl_offset + 0);

        parcel.readEmbeddedBuffer(
                ((String) name).getBytes().length + 1,
                _hidl_blob.handle(),
                _hidl_offset + 0 + 0 /* offsetof(hidl_string, mBuffer) */,false /* nullable */);

        path = _hidl_blob.getString(_hidl_offset + 16);

        parcel.readEmbeddedBuffer(
                ((String) path).getBytes().length + 1,
                _hidl_blob.handle(),
                _hidl_offset + 16 + 0 /* offsetof(hidl_string, mBuffer) */,false /* nullable */);

        ((rockchip.hardware.neuralnetworks.V1_0.RKNNHWBuffer) modelData).readEmbeddedFromParcel(parcel, _hidl_blob, _hidl_offset + 32);
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(64 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RKNNModel> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 64));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 64);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putString(_hidl_offset + 0, name);
        _hidl_blob.putString(_hidl_offset + 16, path);
        modelData.writeEmbeddedToBlob(_hidl_blob, _hidl_offset + 32);
    }
};

