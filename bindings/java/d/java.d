module java;

version (DigitalMars) { } else version (LDC) { } else {
    static assert(false, "This library can only work with DMD or LDC (yet)");
}

import arsd.jni;
import core.stdc.stdlib;
static import provision;

final class OneTimePassword: JavaClass!("dadoum", OneTimePassword) {
    @Import @property void machineId(byte[]);
    @Import @property void oneTimePassword(byte[]);

    @Export void initialize(long otpPtr) {
        Fields* fields = cast(Fields*) otpPtr;
        this.machineId(cast(byte[]) fields.machineId);
        this.oneTimePassword(cast(byte[]) fields.oneTimePassword);
        free(fields);
    }
}

struct Fields {
    ubyte[] machineId;
    ubyte[] oneTimePassword;
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

    @Export long getOneTimePasswordPtr() {
        ubyte[] machineId, oneTimePassword;
        hndl.getOneTimePassword(machineId, oneTimePassword);

        Fields* fields = cast(Fields*) malloc(Fields.sizeof);
        fields.machineId = machineId;
        fields.oneTimePassword = oneTimePassword;

        return cast(long) fields;
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
