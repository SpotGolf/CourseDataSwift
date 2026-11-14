import XCTest
import CourseDataSwift

final class ElevationSurfaceTests: XCTestCase {
    private let origin = Coordinate(lat: 39.9565432, lon: -105.0403751)

    /// Three columns by two rows. The south-west and north-east cells are outside the green.
    private let elevations: [Double?] = [
        nil, 1600.12, 1600.15,
        1600.09, 1600.11, nil
    ]

    private var surface: ElevationSurface {
        ElevationSurface(origin: origin, columns: 3, elevations: elevations)
    }

    private func sortedJSON(_ surface: ElevationSurface) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(surface), as: UTF8.self)
    }

    func testCellAccess() {
        let surface = surface
        XCTAssertEqual(surface.origin, origin)
        XCTAssertEqual(surface.spacing, 1.0)
        XCTAssertEqual(surface.columns, 3)
        XCTAssertEqual(surface.rows, 2)
        for row in 0..<2 {
            for column in 0..<3 {
                let expected = elevations[row * 3 + column]
                let actual = surface.elevation(column: column, row: row)
                if let expected, let actual {
                    XCTAssertEqual(actual, expected, accuracy: 0.005)
                } else {
                    XCTAssertEqual(actual == nil, expected == nil)
                }
            }
        }
    }

    func testCellOutsideGridIsNil() {
        let surface = surface
        XCTAssertNil(surface.elevation(column: -1, row: 0))
        XCTAssertNil(surface.elevation(column: 3, row: 0))
        XCTAssertNil(surface.elevation(column: 0, row: -1))
        XCTAssertNil(surface.elevation(column: 0, row: 2))
    }

    func testRoundsToCentimeters() {
        let surface = ElevationSurface(origin: origin, columns: 2, elevations: [1600.1249, 1600.126])
        XCTAssertEqual(surface.elevation(column: 0, row: 0)!, 1600.12, accuracy: 1e-9)
        XCTAssertEqual(surface.elevation(column: 1, row: 0)!, 1600.13, accuracy: 1e-9)
    }

    func testCodableRoundTrip() throws {
        let data = try JSONEncoder().encode(surface)
        XCTAssertEqual(try JSONDecoder().decode(ElevationSurface.self, from: data), surface)
    }

    func testJSONFormat() throws {
        XCTAssertEqual(
            try sortedJSON(surface),
            #"{"columns":3,"elevations":[null,160012,3,-6,2,null],"origin":{"lat":39.9565432,"lon":-105.0403751},"spacing":1}"#
        )
    }

    func testDecodesFromJSON() throws {
        let json = #"{"origin":{"lat":39.9565432,"lon":-105.0403751},"spacing":1.0,"columns":3,"elevations":[null,160012,3,-6,2,null]}"#
        XCTAssertEqual(try JSONDecoder().decode(ElevationSurface.self, from: Data(json.utf8)), surface)
    }

    func testNegativeElevationsRoundTrip() throws {
        let surface = ElevationSurface(origin: origin, columns: 3, elevations: [-1.25, nil, 0.5])
        let data = try JSONEncoder().encode(surface)
        let decoded = try JSONDecoder().decode(ElevationSurface.self, from: data)
        XCTAssertEqual(decoded, surface)
        XCTAssertEqual(decoded.elevation(column: 0, row: 0)!, -1.25, accuracy: 1e-9)
        XCTAssertNil(decoded.elevation(column: 1, row: 0))
        XCTAssertEqual(decoded.elevation(column: 2, row: 0)!, 0.5, accuracy: 1e-9)
    }

    func testAllCellsOutsideGreenRoundTrip() throws {
        let surface = ElevationSurface(origin: origin, columns: 2, elevations: [nil, nil, nil, nil])
        XCTAssertTrue(try sortedJSON(surface).contains(#""elevations":[null,null,null,null]"#))
        let data = try JSONEncoder().encode(surface)
        XCTAssertEqual(try JSONDecoder().decode(ElevationSurface.self, from: data), surface)
    }

    func testEmptySurfaceRoundTrip() throws {
        let surface = ElevationSurface(origin: origin, columns: 0, elevations: [])
        let data = try JSONEncoder().encode(surface)
        XCTAssertEqual(try JSONDecoder().decode(ElevationSurface.self, from: data), surface)
    }

    func testDecodeRejectsPartialRow() {
        let json = #"{"origin":{"lat":39,"lon":-105},"spacing":1,"columns":3,"elevations":[160012,3,-6,2]}"#
        XCTAssertThrowsError(try JSONDecoder().decode(ElevationSurface.self, from: Data(json.utf8)))
    }

    func testDecodeRejectsNegativeColumns() {
        let json = #"{"origin":{"lat":39,"lon":-105},"spacing":1,"columns":-1,"elevations":[5]}"#
        XCTAssertThrowsError(try JSONDecoder().decode(ElevationSurface.self, from: Data(json.utf8)))
    }
}
