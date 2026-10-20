import XCTest
import CourseDataSwift

final class PolygonGeometryTests: XCTestCase {
    func testCentroidOfSquare() {
        let polygon = [
            Coordinate(lat: 0, lon: 0),
            Coordinate(lat: 0, lon: 2),
            Coordinate(lat: 2, lon: 2),
            Coordinate(lat: 2, lon: 0)
        ]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(centroid.lat, 1.0, accuracy: 0.001)
        XCTAssertEqual(centroid.lon, 1.0, accuracy: 0.001)
    }

    func testCentroidOfTriangle() {
        let polygon = [
            Coordinate(lat: 0, lon: 0),
            Coordinate(lat: 0, lon: 6),
            Coordinate(lat: 3, lon: 3)
        ]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(centroid.lat, 1.0, accuracy: 0.001)
        XCTAssertEqual(centroid.lon, 3.0, accuracy: 0.001)
    }

    func testAreaOfSquare() {
        let polygon = [
            Coordinate(lat: 0, lon: 0),
            Coordinate(lat: 0, lon: 2),
            Coordinate(lat: 2, lon: 2),
            Coordinate(lat: 2, lon: 0)
        ]
        let area = PolygonGeometry.area(of: polygon)
        XCTAssertEqual(area, 4.0, accuracy: 0.001)
    }

    func testFrontAndBackFromDirection() {
        let polygon = [
            Coordinate(lat: 39.786, lon: -74.956),
            Coordinate(lat: 39.786, lon: -74.954),
            Coordinate(lat: 39.788, lon: -74.954),
            Coordinate(lat: 39.788, lon: -74.956)
        ]
        let approachFrom = Coordinate(lat: 39.780, lon: -74.955)
        let front = PolygonGeometry.nearestPoint(on: polygon, to: approachFrom)
        let back = PolygonGeometry.farthestPoint(on: polygon, to: approachFrom)

        XCTAssertEqual(front.lat, 39.786, accuracy: 0.001)
        XCTAssertEqual(back.lat, 39.788, accuracy: 0.001)
    }

    func testCentroidOfEmptyPolygon() {
        let centroid = PolygonGeometry.centroid(of: [])
        XCTAssertEqual(centroid.lat, 0)
        XCTAssertEqual(centroid.lon, 0)
    }

    func testCentroidOfSinglePoint() {
        let polygon = [Coordinate(lat: 39.0, lon: -105.0)]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(centroid.lat, 39.0)
        XCTAssertEqual(centroid.lon, -105.0)
    }

    func testCentroidElevationIsMeanOfVertexElevations() throws {
        let polygon = [
            Coordinate(lat: 39.0, lon: -105.0, ele: 1600),
            Coordinate(lat: 39.0, lon: -104.0, ele: 1602),
            Coordinate(lat: 40.0, lon: -104.0, ele: 1604),
            Coordinate(lat: 40.0, lon: -105.0, ele: 1606),
        ]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(try XCTUnwrap(centroid.ele), 1603, accuracy: 0.0001)
    }

    func testCentroidElevationIsNilWhenAnyVertexLacksElevation() {
        let polygon = [
            Coordinate(lat: 39.0, lon: -105.0, ele: 1600),
            Coordinate(lat: 39.0, lon: -104.0),
            Coordinate(lat: 40.0, lon: -104.0, ele: 1604),
        ]
        XCTAssertNil(PolygonGeometry.centroid(of: polygon).ele)
    }

    func testContainsPointInside() {
        let polygon = [
            Coordinate(lat: 0, lon: 0),
            Coordinate(lat: 0, lon: 4),
            Coordinate(lat: 4, lon: 4),
            Coordinate(lat: 4, lon: 0)
        ]
        let inside = Coordinate(lat: 2, lon: 2)
        XCTAssertTrue(PolygonGeometry.contains(inside, in: polygon))
    }

    func testContainsPointOutside() {
        let polygon = [
            Coordinate(lat: 0, lon: 0),
            Coordinate(lat: 0, lon: 4),
            Coordinate(lat: 4, lon: 4),
            Coordinate(lat: 4, lon: 0)
        ]
        let outside = Coordinate(lat: 5, lon: 5)
        XCTAssertFalse(PolygonGeometry.contains(outside, in: polygon))
    }
}
