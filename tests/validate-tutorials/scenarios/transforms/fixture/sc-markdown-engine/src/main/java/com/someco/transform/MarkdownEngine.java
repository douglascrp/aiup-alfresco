package com.someco.transform;
import org.alfresco.transform.base.TransformEngine;
import org.alfresco.transform.base.probes.ProbeTransform;
import org.alfresco.transform.config.TransformConfig;
public class MarkdownEngine implements TransformEngine {
    public String getTransformEngineName() { return "markdown"; }
    public String getStartupMessage() { return "Startup markdown"; }
    public TransformConfig getTransformConfig() { return null; }
    public ProbeTransform getProbeTransform() { return null; }
}
