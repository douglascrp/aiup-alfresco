package com.someco.rest;
import org.alfresco.rest.framework.WebApiDescription;
import org.alfresco.rest.framework.resource.RelationshipResource;
import org.alfresco.rest.framework.resource.actions.interfaces.RelationshipResourceAction;
import org.alfresco.rest.framework.resource.parameters.CollectionWithPagingInfo;
import org.alfresco.rest.framework.resource.parameters.Parameters;
import com.someco.rest.model.VendorContract;

@RelationshipResource(name = "payments", entityResource = VendorContractEntityResource.class, title = "Payments")
public class VendorContractPaymentsRelationshipResource implements RelationshipResourceAction.Read<VendorContract> {
    @Override
    @WebApiDescription(title = "List payments")
    public CollectionWithPagingInfo<VendorContract> readAll(String entityResourceId, Parameters parameters) {
        return CollectionWithPagingInfo.asPaged(parameters.getPaging(), java.util.List.of());
    }
}
