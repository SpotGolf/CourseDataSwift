import XCTest
import CoreLocation
import CourseDataSwift

final class CoordinateTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let coord = Coordinate(lat: 39.9397, lon: -105.0267)
        let data = try JSONEncoder().encode(coord)
        let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
        XCTAssertEqual(coord, decoded)
    }

    func testCLLocationCoordinate2D() {
        let coord = Coordinate(lat: 39.9397, lon: -105.0267)
        let cl = coord.clCoordinate
        XCTAssertEqual(cl.latitude, 39.9397)
        XCTAssertEqual(cl.longitude, -105.0267)
    }

    func testCLLocation() {
        let coord = Coordinate(lat: 39.9397, lon: -105.0267)
        let loc = coord.clLocation
        XCTAssertEqual(loc.coordinate.latitude, 39.9397)
        XCTAssertEqual(loc.coordinate.longitude, -105.0267)
    }

    func testInitFromCLLocationCoordinate2D() {
        let cl = CLLocationCoordinate2D(latitude: 39.9397, longitude: -105.0267)
        let coord = Coordinate(cl)
        XCTAssertEqual(coord.lat, 39.9397)
        XCTAssertEqual(coord.lon, -105.0267)
    }

    func testJSONUsesShortKeys() throws {
        let coord = Coordinate(lat: 39.7879, lon: -74.958)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(coord), as: UTF8.self)
        XCTAssertEqual(json, #"{"lat":39.7879,"lon":-74.958}"#)
    }

    func testJSONUsesShortKeysWithElevation() throws {
        let coord = Coordinate(lat: 39.7879, lon: -74.958, ele: 12.25)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(coord), as: UTF8.self)
        XCTAssertEqual(json, #"{"ele":12.25,"lat":39.7879,"lon":-74.958}"#)
    }

    func testJSONDecoding() throws {
        let json = #"{"lat": 39.7879, "lon": -74.958, "ele": 12.25}"#
        let coord = try JSONDecoder().decode(Coordinate.self, from: Data(json.utf8))
        XCTAssertEqual(coord, Coordinate(lat: 39.7879, lon: -74.958, ele: 12.25))
    }

    func testJSONDecodingWithoutElevation() throws {
        let json = #"{"lat": 39.7879, "lon": -74.958}"#
        let coord = try JSONDecoder().decode(Coordinate.self, from: Data(json.utf8))
        XCTAssertEqual(coord, Coordinate(lat: 39.7879, lon: -74.958))
        XCTAssertNil(coord.ele)
    }

    func testElevationDefaultsToNil() {
        let coord = Coordinate(lat: 39.9397, lon: -105.0267)
        XCTAssertNil(coord.ele)
    }

    func testCodableRoundTripWithElevation() throws {
        let coord = Coordinate(lat: 39.9397, lon: -105.0267, ele: 1624.5)
        let data = try JSONEncoder().encode(coord)
        let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
        XCTAssertEqual(coord, decoded)
    }

    func testCLLocationWithElevation() {
        let coord = Coordinate(lat: 39.9397, lon: -105.0267, ele: 1624.5)
        let loc = coord.clLocation
        XCTAssertEqual(loc.altitude, 1624.5)
        XCTAssertGreaterThanOrEqual(loc.verticalAccuracy, 0)
    }

    func testCLLocationWithoutElevationHasInvalidAltitude() {
        let coord = Coordinate(lat: 39.9397, lon: -105.0267)
        XCTAssertLessThan(coord.clLocation.verticalAccuracy, 0)
    }

    func testInitFromCLLocationCoordinate2DWithElevation() {
        let cl = CLLocationCoordinate2D(latitude: 39.9397, longitude: -105.0267)
        let coord = Coordinate(cl, ele: 1624.5)
        XCTAssertEqual(coord.ele, 1624.5)
    }
}
