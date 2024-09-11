package com.example;
import com.example.dto.Person;
import com.file.io.FormattedDataStreamWriter;

import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        String fileName = "output.txt";

        try (FormattedDataStreamWriter writer = new FormattedDataStreamWriter(Person.class, fileName)) {
            // 創建一些 Person 對象
            Person person1 = new Person("1", "Alice", "alice@example.com");
            Person person2 = new Person("2", "Bob", "bob@example.com");
            Person person3 = new Person("3", "Charlie", "charlie@example.com");

            // 寫入對象
            writer.writeObject(person1);
            writer.writeObject(person2);
            writer.writeObject(person3);

            System.out.println("Data has been written to " + fileName);

        } catch (IOException e) {
            System.err.println("An error occurred while writing to the file: " + e.getMessage());
            e.printStackTrace();
        }
    }
}