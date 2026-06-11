package com.someco.job;
import org.alfresco.repo.transaction.RetryingTransactionHelper;
public class ContentArchiverJobExecuter {
    private RetryingTransactionHelper retryingTransactionHelper;
    public void execute() {
        retryingTransactionHelper.doInTransaction(() -> null, false, true);
    }
    public void setRetryingTransactionHelper(RetryingTransactionHelper h) { this.retryingTransactionHelper = h; }
}
