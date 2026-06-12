package com.someco.rest;
import org.alfresco.rest.framework.WebApiDescription;
import org.alfresco.rest.framework.resource.EntityResource;
import org.alfresco.rest.framework.resource.actions.interfaces.EntityResourceAction;
import org.alfresco.rest.framework.resource.parameters.CollectionWithPagingInfo;
import org.alfresco.rest.framework.resource.parameters.Parameters;
import com.someco.rest.model.VendorContract;

@EntityResource(name = "vendor-contracts", title = "Vendor Contract API")
public class VendorContractEntityResource implements EntityResourceAction.Read<VendorContract> {
    @Override
    @WebApiDescription(title = "List vendor-contracts")
    public CollectionWithPagingInfo<VendorContract> readAll(Parameters parameters) {
        return CollectionWithPagingInfo.asPaged(parameters.getPaging(), java.util.List.of());
    }
}
