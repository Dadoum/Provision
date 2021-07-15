module provision.android.protocoldialog;

import provision.glue;
import provision.android.requestcontext;
import provision.androidclass;

@AndroidClassInfo(Library.LIBSTORESERVICESCORE, 392) class ProtocolDialog : AndroidClass {
    mixin implementDefaultConstructor;
    mixin implementDestructor!"_ZN17storeservicescore14ProtocolDialogD2Ev";
    mixin implementConstructor!(void function(), "_ZN17storeservicescore14ProtocolDialogC2Ev");
    /+
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore14ProtocolDialog10setButtonsERKNSt6__ndk16vectorINS1_10shared_ptrINS_14ProtocolButtonEEENS1_9allocatorIS5_EEEE");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore14ProtocolDialog10setMessageERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialog10setMetricsERKNSt6__ndk110shared_ptrINS_21ProtocolDialogMetricsEEE");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialog11setMetadataERN13mediaplatform17CFRetainedPointerIP14__CFDictionaryEE");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialog13setDialogKindENS0_10DialogKindE");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore14ProtocolDialog13setTextFieldsERKNSt6__ndk16vectorINS1_10shared_ptrINS_17ProtocolTextFieldEEENS1_9allocatorIS5_EEEE");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialog14setButtonStyleENS0_11ButtonStyleE");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialog14setFailureTypeEx");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialog15setButtonTitlesEPKcz");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialog32setAllowsBiometricAuthenticationEb");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore14ProtocolDialog8setTitleERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialogC1EPK14__CFDictionary");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore14ProtocolDialogC1Ev");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore14ProtocolDialogC2EPK14__CFDictionary");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore14ProtocolDialogC2Ev");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore14ProtocolDialogD2Ev");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore21ProtocolDialogMetricsC1EPK14__CFDictionary");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore21ProtocolDialogMetricsC1Ev");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore21ProtocolDialogMetricsC2EPK14__CFDictionary");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore21ProtocolDialogMetricsC2Ev");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore21ProtocolDialogMetricsD2Ev");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore22ProtocolDialogResponse17setSelectedButtonERKNSt6__ndk110shared_ptrINS_14ProtocolButtonEEE");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore22ProtocolDialogResponse17setTextFieldValueERKNSt6__ndk110shared_ptrINS_17ProtocolTextFieldEEERKNS1_12basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    mixin implementMethod!(void function(), "", "_ZN17storeservicescore22ProtocolDialogResponse17valueForTextFieldERKNSt6__ndk110shared_ptrINS_17ProtocolTextFieldEEE");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore22ProtocolDialogResponse31setPerformsDefaultButtonActionsEb");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore22ProtocolDialogResponseC1Ev");
    mixin implementMethod!(void function(), "",
            "_ZN17storeservicescore22ProtocolDialogResponseC2Ev");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog10dialogKindEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog10textFieldsEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog11buttonStyleEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog11failureTypeEv");
    mixin implementMethod!(void function(), "", "_ZNK17storeservicescore14ProtocolDialog25firstButtonWithActionTypeERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog29allowsBiometricAuthenticationEv");
    mixin implementMethod!(void function(), "", "_ZNK17storeservicescore14ProtocolDialog5titleEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog7buttonsEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog7messageEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog7metricsEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore14ProtocolDialog8metadataEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore21ProtocolDialogMetrics11messageCodeEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore21ProtocolDialogMetrics7messageEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore21ProtocolDialogMetrics7optionsEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore21ProtocolDialogMetrics8dialogIdEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore21ProtocolDialogMetrics9actionUrlEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore22ProtocolDialogResponse14selectedButtonEv");
    mixin implementMethod!(void function(), "",
            "_ZNK17storeservicescore22ProtocolDialogResponse28performsDefaultButtonActionsEv");+/
}
