package com.file.annotation;

import com.file.enumerate.AlignmentType;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface Alignment {

    AlignmentType align() default AlignmentType.LEFT;
    String paddingChar() default "";
    String separator() default "";
    int width() default 0;

}