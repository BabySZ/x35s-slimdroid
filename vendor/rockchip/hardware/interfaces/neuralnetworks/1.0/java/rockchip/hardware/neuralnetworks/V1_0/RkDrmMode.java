package rockchip.hardware.neuralnetworks.V1_0;


public final class RkDrmMode {
    public int width = 0;
    public int height = 0;
    public float refreshRate = 0.0f;
    public int clock = 0;
    public int flags = 0;
    public int interlaceFlag = 0;
    public int yuvFlag = 0;
    public int connectorId = 0;
    public int mode_type = 0;
    public int idx = 0;
    public int hsync_start = 0;
    public int hsync_end = 0;
    public int htotal = 0;
    public int hskew = 0;
    public int vsync_start = 0;
    public int vsync_end = 0;
    public int vtotal = 0;
    public int vscan = 0;

    @Override
    public final boolean equals(Object otherObject) {
        if (this == otherObject) {
            return true;
        }
        if (otherObject == null) {
            return false;
        }
        if (otherObject.getClass() != rockchip.hardware.neuralnetworks.V1_0.RkDrmMode.class) {
            return false;
        }
        rockchip.hardware.neuralnetworks.V1_0.RkDrmMode other = (rockchip.hardware.neuralnetworks.V1_0.RkDrmMode)otherObject;
        if (this.width != other.width) {
            return false;
        }
        if (this.height != other.height) {
            return false;
        }
        if (this.refreshRate != other.refreshRate) {
            return false;
        }
        if (this.clock != other.clock) {
            return false;
        }
        if (this.flags != other.flags) {
            return false;
        }
        if (this.interlaceFlag != other.interlaceFlag) {
            return false;
        }
        if (this.yuvFlag != other.yuvFlag) {
            return false;
        }
        if (this.connectorId != other.connectorId) {
            return false;
        }
        if (this.mode_type != other.mode_type) {
            return false;
        }
        if (this.idx != other.idx) {
            return false;
        }
        if (this.hsync_start != other.hsync_start) {
            return false;
        }
        if (this.hsync_end != other.hsync_end) {
            return false;
        }
        if (this.htotal != other.htotal) {
            return false;
        }
        if (this.hskew != other.hskew) {
            return false;
        }
        if (this.vsync_start != other.vsync_start) {
            return false;
        }
        if (this.vsync_end != other.vsync_end) {
            return false;
        }
        if (this.vtotal != other.vtotal) {
            return false;
        }
        if (this.vscan != other.vscan) {
            return false;
        }
        return true;
    }

    @Override
    public final int hashCode() {
        return java.util.Objects.hash(
                android.os.HidlSupport.deepHashCode(this.width), 
                android.os.HidlSupport.deepHashCode(this.height), 
                android.os.HidlSupport.deepHashCode(this.refreshRate), 
                android.os.HidlSupport.deepHashCode(this.clock), 
                android.os.HidlSupport.deepHashCode(this.flags), 
                android.os.HidlSupport.deepHashCode(this.interlaceFlag), 
                android.os.HidlSupport.deepHashCode(this.yuvFlag), 
                android.os.HidlSupport.deepHashCode(this.connectorId), 
                android.os.HidlSupport.deepHashCode(this.mode_type), 
                android.os.HidlSupport.deepHashCode(this.idx), 
                android.os.HidlSupport.deepHashCode(this.hsync_start), 
                android.os.HidlSupport.deepHashCode(this.hsync_end), 
                android.os.HidlSupport.deepHashCode(this.htotal), 
                android.os.HidlSupport.deepHashCode(this.hskew), 
                android.os.HidlSupport.deepHashCode(this.vsync_start), 
                android.os.HidlSupport.deepHashCode(this.vsync_end), 
                android.os.HidlSupport.deepHashCode(this.vtotal), 
                android.os.HidlSupport.deepHashCode(this.vscan));
    }

    @Override
    public final String toString() {
        java.lang.StringBuilder builder = new java.lang.StringBuilder();
        builder.append("{");
        builder.append(".width = ");
        builder.append(this.width);
        builder.append(", .height = ");
        builder.append(this.height);
        builder.append(", .refreshRate = ");
        builder.append(this.refreshRate);
        builder.append(", .clock = ");
        builder.append(this.clock);
        builder.append(", .flags = ");
        builder.append(this.flags);
        builder.append(", .interlaceFlag = ");
        builder.append(this.interlaceFlag);
        builder.append(", .yuvFlag = ");
        builder.append(this.yuvFlag);
        builder.append(", .connectorId = ");
        builder.append(this.connectorId);
        builder.append(", .mode_type = ");
        builder.append(this.mode_type);
        builder.append(", .idx = ");
        builder.append(this.idx);
        builder.append(", .hsync_start = ");
        builder.append(this.hsync_start);
        builder.append(", .hsync_end = ");
        builder.append(this.hsync_end);
        builder.append(", .htotal = ");
        builder.append(this.htotal);
        builder.append(", .hskew = ");
        builder.append(this.hskew);
        builder.append(", .vsync_start = ");
        builder.append(this.vsync_start);
        builder.append(", .vsync_end = ");
        builder.append(this.vsync_end);
        builder.append(", .vtotal = ");
        builder.append(this.vtotal);
        builder.append(", .vscan = ");
        builder.append(this.vscan);
        builder.append("}");
        return builder.toString();
    }

    public final void readFromParcel(android.os.HwParcel parcel) {
        android.os.HwBlob blob = parcel.readBuffer(72 /* size */);
        readEmbeddedFromParcel(parcel, blob, 0 /* parentOffset */);
    }

