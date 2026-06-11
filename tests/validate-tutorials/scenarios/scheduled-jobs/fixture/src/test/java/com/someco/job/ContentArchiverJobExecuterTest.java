package com.someco.job;
import org.alfresco.repo.transaction.RetryingTransactionHelper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
@ExtendWith(MockitoExtension.class)
class ContentArchiverJobExecuterTest {
    @Mock RetryingTransactionHelper retryingTransactionHelper;
    @Test void runs() { }
}
