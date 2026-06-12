package com.someco.audit.extractor;
import org.alfresco.repo.audit.extractor.AbstractDataExtractor;
import java.io.Serializable;
public class ClassificationDataExtractor extends AbstractDataExtractor {
    @Override public boolean isSupported(Serializable data) { return data != null; }
    @Override public Serializable extractData(Serializable in) { return in; }
}
