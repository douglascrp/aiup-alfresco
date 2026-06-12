package com.someco.rest.model;
import org.alfresco.rest.framework.resource.UniqueId;
public class VendorContract {
    private String id;
    @UniqueId public String getId() { return id; }
    public void setId(String id) { this.id = id; }
}
