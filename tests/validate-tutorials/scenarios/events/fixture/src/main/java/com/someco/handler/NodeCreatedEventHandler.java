/*
 * Copyright 2026 SomeCo. Licensed under the Apache License, Version 2.0.
 */
package com.someco.handler;
import org.alfresco.event.sdk.handling.handler.AlfrescoEventListener;
import org.alfresco.event.sdk.handling.handler.OnNodeCreatedEventHandler;
import org.alfresco.repo.event.v1.model.RepoEvent;
import org.alfresco.repo.event.v1.model.DataAttributes;
import org.alfresco.repo.event.v1.model.Resource;
import org.springframework.stereotype.Component;

@Component
@AlfrescoEventListener
public class NodeCreatedEventHandler implements OnNodeCreatedEventHandler {
    @Override
    public void handleEvent(RepoEvent<DataAttributes<Resource>> event) {
        // log node type + id at INFO
    }
}
