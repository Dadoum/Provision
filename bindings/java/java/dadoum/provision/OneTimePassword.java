package dadoum;

public class OneTimePassword {
    private byte[] machineId;
    private byte[] oneTimePassword;

    private native void initialize(long otpPtr);

    protected OneTimePassword(long otpPtr) {
        initialize(otpPtr);
    }

    public byte[] getOneTimePassword() {
        return oneTimePassword;
    }

    public byte[] getMachineId() {
        return machineId;
    }
}
