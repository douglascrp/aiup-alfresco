package com.someco.content;
import org.alfresco.repo.content.AbstractContentReader;
import org.alfresco.service.cmr.repository.ContentReader;
import java.nio.channels.ReadableByteChannel;
public class TieredContentReader extends AbstractContentReader {
    private final String rootLocation;
    protected TieredContentReader(String url, String root) { super(url); this.rootLocation = root; }
    @Override public boolean exists() { return false; }
    @Override public long getLastModified() { return 0L; }
    @Override public long getSize() { return 0L; }
    @Override protected ContentReader createReader() { return new TieredContentReader(getContentUrl(), rootLocation); }
    @Override protected ReadableByteChannel getDirectReadableChannel() { throw new UnsupportedOperationException(); }
}
