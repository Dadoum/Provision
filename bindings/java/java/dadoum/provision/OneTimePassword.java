package dadoum;

public class OneTimePassword implements java.lang.AutoCloseable {
    private byte[] machineId;
    private byte[] oneTimePassword;

    private native void initialize(long otpPtr);

    protected OneTimePassword(long otpPtr) {
        initialize(otpPtr);
    }

    ~OneTimePassword() {
        dispose();
    }

    public byte[] getOneTimePassword() {
        return oneTimePassword;
    }

    public byte[] getMachineId() {
        return machineId;
    }
}
