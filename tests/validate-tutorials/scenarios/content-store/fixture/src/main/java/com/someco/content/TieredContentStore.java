package com.someco.content;
import org.alfresco.repo.content.AbstractContentStore;
import org.alfresco.service.cmr.repository.ContentReader;
import org.alfresco.service.cmr.repository.ContentWriter;
public class TieredContentStore extends AbstractContentStore {
    private String rootLocation;
    @Override public boolean isWriteSupported() { return true; }
    @Override public ContentReader getReader(String contentUrl) { return new TieredContentReader(contentUrl, rootLocation); }
    @Override public ContentWriter getWriterInternal(ContentReader existing, String newUrl) { return new TieredContentWriter(newUrl, rootLocation, existing); }
    @Override public String getRootLocation() { return rootLocation; }
    public void setRootLocation(String r) { this.rootLocation = r; }
}