    public static final java.util.ArrayList<RkDrmMode> readVectorFromParcel(android.os.HwParcel parcel) {
        java.util.ArrayList<RkDrmMode> _hidl_vec = new java.util.ArrayList();
        android.os.HwBlob _hidl_blob = parcel.readBuffer(16 /* sizeof hidl_vec<T> */);

        {
            int _hidl_vec_size = _hidl_blob.getInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */);
            android.os.HwBlob childBlob = parcel.readEmbeddedBuffer(
                    _hidl_vec_size * 72,_hidl_blob.handle(),
                    0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */,true /* nullable */);

            _hidl_vec.clear();
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                rockchip.hardware.neuralnetworks.V1_0.RkDrmMode _hidl_vec_element = new rockchip.hardware.neuralnetworks.V1_0.RkDrmMode();
                ((rockchip.hardware.neuralnetworks.V1_0.RkDrmMode) _hidl_vec_element).readEmbeddedFromParcel(parcel, childBlob, _hidl_index_0 * 72);
                _hidl_vec.add(_hidl_vec_element);
            }
        }

        return _hidl_vec;
    }

    public final void readEmbeddedFromParcel(
            android.os.HwParcel parcel, android.os.HwBlob _hidl_blob, long _hidl_offset) {
        width = _hidl_blob.getInt32(_hidl_offset + 0);
        height = _hidl_blob.getInt32(_hidl_offset + 4);
        refreshRate = _hidl_blob.getFloat(_hidl_offset + 8);
        clock = _hidl_blob.getInt32(_hidl_offset + 12);
        flags = _hidl_blob.getInt32(_hidl_offset + 16);
        interlaceFlag = _hidl_blob.getInt32(_hidl_offset + 20);
        yuvFlag = _hidl_blob.getInt32(_hidl_offset + 24);
        connectorId = _hidl_blob.getInt32(_hidl_offset + 28);
        mode_type = _hidl_blob.getInt32(_hidl_offset + 32);
        idx = _hidl_blob.getInt32(_hidl_offset + 36);
        hsync_start = _hidl_blob.getInt32(_hidl_offset + 40);
        hsync_end = _hidl_blob.getInt32(_hidl_offset + 44);
        htotal = _hidl_blob.getInt32(_hidl_offset + 48);
        hskew = _hidl_blob.getInt32(_hidl_offset + 52);
        vsync_start = _hidl_blob.getInt32(_hidl_offset + 56);
        vsync_end = _hidl_blob.getInt32(_hidl_offset + 60);
        vtotal = _hidl_blob.getInt32(_hidl_offset + 64);
        vscan = _hidl_blob.getInt32(_hidl_offset + 68);
    }

    public final void writeToParcel(android.os.HwParcel parcel) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(72 /* size */);
        writeEmbeddedToBlob(_hidl_blob, 0 /* parentOffset */);
        parcel.writeBuffer(_hidl_blob);
    }

    public static final void writeVectorToParcel(
            android.os.HwParcel parcel, java.util.ArrayList<RkDrmMode> _hidl_vec) {
        android.os.HwBlob _hidl_blob = new android.os.HwBlob(16 /* sizeof(hidl_vec<T>) */);
        {
            int _hidl_vec_size = _hidl_vec.size();
            _hidl_blob.putInt32(0 + 8 /* offsetof(hidl_vec<T>, mSize) */, _hidl_vec_size);
            _hidl_blob.putBool(0 + 12 /* offsetof(hidl_vec<T>, mOwnsBuffer) */, false);
            android.os.HwBlob childBlob = new android.os.HwBlob((int)(_hidl_vec_size * 72));
            for (int _hidl_index_0 = 0; _hidl_index_0 < _hidl_vec_size; ++_hidl_index_0) {
                _hidl_vec.get(_hidl_index_0).writeEmbeddedToBlob(childBlob, _hidl_index_0 * 72);
            }
            _hidl_blob.putBlob(0 + 0 /* offsetof(hidl_vec<T>, mBuffer) */, childBlob);
        }

        parcel.writeBuffer(_hidl_blob);
    }

    public final void writeEmbeddedToBlob(
            android.os.HwBlob _hidl_blob, long _hidl_offset) {
        _hidl_blob.putInt32(_hidl_offset + 0, width);
        _hidl_blob.putInt32(_hidl_offset + 4, height);
        _hidl_blob.putFloat(_hidl_offset + 8, refreshRate);
        _hidl_blob.putInt32(_hidl_offset + 12, clock);
        _hidl_blob.putInt32(_hidl_offset + 16, flags);
        _hidl_blob.putInt32(_hidl_offset + 20, interlaceFlag);
        _hidl_blob.putInt32(_hidl_offset + 24, yuvFlag);
        _hidl_blob.putInt32(_hidl_offset + 28, connectorId);
        _hidl_blob.putInt32(_hidl_offset + 32, mode_type);
        _hidl_blob.putInt32(_hidl_offset + 36, idx);
        _hidl_blob.putInt32(_hidl_offset + 40, hsync_start);
        _hidl_blob.putInt32(_hidl_offset + 44, hsync_end);
        _hidl_blob.putInt32(_hidl_offset + 48, htotal);
        _hidl_blob.putInt32(_hidl_offset + 52, hskew);
        _hidl_blob.putInt32(_hidl_offset + 56, vsync_start);
        _hidl_blob.putInt32(_hidl_offset + 60, vsync_end);
        _hidl_blob.putInt32(_hidl_offset + 64, vtotal);
        _hidl_blob.putInt32(_hidl_offset + 68, vscan);
    }
};

