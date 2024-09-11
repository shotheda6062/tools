package com.file.io;

import com.file.annotation.Alignment;
import com.file.annotation.RowFormat;
import com.file.enumerate.AlignmentType;

import java.io.*;
import java.lang.reflect.Field;
import java.nio.charset.Charset;

public class FormattedDataStreamWriter extends OutputStream implements AutoCloseable {
    private static final int BUFFER_SIZE = 8192; // 8KB buffer size, you can adjust this
    private final BufferedOutputStream bufferedOut;
    private final Charset charset;
    private final int rowLength;
    private final Class<?> clazz;
    private final String paddingChar ;

    public FormattedDataStreamWriter(Class<?> clazz, String fileName) throws IOException {
        this.clazz = clazz;
        RowFormat rowFormat = clazz.getAnnotation(RowFormat.class);
        assert rowFormat != null;
        this.charset = Charset.forName(rowFormat.charset());
        this.rowLength =  rowFormat.rowLength();
        this.bufferedOut = new BufferedOutputStream(new FileOutputStream(fileName, true), BUFFER_SIZE);
        this.paddingChar = rowFormat.paddingChar();
    }

    @Override
    public void write(int b) throws IOException {
        bufferedOut.write(b);
    }

    @Override
    public void write(byte[] b, int off, int len) throws IOException {
        bufferedOut.write(b, off, len);
    }

    public void writeObject(Object obj) throws IOException {
        try {
            String rowData = formatObject(obj);
            byte[] data = (rowData + System.lineSeparator()).getBytes(charset);
            write(data);
        } catch (IllegalAccessException e) {
            throw new IOException("Error formatting object", e);
        }
    }

    private String formatObject(Object obj) throws IllegalAccessException {
        StringBuilder rowBuilder = new StringBuilder();
        Field[] fields = clazz.getDeclaredFields();

        for (int i = 0; i < fields.length; i++) {
            Field field = fields[i];
            field.setAccessible(true);
            Alignment alignment = field.getAnnotation(Alignment.class);

            if (alignment != null) {
                String value = String.valueOf(field.get(obj));
                int width = alignment.width();

                String formattedValue = formatValue(value, width, alignment.align(), alignment.paddingChar());
                rowBuilder.append(formattedValue);

                if (i < fields.length - 1 && !alignment.separator().isEmpty()) {
                    rowBuilder.append(alignment.separator());
                }
            } else {
                rowBuilder.append(String.valueOf(field.get(obj)));
            }
        }

        if (rowLength > 0) {
            if (rowBuilder.length() > rowLength) {
                String rowData = rowBuilder.toString();
                return rowData.substring(0, rowLength);
            } else if (rowBuilder.length() < rowLength) {
                while (rowBuilder.length() < rowLength) {
                    rowBuilder.append(paddingChar);
                }
            }
        }

        return rowBuilder.toString();
    }

    private String formatValue(String value, int width, AlignmentType alignmentType, String paddingChar) {
        if (value.length() >= width) {
            return value.substring(0, width);
        }

        StringBuilder sb = new StringBuilder();
        int paddingLength = width - value.length();

        if (alignmentType == AlignmentType.RIGHT) {
            sb.append(paddingChar.repeat(paddingLength));
            sb.append(value);
        } else {
            sb.append(value);
            sb.append(paddingChar.repeat(paddingLength));
        }

        return sb.toString();
    }

    @Override
    public void flush() throws IOException {
        bufferedOut.flush();
    }

    @Override
    public void close() throws IOException {
        bufferedOut.close();
    }
}