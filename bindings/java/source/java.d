module java;

import arsd.jni;
static import provision;

extern(C) void Java_yeah();

final class OneTimePassword: JavaClass!("dadoum", OneTimePassword) {
    byte[] machineId;
    byte[] oneTimePassword;

    this(byte[] machineId, byte[] oneTimePassword) {
        this.machineId = machineId;
        this.oneTimePassword = oneTimePassword;
    }

    @Export byte[] getMachineId() {
        return machineId;
    }

    @Export byte[] getOneTimePassword() {
        return oneTimePassword;
    }
}

final class ADI : JavaClass!("dadoum", ADI) {
    @Import @property long handle();
    @Import @property void handle(long);

    pragma(inline, true)
    provision.ADI* hndl() {
        return cast(provision.ADI*) handle;
    }

    @Export void initialize(string provisioningPath) {
        handle = cast(long) new provision.ADI(provisioningPath);
    }

    @Export bool isMachineProvisioned() {
        return hndl.isMachineProvisioned();
    }

    @Export ulong provisionDevice() {
        ulong rinfo;
        hndl.provisionDevice(rinfo);
        return rinfo;
    }

    @Export OneTimePassword getOneTimePassword() {
        ubyte[] machineId, oneTimePassword;
        hndl.getOneTimePassword(machineId, oneTimePassword);
        return new OneTimePassword(cast(byte[]) machineId, cast(byte[]) oneTimePassword);
    }

    @Export ulong getRoutingInformation() {
        ulong rinfo;
        hndl.getRoutingInformation(rinfo);
        return rinfo;
    }
}

version(Windows) {
    import core.sys.windows.dll;
    mixin SimpleDllMain;
}
