package com.someco.patch;
import org.alfresco.repo.admin.patch.AbstractPatch;
import org.alfresco.service.cmr.search.ResultSet;
import org.alfresco.service.cmr.search.SearchParameters;
import org.alfresco.service.cmr.search.SearchService;
public class ActiveFlagPatch extends AbstractPatch {
    @Override
    protected String applyInternal() throws Exception {
        ResultSet results = null;
        try {
            SearchParameters sp = new SearchParameters();
            sp.setLanguage(SearchService.LANGUAGE_FTS_ALFRESCO);
            results = searchService.query(sp);
        } finally {
            if (results != null) results.close();
        }
        return "Patched legacy docs";
    }
}
