package com.someco.job;
import org.alfresco.schedule.AbstractScheduledLockedJob;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
public class ContentArchiverJob extends AbstractScheduledLockedJob {
    private ContentArchiverJobExecuter executer;
    @Override public void executeJob(JobExecutionContext c) throws JobExecutionException { executer.execute(); }
    public void setExecuter(ContentArchiverJobExecuter e) { this.executer = e; }
}
