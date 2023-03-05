package dadoum;

public class ADI implements java.lang.AutoCloseable {
    long handle;

    public ADI(String provisioningPath) {
        this.initialize(provisioningPath);
    }

    ~ADI() {
        this.dispose();
    }

    private native void initialize(String provisioningPath);
    private native void dispose();
    public native boolean isMachineProvisioned();
    public native int provisionDevice();
    public native int getRoutingInformation();
    private native long getOneTimePasswordPtr();

    public OneTimePassword getOneTimePassword() {
        return new OneTimePassword(getOneTimePasswordPtr());
    }
}
