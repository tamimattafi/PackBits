package com.smartlink.data.utils;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

public class PackBits {

    public static byte[] unpack(final byte[] packedSource, final int expectedLength) throws IllegalStateException {
        int total = 0;

        final ByteArrayOutputStream baos = new ByteArrayOutputStream();

        // Loop until you get the number of unpacked bytes you are expecting:
        try {
            int i = 0;
            while (total < expectedLength) {
                // Read the next source byte into n.
                if (i >= packedSource.length) {
                    throw new IllegalStateException("Packbits: Unpack bits source exhausted: " + i + ", done + " + total + ", expectedLength + " + expectedLength);
                }

                final int n = packedSource[i++];
                if ((n >= 0) && (n <= 127)) {
                    // If n is between 0 and 127 inclusive, copy the next n+1 bytes
                    // literally.
                    final int count = n + 1;

                    total += count;
                    for (int j = 0; j < count; j++) {
                        baos.write(packedSource[i++]);
                    }
                } else if ((n >= -127) && (n <= -1)) {
                    // Else if n is between -127 and -1 inclusive, copy the next byte
                    // -n+1 times.

                    final int b = packedSource[i++];
                    final int count = -n + 1;

                    total += count;
                    for (int j = 0; j < count; j++) {
                        baos.write(b);
                    }
                } else if (n == -128) {
                    // Else if n is -128, noop.
                    throw new IllegalStateException("Packbits: " + n);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return baos.toByteArray();

    }

    private static int findNextDuplicate(final byte[] bytes, final int start) {
        // int last = -1;
        if (start >= bytes.length) {
            return -1;
        }

        byte prev = bytes[start];

        for (int i = start + 1; i < bytes.length; i++) {
            final byte b = bytes[i];

            if (b == prev) {
                return i - 1;
            }

            prev = b;
        }

        return -1;
    }

    private static int findRunLength(final byte[] bytes, final int start) {
        final byte b = bytes[start];

        int i;

        for (i = start + 1; (i < bytes.length) && (bytes[i] == b); i++) {
            // do nothing
        }

        return i - start;
    }

    public static byte[] pack(final byte[] unpackedSource) throws IOException {
        // max length 1 extra byte for every 128
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream(unpackedSource.length * 2)) {
            int ptr = 0;
            while (ptr < unpackedSource.length) {
                int dup = findNextDuplicate(unpackedSource, ptr);

                if (dup == ptr) {
                    // write run length
                    final int len = findRunLength(unpackedSource, dup);
                    final int actualLen = Math.min(len, 128);
                    baos.write(-(actualLen - 1));
                    baos.write(unpackedSource[ptr]);
                    ptr += actualLen;
                } else {
                    // write literals
                    int len = dup - ptr;

                    if (dup > 0) {
                        final int runlen = findRunLength(unpackedSource, dup);
                        if (runlen < 3) {
                            // may want to discard next run.
                            final int nextptr = ptr + len + runlen;
                            final int nextdup = findNextDuplicate(unpackedSource, nextptr);
                            if (nextdup != nextptr) {
                                // discard 2-byte run
                                dup = nextdup;
                                len = dup - ptr;
                            }
                        }
                    }

                    if (dup < 0) {
                        len = unpackedSource.length - ptr;
                    }
                    final int actualLen = Math.min(len, 128);

                    baos.write(actualLen - 1);
                    for (int i = 0; i < actualLen; i++) {
                        baos.write(unpackedSource[ptr]);
                        ptr++;
                    }
                }
            }

            return baos.toByteArray();
        }
    }
}
