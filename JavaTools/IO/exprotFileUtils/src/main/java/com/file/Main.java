package com.file;

import com.file.dto.Person;
import com.file.io.FormattedDataStreamWriter;

import java.io.IOException;

//TIP To <b>Run</b> code, press <shortcut actionId="Run"/> or
// click the <icon src="AllIcons.Actions.Execute"/> icon in the gutter.
public class Main {
    public static void main(String[] args) {
        try (FormattedDataStreamWriter output = new FormattedDataStreamWriter(Person.class, "test.txt")) {
            // 創建一些 Person 對象
            Person person1 = new Person("1", "Alice", "alice@example.com");
            Person person2 = new Person("2", "Bob", "bob@example.com");
            Person person3 = new Person("3", "Charlie", "charlie@example.com");

            // 寫入對象
            output.writeObject(person1);
            output.writeObject(person2);
            output.writeObject(person3);

        } catch (IOException  e) {
            e.printStackTrace();
        }
    }
}