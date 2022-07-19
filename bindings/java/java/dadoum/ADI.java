package dadoum;

public class ADI {
    public native void initialize(String provisioningPath);
    public native boolean isMachineProvisioned();
    public native int provisionDevice();
    public native OneTimePassword getOneTimePassword();
    public native int getRoutingInformation();
}
