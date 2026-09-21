import Foundation
import zlib

public enum GZipError: Error {
    case compressionFailed(Int32)
    case decompressionFailed(Int32)
}

public extension Data {
    func gzipCompressed() throws -> Data {
        var stream = z_stream()

        if !isEmpty {
            withUnsafeBytes { inputPtr in
                let bound = inputPtr.bindMemory(to: UInt8.self)
                stream.next_in = UnsafeMutablePointer(mutating: bound.baseAddress!)
                stream.avail_in = uInt(count)
            }
        }

        var status = deflateInit2_(&stream, Z_BEST_COMPRESSION, Z_DEFLATED,
                                   MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                                   ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else { throw GZipError.compressionFailed(status) }

        let bound = deflateBound(&stream, uLong(count))
        var output = Data(count: Int(bound))
        output.withUnsafeMutableBytes { outputPtr in
            stream.next_out = outputPtr.bindMemory(to: UInt8.self).baseAddress
            stream.avail_out = uInt(bound)
        }

        status = deflate(&stream, Z_FINISH)
        let compressedSize = Int(stream.total_out)
        deflateEnd(&stream)

        guard status == Z_STREAM_END else { throw GZipError.compressionFailed(status) }
        return output.prefix(compressedSize)
    }

    func gzipDecompressed() throws -> Data {
        guard !isEmpty else {
            return Data()
        }

        var stream = z_stream()
        withUnsafeBytes { inputPtr in
            let bound = inputPtr.bindMemory(to: UInt8.self)
            stream.next_in = UnsafeMutablePointer(mutating: bound.baseAddress!)
            stream.avail_in = uInt(count)
        }

        var status = inflateInit2_(&stream, MAX_WBITS + 16,
                                   ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else { throw GZipError.decompressionFailed(status) }

        let chunkSize = count * 2
        var output = Data(count: chunkSize)
        repeat {
            let outputCount = output.count
            if Int(stream.total_out) >= outputCount {
                output.count = outputCount + chunkSize
            }
            let totalOut = Int(stream.total_out)
            let availableOut = output.count - totalOut
            output.withUnsafeMutableBytes { outputPtr in
                let base = outputPtr.bindMemory(to: UInt8.self).baseAddress!
                stream.next_out = base.advanced(by: totalOut)
                stream.avail_out = uInt(availableOut)
            }
            status = inflate(&stream, Z_NO_FLUSH)
        } while status == Z_OK

        let decompressedSize = Int(stream.total_out)
        inflateEnd(&stream)

        guard status == Z_STREAM_END else { throw GZipError.decompressionFailed(status) }
        return output.prefix(decompressedSize)
    }
}
