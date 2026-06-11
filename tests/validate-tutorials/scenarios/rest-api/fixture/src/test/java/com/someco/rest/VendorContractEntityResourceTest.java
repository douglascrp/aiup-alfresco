package com.someco.rest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;
@ExtendWith(MockitoExtension.class)
class VendorContractEntityResourceTest {
    @Test void readAll_returnsPaged() { new VendorContractEntityResource().readAll(null); }
}
