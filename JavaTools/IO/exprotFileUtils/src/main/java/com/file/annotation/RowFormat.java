package com.file.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface RowFormat {
    String charset() default "UTF-8";
    int rowLength() default -1; // -1 表示不限制長度
    String paddingChar() default " ";
}