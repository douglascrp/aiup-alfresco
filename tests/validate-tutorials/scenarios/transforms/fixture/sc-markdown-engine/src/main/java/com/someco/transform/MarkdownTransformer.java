package com.someco.transform;
import org.alfresco.transform.base.CustomTransformer;
import org.alfresco.transform.base.TransformManager;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Map;
public class MarkdownTransformer implements CustomTransformer {
    public String getTransformerName() { return "markdown"; }
    public void transform(String s, InputStream in, String t, OutputStream out, Map<String,String> o, TransformManager m) { }
}
