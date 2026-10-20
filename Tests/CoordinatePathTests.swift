import XCTest
import CourseDataSwift

final class CoordinatePathTests: XCTestCase {
    private let points = [
        Coordinate(lat: 39.9565432, lon: -105.0403751, ele: 1600.25),
        Coordinate(lat: 39.9565532, lon: -105.0403951, ele: 1600.35),
        Coordinate(lat: 39.9565632, lon: -105.0404151, ele: 1600.15)
    ]

    /// Asserts that a stored point matches the original to within half a unit:
    /// 1/730,000 of a degree and half a foot of elevation.
    private func assertClose(_ actual: [Coordinate], _ expected: [Coordinate], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        for (a, e) in zip(actual, expected) {
            XCTAssertEqual(a.lat, e.lat, accuracy: 0.5 / 365_000, file: file, line: line)
            XCTAssertEqual(a.lon, e.lon, accuracy: 0.5 / 365_000, file: file, line: line)
            if let expectedEle = e.ele, let actualEle = a.ele {
                XCTAssertEqual(actualEle, expectedEle, accuracy: 0.1524, file: file, line: line)
            } else {
                XCTAssertEqual(a.ele == nil, e.ele == nil, file: file, line: line)
            }
        }
    }

    func testCollectionAccess() {
        let path = CoordinatePath(points)
        XCTAssertEqual(path.count, 3)
        assertClose(Array(path), points)
        assertClose([path[1]], [points[1]])
    }

    func testEmptyPath() throws {
        let path = CoordinatePath()
        XCTAssertTrue(path.isEmpty)
        let data = try JSONEncoder().encode(path)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), #"{"values":[]}"#)
        XCTAssertEqual(try JSONDecoder().decode(CoordinatePath.self, from: data), path)
    }

    func testArrayLiteral() {
        let path: CoordinatePath = [Coordinate(lat: 1, lon: 2)]
        XCTAssertEqual(Array(path), [Coordinate(lat: 1, lon: 2)])
    }

    func testAppend() {
        var path = CoordinatePath()
        path.append(points[0])
        path.append(points[1])
        XCTAssertEqual(path, CoordinatePath(points.prefix(2)))
    }

    func testRoundsToOneFoot() {
        let path = CoordinatePath([Coordinate(lat: 39.123456789, lon: -105.987654321, ele: 1600.25)])
        // 39.123456789 * 365,000 = 14,280,061.73, which rounds to 14,280,062
        XCTAssertEqual(path[0].lat, 14_280_062 / 365_000)
        // -105.987654321 * 365,000 = -38,685,493.83, which rounds to -38,685,494
        XCTAssertEqual(path[0].lon, -38_685_494 / 365_000)
        // 1600.25 m is 5,250.16 feet, which rounds to 5,250 feet
        XCTAssertEqual(path[0].ele, 5_250 * 0.3048)
    }

    func testStoredPointsDoNotDrift() throws {
        let path = CoordinatePath(points)
        XCTAssertEqual(CoordinatePath(path), path)
    }

    func testMissingElevation() throws {
        let original = [
            Coordinate(lat: 39.1, lon: -105.1, ele: 1600.5),
            Coordinate(lat: 39.2, lon: -105.2),
            Coordinate(lat: 39.3, lon: -105.3, ele: 1601.5)
        ]
        let path = CoordinatePath(original)
        XCTAssertNil(path[1].ele)
        assertClose(Array(path), original)

        let decoded = try JSONDecoder().decode(CoordinatePath.self, from: JSONEncoder().encode(path))
        XCTAssertEqual(decoded, path)
    }

    func testJSONEncodesMissingElevationAsNull() throws {
        let path = CoordinatePath([
            Coordinate(lat: 39.1, lon: -105.1, ele: 1600.5),
            Coordinate(lat: 39.2, lon: -105.2),
            Coordinate(lat: 39.3, lon: -105.3, ele: 1601.5)
        ])
        let json = String(decoding: try JSONEncoder().encode(path), as: UTF8.self)
        // 1600.5 m is 5,251 feet and 1601.5 m is 5,254 feet. The third elevation is the
        // difference from the first, the last one known.
        XCTAssertEqual(json, #"{"values":[14271500,-38361500,5251,36500,-36500,null,36500,-36500,3]}"#)
    }

    func testFirstElevationMissing() throws {
        let path = CoordinatePath([
            Coordinate(lat: 39.1, lon: -105.1),
            Coordinate(lat: 39.2, lon: -105.2, ele: 1600.5)
        ])
        let json = String(decoding: try JSONEncoder().encode(path), as: UTF8.self)
        XCTAssertEqual(json, #"{"values":[14271500,-38361500,null,36500,-36500,5251]}"#)
        XCTAssertEqual(try JSONDecoder().decode(CoordinatePath.self, from: Data(json.utf8)), path)
    }

    func testJSONEncodesDifferences() throws {
        let path = CoordinatePath(points)
        let json = String(decoding: try JSONEncoder().encode(path), as: UTF8.self)
        XCTAssertEqual(json, #"{"values":[14584138,-38339737,5250,4,-7,0,4,-8,0]}"#)
    }

    func testCodableRoundTrip() throws {
        let path = CoordinatePath(points)
        let decoded = try JSONDecoder().decode(CoordinatePath.self, from: JSONEncoder().encode(path))
        XCTAssertEqual(decoded, path)
        assertClose(Array(decoded), points)
    }

    func testDecodingRejectsIncompletePoint() {
        let json = #"{"values":[1,2]}"#
        XCTAssertThrowsError(try JSONDecoder().decode(CoordinatePath.self, from: Data(json.utf8)))
    }

    func testDecodingRejectsNullLatitude() {
        let json = #"{"values":[null,-38361500,5251]}"#
        XCTAssertThrowsError(try JSONDecoder().decode(CoordinatePath.self, from: Data(json.utf8)))
    }
}
