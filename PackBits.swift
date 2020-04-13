//
// Created by toxic-dev on 2/25/20.
//

import Foundation

extension String: Error {
}


class PackBits {

    public static var debug = true

    public static func unpack(this data: Data, expectingSizeOf expectedSize: Int) throws -> Data {
        printDebug(text: "Unpacking started")
        var total = 0
        let inputStream = data.map {
            Int8(bitPattern: $0)
        }
        var outputStream = Data(capacity: expectedSize)
        do {

            var index = 0
            while total < expectedSize {
                printDebug(text: "Estimated Unpacking Progress: \((total*100)/expectedSize)%")

                // Read the next source byte into n.
                if index >= inputStream.count {
                    printDebug(text: "Error: Index is equal or bigger than the data count")
                    throw "Packbits: Unpack bits source exhausted: \(index), done \(total), expectedSize \(expectedSize)";
                }


                let n = Int(inputStream[index])
                index += 1

                if (n >= 0) && (n <= 127) {
                    printDebug(text: "Copying next n+1 bytes...")
                    // If n is between 0 and 127 inclusive, copy the next n+1 bytes
                    // literally.
                    let count = n + 1

                    total += count

                    for _ in 0..<count {
                        printDebug(text: "Appending data...")
                        outputStream.append(UInt8(bitPattern: inputStream[index]))
                        index += 1
                    }
                } else if (n >= -127) && (n <= -1) {
                    printDebug(text: "Copying next byte...")
                    // Else if n is between -127 and -1 inclusive, copy the next byte
                    // -n+1 times.
                    let b = inputStream[index]
                    index += 1

                    let count = -n + 1

                    total += count

                    for _ in 0..<count {
                        printDebug(text: "Appending data...")
                        outputStream.append(UInt8(b))
                    }
                } else if (n == -128) {
                    printDebug(text: "Error: n equals to -128")
                    throw "Packbits: \(n)"
                }
            }

        } catch {
            print(error)
        }

        return outputStream
    }


    private static func findNextDuplicate(from data: Data, startingAt start: Int) -> Int {
        // int last = -1;
        if start >= data.count {
            return -1
        }

        var prev = data[start]

        for index in (start + 1)..<data.count {
            let b = data[index]

            if b == prev {
                return index - 1
            }

            prev = b;
        }


        return -1
    }

    private static func findRunLength(from data: Data, startingAt start: Int) -> Int {
        let b = data[start]

        var index = start + 1

        for _ in index..<data.count {
            if data[index] == b {
                index += 1
            } else {
                break
            }
        }

        return index - start
    }


    public static func pack(this data: Data) throws -> Data {
        printDebug(text: "Started Packing...")
        // max length 1 extra byte for every 128
        var outputStream = Data(capacity: data.count * 2)
        var ptr = 0

        while ptr < data.count {
            printDebug(text: "Estimated Packing Progress: \((ptr*100)/data.count)%")
            printDebug(text: "Finding duplicate starting at \(ptr)")
            var duplicate = findNextDuplicate(from: data, startingAt: ptr)

            if duplicate == ptr {
                printDebug(text: "Writing Run Length...")
                // write run length
                printDebug(text: "Finding Run Length starting at \(duplicate)...")
                let runLength = findRunLength(from: data, startingAt: duplicate)
                printDebug(text: "Finding Actual Run Length: min between \(runLength) and 128...")
                let actualRunLength = min(runLength, 128)
                printDebug(text: "Converting int \(-(actualRunLength - 1)) to byte...")
                let runLengthByte = Int8(-(actualRunLength - 1))
                printDebug(text: "Appending Run Length byte \(runLengthByte)...")
                outputStream.append(UInt8(bitPattern: runLengthByte))
                printDebug(text: "Appending data at index \(ptr)...")
                outputStream.append(data[ptr])
                ptr += actualRunLength
            } else {
                printDebug(text: "Writing Literals...")
                // write literals
                var runLength = duplicate - ptr

                if duplicate > 0 {
                    printDebug(text: "Finding Run Length starting at \(duplicate)...")
                    let nextRunLength = findRunLength(from: data, startingAt: duplicate)
                    if nextRunLength < 3 {
                        // may want to discard next run.
                        printDebug(text: "Discarding Next Run...")
                        let nextPtr = ptr + (runLength + nextRunLength)
                        printDebug(text: "Finding next duplicated starting at \(nextPtr)...")
                        let nextDuplicate = findNextDuplicate(from: data, startingAt: nextPtr)
                        if nextDuplicate != nextPtr {
                            // discard 2-byte run
                            printDebug(text: "Discarding 2-byte Run...")
                            duplicate = nextDuplicate
                            runLength = (duplicate - ptr)
                        }
                    }
                }

                if duplicate < 0 {
                    runLength = (data.count - ptr)
                }

                printDebug(text: "Finding actual run length betweein \(runLength) and 128...")
                let actualRunLength = min(runLength, 128)
                printDebug(text: "Converting int \(actualRunLength - 1) to byte...")
                let actualRunLengthByte = Int8(actualRunLength - 1)
                printDebug(text: "Appending actual run length byte \(actualRunLengthByte)")
                outputStream.append(UInt8(bitPattern: actualRunLengthByte))

                for _ in 0..<actualRunLength {
                    printDebug(text: "Appending data at index \(ptr)")
                    outputStream.append(data[ptr])
                    ptr += 1
                }
            }
        }

        return outputStream

    }


    private static func printDebug(text: String) {
        if debug {
            print(text)
        }
    }
}