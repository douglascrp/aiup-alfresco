package com.someco.security;
import org.alfresco.repo.security.permissions.DynamicAuthority;
import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
import java.util.Set;
public class ReviewerDynamicAuthority implements DynamicAuthority {
    public static final String AUTHORITY = "sc_reviewer";
    private NodeService nodeService;
    @Override public boolean hasAuthority(NodeRef nodeRef, String userName) {
        return nodeService.exists(nodeRef);
    }
    @Override public String getAuthority() { return AUTHORITY; }
    @Override public Set requiredFor() { return null; }
    public void setNodeService(NodeService s) { this.nodeService = s; }
}
