package dadoum;

public class OneTimePassword {
    private byte[] machineId;
    private byte[] oneTimePassword;

    protected native void initialize(long otpPtr);

    public byte[] getOneTimePassword() {
        return oneTimePassword;
    }

    public byte[] getMachineId() {
        return machineId;
    }
}
