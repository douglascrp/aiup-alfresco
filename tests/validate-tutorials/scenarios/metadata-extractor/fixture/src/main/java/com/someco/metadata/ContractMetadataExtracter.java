package com.someco.metadata;
import org.alfresco.repo.content.metadata.AbstractMappingMetadataExtracter;
import org.alfresco.service.cmr.repository.ContentReader;
import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
public class ContractMetadataExtracter extends AbstractMappingMetadataExtracter {
    public ContractMetadataExtracter() { super(Set.of("application/x-someco-contract")); }
    @Override protected Map<String, Serializable> extractRaw(ContentReader reader) {
        return new HashMap<>();
    }
}
