package com.someco.patch;
import org.alfresco.service.cmr.search.ResultSet;
import org.alfresco.service.cmr.search.SearchService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
@ExtendWith(MockitoExtension.class)
class ActiveFlagPatchTest {
    @Mock SearchService searchService;
    @Mock ResultSet resultSet;
    @Test void applyInternal_runs() { }
}
