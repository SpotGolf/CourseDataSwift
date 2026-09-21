import Foundation
import Testing

@testable import CourseData

@Suite("GZip Compression Tests")
struct GZipTests {
    @Test("Round-trip compress then decompress returns original data")
    func roundTrip() throws {
        let original = Data(#"{"name":"Broadlands Golf Course","holes":18}"#.utf8)

        let compressed = try original.gzipCompressed()
        let decompressed = try compressed.gzipDecompressed()

        #expect(decompressed == original)
    }

    @Test("Compressed output starts with gzip magic bytes 1f 8b")
    func magicBytes() throws {
        let data = Data("hello world".utf8)

        let compressed = try data.gzipCompressed()

        #expect(compressed.count >= 2)
        #expect(compressed[0] == 0x1F)
        #expect(compressed[1] == 0x8B)
    }

    @Test("Compressed data is smaller than original for repetitive input")
    func compressionReducesSize() throws {
        let repeated = Data(String(repeating: "abcdefgh", count: 1000).utf8)

        let compressed = try repeated.gzipCompressed()

        #expect(compressed.count < repeated.count)
    }

    @Test("Empty data round-trips correctly")
    func emptyData() throws {
        let empty = Data()

        let compressed = try empty.gzipCompressed()
        let decompressed = try compressed.gzipDecompressed()

        #expect(decompressed == empty)
    }

    @Test("Decompressing invalid data throws")
    func invalidDataThrows() throws {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])

        #expect(throws: GZipError.self) {
            try garbage.gzipDecompressed()
        }
    }
}
