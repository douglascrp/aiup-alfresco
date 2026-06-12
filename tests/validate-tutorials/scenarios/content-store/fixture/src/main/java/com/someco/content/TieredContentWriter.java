package com.someco.content;
import org.alfresco.repo.content.AbstractContentWriter;
import org.alfresco.service.cmr.repository.ContentReader;
import java.nio.channels.WritableByteChannel;
public class TieredContentWriter extends AbstractContentWriter {
    private final String rootLocation;
    protected TieredContentWriter(String url, String root, ContentReader existing) { super(url, existing); this.rootLocation = root; }
    @Override public long getSize() { return 0L; }
    @Override protected ContentReader createReader() { return new TieredContentReader(getContentUrl(), rootLocation); }
    @Override protected WritableByteChannel getDirectWritableChannel() { throw new UnsupportedOperationException(); }
}
