import XCTest
import CourseData

final class PolygonGeometryTests: XCTestCase {
    func testCentroidOfSquare() {
        let polygon = [
            Coordinate(latitude: 0, longitude: 0),
            Coordinate(latitude: 0, longitude: 2),
            Coordinate(latitude: 2, longitude: 2),
            Coordinate(latitude: 2, longitude: 0)
        ]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(centroid.latitude, 1.0, accuracy: 0.001)
        XCTAssertEqual(centroid.longitude, 1.0, accuracy: 0.001)
    }

    func testCentroidOfTriangle() {
        let polygon = [
            Coordinate(latitude: 0, longitude: 0),
            Coordinate(latitude: 0, longitude: 6),
            Coordinate(latitude: 3, longitude: 3)
        ]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(centroid.latitude, 1.0, accuracy: 0.001)
        XCTAssertEqual(centroid.longitude, 3.0, accuracy: 0.001)
    }

    func testAreaOfSquare() {
        let polygon = [
            Coordinate(latitude: 0, longitude: 0),
            Coordinate(latitude: 0, longitude: 2),
            Coordinate(latitude: 2, longitude: 2),
            Coordinate(latitude: 2, longitude: 0)
        ]
        let area = PolygonGeometry.area(of: polygon)
        XCTAssertEqual(area, 4.0, accuracy: 0.001)
    }

    func testFrontAndBackFromDirection() {
        let polygon = [
            Coordinate(latitude: 39.786, longitude: -74.956),
            Coordinate(latitude: 39.786, longitude: -74.954),
            Coordinate(latitude: 39.788, longitude: -74.954),
            Coordinate(latitude: 39.788, longitude: -74.956)
        ]
        let approachFrom = Coordinate(latitude: 39.780, longitude: -74.955)
        let front = PolygonGeometry.nearestPoint(on: polygon, to: approachFrom)
        let back = PolygonGeometry.farthestPoint(on: polygon, to: approachFrom)

        XCTAssertEqual(front.latitude, 39.786, accuracy: 0.001)
        XCTAssertEqual(back.latitude, 39.788, accuracy: 0.001)
    }

    func testCentroidOfEmptyPolygon() {
        let centroid = PolygonGeometry.centroid(of: [])
        XCTAssertEqual(centroid.latitude, 0)
        XCTAssertEqual(centroid.longitude, 0)
    }

    func testCentroidOfSinglePoint() {
        let polygon = [Coordinate(latitude: 39.0, longitude: -105.0)]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(centroid.latitude, 39.0)
        XCTAssertEqual(centroid.longitude, -105.0)
    }

    func testCentroidElevationIsMeanOfVertexElevations() throws {
        let polygon = [
            Coordinate(latitude: 39.0, longitude: -105.0, elevation: 1600),
            Coordinate(latitude: 39.0, longitude: -104.0, elevation: 1602),
            Coordinate(latitude: 40.0, longitude: -104.0, elevation: 1604),
            Coordinate(latitude: 40.0, longitude: -105.0, elevation: 1606),
        ]
        let centroid = PolygonGeometry.centroid(of: polygon)
        XCTAssertEqual(try XCTUnwrap(centroid.elevation), 1603, accuracy: 0.0001)
    }

    func testCentroidElevationIsNilWhenAnyVertexLacksElevation() {
        let polygon = [
            Coordinate(latitude: 39.0, longitude: -105.0, elevation: 1600),
            Coordinate(latitude: 39.0, longitude: -104.0),
            Coordinate(latitude: 40.0, longitude: -104.0, elevation: 1604),
        ]
        XCTAssertNil(PolygonGeometry.centroid(of: polygon).elevation)
    }

    func testContainsPointInside() {
        let polygon = [
            Coordinate(latitude: 0, longitude: 0),
            Coordinate(latitude: 0, longitude: 4),
            Coordinate(latitude: 4, longitude: 4),
            Coordinate(latitude: 4, longitude: 0)
        ]
        let inside = Coordinate(latitude: 2, longitude: 2)
        XCTAssertTrue(PolygonGeometry.contains(inside, in: polygon))
    }

    func testContainsPointOutside() {
        let polygon = [
            Coordinate(latitude: 0, longitude: 0),
            Coordinate(latitude: 0, longitude: 4),
            Coordinate(latitude: 4, longitude: 4),
            Coordinate(latitude: 4, longitude: 0)
        ]
        let outside = Coordinate(latitude: 5, longitude: 5)
        XCTAssertFalse(PolygonGeometry.contains(outside, in: polygon))
    }
}
