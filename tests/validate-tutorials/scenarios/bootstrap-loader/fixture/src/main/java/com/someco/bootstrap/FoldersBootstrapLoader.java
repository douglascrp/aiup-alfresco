package com.someco.bootstrap;
import org.alfresco.repo.module.AbstractModuleComponent;
import org.alfresco.repo.nodelocator.NodeLocatorService;
public class FoldersBootstrapLoader extends AbstractModuleComponent {
    private NodeLocatorService nodeLocatorService;
    @Override protected void executeInternal() {
        nodeLocatorService.getNode("companyhome", null, null);
    }
    public void setNodeLocatorService(NodeLocatorService s) { this.nodeLocatorService = s; }
}
