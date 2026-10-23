package rockchip.hardware.neuralnetworks.V1_0;


public final class RKNNTensorAttr {
    public int index = 0;
    /*
     * input parameter, the index of input/output tensor,
     * need set before call rknn_query.
     */
    public int n_dims = 0;
    /*
     * the number of dimensions.
     */
    public int[/* 16 */] dims = new int[16];
    /*
     * the dimensions array.
     */
    public String name = new String();
    /*
     * the name of tensor.
     */
    public int n_elems = 0;
    /*
     * the number of elements.
     */
    public int size = 0;
    /*
     * the bytes size of tensor.
     */
    public int fmt = 0;
    /*
     * the data format of tensor.
     */
    public int type = 0;
    /*
     * the data type of tensor.
     */
    public int qnt_type = 0;
    /*
     * the quantitative type of tensor.
     */
    public byte fl = 0;
    /*
     * fractional length for RKNN_TENSOR_QNT_DFP.
     */
    public int zp = 0;
    /*
     * zero point for RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC.
     */
    public float scale = 0.0f;

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RKNNTensorAttr.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RKNNTensorAttr other = (rockchip.hardware.neuralnetworks.V1_0.RKNNTensorAttr)otherObject;
        if (this.index != other.index) {
            return false;
        }
        if (this.n_dims != other.n_dims) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.dims, other.dims)) {
            return false;
        }
        if (!android.os.HidlSupport.deepEquals(this.name, other.name)) {
            return false;
        }
        if (this.n_elems != other.n_elems) {
            return false;
        }
        if (this.size != other.size) {
            return false;
        }
        if (this.fmt != other.fmt) {
            return false;
        }
        if (this.type != other.type) {
            return false;
        }
        if (this.qnt_type != other.qnt_type) {
            return false;
        }
        if (this.fl != other.fl) {
            return false;
        }
        if (this.zp != other.zp) {
            return false;
        }
        if (this.scale != other.scale) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.index), 
                android.os.HidlSupport.deepHashCode(this.n_dims), 
                android.os.HidlSupport.deepHashCode(this.dims), 
                android.os.HidlSupport.deepHashCode(this.name), 
                android.os.HidlSupport.deepHashCode(this.n_elems), 
                android.os.HidlSupport.deepHashCode(this.size), 
                android.os.HidlSupport.deepHashCode(this.fmt), 
                android.os.HidlSupport.deepHashCode(this.type), 
                android.os.HidlSupport.deepHashCode(this.qnt_type), 
                android.os.HidlSupport.deepHashCode(this.fl), 
                android.os.HidlSupport.deepHashCode(this.zp), 
                android.os.HidlSupport.deepHashCode(this.scale));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".index = ");
        builder.append(this.index);
        builder.append(", .n_dims = ");
        builder.append(this.n_dims);
        builder.append(", .dims = ");
        builder.append(java.util.Arrays.toString(this.dims));
        builder.append(", .name = ");
        builder.append(this.name);
        builder.append(", .n_elems = ");
        builder.append(this.n_elems);
        builder.append(", .size = ");
        builder.append(this.size);
        builder.append(", .fmt = ");
        builder.append(rockchip.hardware.neuralnetworks.V1_0.RKNN_TENSOR_FORMAT.toString(this.fmt));
        builder.append(", .type = ");
        builder.append(rockchip.hardware.neuralnetworks.V1_0.RKNN_TENSOR_TYPE.toString(this.type));
        builder.append(", .qnt_type = ");
        builder.append(rockchip.hardware.neuralnetworks.V1_0.RKNN_TENSOR_QNT_TYPE.toString(this.qnt_type));
        builder.append(", .fl = ");
        builder.append(this.fl);
        builder.append(", .zp = ");
        builder.append(this.zp);
        builder.append(", .scale = ");
        builder.append(this.scale);
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(120 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RKNNTensorAttr> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RKNNTensorAttr> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 120,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RKNNTensorAttr _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RKNNTensorAttr();
                ((rockchip.hardware.neuralnetworks.V1_0.RKNNTensorAttr) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 120);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        index = _hidl_blob.getInt32(_hidl_offset + 0);
        n_dims = _hidl_blob.getInt32(_hidl_offset + 4);
        {
            long _hidl_array_offset_0 = _hidl_offset + 8;
            _hidl_blob.copyToInt32Array(_hidl_array_offset_0, (int[/* 16 */]) dims, 16 /* size */);
            _hidl_array_offset_0 += 16 * 4;
        }
        name = _hidl_blob.getString(_hidl_offset + 72);

        parcel.readEmbeddedBuffer(
                ((String) name).getBytes().length + 1,
                _hidl_blob.handle(),
                _hidl_offset + 72 + 0 /* offsetof(hidl_string, mBuffer) */,false /* nullable */);

        n_elems = _hidl_blob.getInt32(_hidl_offset + 88);
        size = _hidl_blob.getInt32(_hidl_offset + 92);
        fmt = _hidl_blob.getInt32(_hidl_offset + 96);
        type = _hidl_blob.getInt32(_hidl_offset + 100);
        qnt_type = _hidl_blob.getInt32(_hidl_offset + 104);
        fl = _hidl_blob.getInt8(_hidl_offset + 108);
        zp = _hidl_blob.getInt32(_hidl_offset + 112);
        scale = _hidl_blob.getFloat(_hidl_offset + 116);
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(120 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RKNNTensorAttr> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 120));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 120);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putInt32(_hidl_offset + 0, index);
        _hidl_blob.putInt32(_hidl_offset + 4, n_dims);
        {
            long _hidl_array_offset_0 = _hidl_offset + 8;
            int[] _hidl_array_item_0 = (int[/* 16 */]) dims;

            if (_hidl_array_item_0 == null || _hidl_array_item_0.length != 16) {
                throw new IllegalArgumentException("Array element is not of the expected length");
            }

            _hidl_blob.putInt32Array(_hidl_array_offset_0, _hidl_array_item_0);
            _hidl_array_offset_0 += 16 * 4;
        }
        _hidl_blob.putString(_hidl_offset + 72, name);
        _hidl_blob.putInt32(_hidl_offset + 88, n_elems);
        _hidl_blob.putInt32(_hidl_offset + 92, size);
        _hidl_blob.putInt32(_hidl_offset + 96, fmt);
        _hidl_blob.putInt32(_hidl_offset + 100, type);
        _hidl_blob.putInt32(_hidl_offset + 104, qnt_type);
        _hidl_blob.putInt8(_hidl_offset + 108, fl);
        _hidl_blob.putInt32(_hidl_offset + 112, zp);
        _hidl_blob.putFloat(_hidl_offset + 116, scale);
    }
};

