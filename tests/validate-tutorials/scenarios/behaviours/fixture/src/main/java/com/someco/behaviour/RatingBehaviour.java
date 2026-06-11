package com.someco.behaviour;

import org.alfresco.repo.node.NodeServicePolicies.OnCreateNodePolicy;
import org.alfresco.repo.policy.JavaBehaviour;
import org.alfresco.repo.policy.PolicyComponent;
import org.alfresco.service.cmr.repository.ChildAssociationRef;

public class RatingBehaviour implements OnCreateNodePolicy {
    private PolicyComponent policyComponent;
    public void init() {
        policyComponent.bindClassBehaviour(
            OnCreateNodePolicy.QNAME,
            com.someco.model.SomeCoModel.TYPE_DOC,
            new JavaBehaviour(this, "onCreateNode"));
    }
    @Override
    public void onCreateNode(ChildAssociationRef ref) { }
    public void setPolicyComponent(PolicyComponent pc) { this.policyComponent = pc; }
}
