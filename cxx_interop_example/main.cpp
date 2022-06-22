//
// Created by dadoum on 22/06/2022.
//
#include <cstdio>
#include "provision.h"

int main(int argc, char**argv) {
    ADI* adi = provision_adi_create("./adi");

    uint64_t routingInformation;
    provision_adi_provision_device(adi, &routingInformation);

    printf("%lu", routingInformation);

    provision_adi_dispose(adi);
}
