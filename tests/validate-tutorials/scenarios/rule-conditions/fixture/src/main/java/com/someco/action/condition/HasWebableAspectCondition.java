package com.someco.action.condition;
import org.alfresco.repo.action.evaluator.ActionConditionEvaluatorAbstractBase;
import org.alfresco.service.cmr.action.ActionCondition;
import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
public class HasWebableAspectCondition extends ActionConditionEvaluatorAbstractBase {
    public static final String NAME = "sc-has-webable-aspect";
    private NodeService nodeService;
    @Override
    protected boolean evaluateImpl(ActionCondition c, NodeRef n) {
        return nodeService.exists(n);
    }
    public void setNodeService(NodeService s) { this.nodeService = s; }
}
