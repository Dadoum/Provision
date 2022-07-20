package dadoum;

public class ADI {
    long handle;

    public ADI(String provisioningPath) {
        this.initialize(provisioningPath);
    }

    private native void initialize(String provisioningPath);
    public native boolean isMachineProvisioned();
    public native int provisionDevice();
    private native long getOneTimePassword();
    public native int getRoutingInformation();

    public OneTimePassword getOTP() {
        var otp = new OneTimePassword();
        otp.initialize(getOneTimePassword());
        return otp;
    }
}
