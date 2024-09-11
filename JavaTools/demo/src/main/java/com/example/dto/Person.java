package com.example.dto;

import com.file.annotation.Alignment;
import com.file.annotation.RowFormat;
import com.file.enumerate.AlignmentType;

@RowFormat(charset = "UTF-8", rowLength = 50)
public class Person {
    @Alignment(align = AlignmentType.RIGHT, paddingChar = "0", width = 5, separator = "|")
    private String id;

    @Alignment(align = AlignmentType.LEFT, paddingChar = "　", width = 10, separator = "|")  // 使用全形空格
    private String name;

    @Alignment(align = AlignmentType.LEFT, paddingChar = "", width = 15)
    private String email;

    public Person(String id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }
}