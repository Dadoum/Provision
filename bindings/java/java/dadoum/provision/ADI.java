package dadoum;

public class ADI {
    long handle;

    public ADI(String provisioningPath) {
        this.initialize(provisioningPath);
    }

    private native void initialize(String provisioningPath);
    public native boolean isMachineProvisioned();
    public native int provisionDevice();
    public native int getRoutingInformation();
    private native long getOneTimePasswordPtr();

    public OneTimePassword getOneTimePassword() {
        return new OneTimePassword(getOneTimePasswordPtr());
    }
}
