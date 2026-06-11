package com.someco.action;

import org.alfresco.repo.action.executer.ActionExecuterAbstractBase;
import org.alfresco.service.cmr.action.Action;
import org.alfresco.service.cmr.repository.NodeRef;

public class SetWebFlagActionExecuter extends ActionExecuterAbstractBase {
    @Override
    protected void executeImpl(Action action, NodeRef actionedUponNodeRef) {
        // set flag
    }
    @Override
    protected void addParameterDefinitions(java.util.List p) { }
}
