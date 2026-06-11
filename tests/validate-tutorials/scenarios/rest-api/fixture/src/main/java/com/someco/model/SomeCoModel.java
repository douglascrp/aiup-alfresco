package com.someco.model;
import org.alfresco.service.namespace.QName;
public interface SomeCoModel {
    String NAMESPACE_URI = "http://www.someco.com/model/content/1.0";
    QName TYPE_DOC = QName.createQName(NAMESPACE_URI, "doc");
}
