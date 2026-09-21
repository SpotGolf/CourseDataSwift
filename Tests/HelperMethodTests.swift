import XCTest
import CourseData

// MARK: - Test Fixtures

private let greenPolygon = [
    Coordinate(latitude: 39.940, longitude: -105.030),
    Coordinate(latitude: 39.940, longitude: -105.029),
    Coordinate(latitude: 39.941, longitude: -105.029),
    Coordinate(latitude: 39.941, longitude: -105.030),
]

private let fairwayPolygon = [
    Coordinate(latitude: 39.935, longitude: -105.032),
    Coordinate(latitude: 39.935, longitude: -105.028),
    Coordinate(latitude: 39.939, longitude: -105.028),
    Coordinate(latitude: 39.939, longitude: -105.032),
]

private let bunkerPolygon = [
    Coordinate(latitude: 39.9395, longitude: -105.031),
    Coordinate(latitude: 39.9395, longitude: -105.030),
    Coordinate(latitude: 39.9400, longitude: -105.030),
    Coordinate(latitude: 39.9400, longitude: -105.031),
]

private let features = [
    Feature(id: 1, type: .tee, polygon: [
        Coordinate(latitude: 39.930, longitude: -105.031),
        Coordinate(latitude: 39.930, longitude: -105.030),
        Coordinate(latitude: 39.931, longitude: -105.030),
        Coordinate(latitude: 39.931, longitude: -105.031),
    ]),
    Feature(id: 2, type: .fairway, polygon: fairwayPolygon),
    Feature(id: 3, type: .green, polygon: greenPolygon),
    Feature(id: 4, type: .bunker, polygon: bunkerPolygon),
    Feature(id: 5, type: .fairway, polygon: [
        Coordinate(latitude: 39.950, longitude: -105.032),
        Coordinate(latitude: 39.950, longitude: -105.028),
        Coordinate(latitude: 39.955, longitude: -105.028),
        Coordinate(latitude: 39.955, longitude: -105.032),
    ]),
]

private let hole1 = Hole(
    number: 1,
    par: 4,
    features: [1, 2, 3, 4],
    centerline: [
        Coordinate(latitude: 39.930, longitude: -105.030),
        Coordinate(latitude: 39.937, longitude: -105.030),
        Coordinate(latitude: 39.941, longitude: -105.029),
    ]
)

private let hole2 = Hole(number: 2, par: 3, features: [5])

private func makeCourse() -> Course {
    Course(
        name: "Test Course",
        location: CourseLocation(
            address: "123 Test St",
            city: "Denver",
            state: "CO",
            country: "US",
            coordinate: Coordinate(latitude: 39.935, longitude: -105.030)
        ),
        features: features,
        subCourses: [
            SubCourse(name: "Front", holes: [hole1, hole2]),
            SubCourse(name: "Back", holes: [
                Hole(number: 1, par: 4),
                Hole(number: 2, par: 5),
            ]),
        ]
    )
}

// MARK: - Course Helper Tests

final class CourseHelperTests: XCTestCase {
    func testFindFeatureByID() {
        let course = makeCourse()
        let feature = course.findFeature(id: 3)
        XCTAssertNotNil(feature)
        XCTAssertEqual(feature?.type, .green)
    }

    func testFindFeatureMissingID() {
        let course = makeCourse()
        XCTAssertNil(course.findFeature(id: 999))
    }

    func testFeaturesForHole() {
        let course = makeCourse()
        let resolved = course.features(for: hole1)
        XCTAssertEqual(resolved.count, 4)
        XCTAssertEqual(Set(resolved.map(\.id)), [1, 2, 3, 4])
    }

    func testFeaturesForHoleWithNoFeatures() {
        let course = makeCourse()
        let empty = Hole(number: 9, par: 3)
        XCTAssertTrue(course.features(for: empty).isEmpty)
    }

    func testHoleBySubCourseAndNumber() {
        let course = makeCourse()
        let h = course.hole(subCourseIndex: 0, number: 2)
        XCTAssertNotNil(h)
        XCTAssertEqual(h?.par, 3)
    }

    func testHoleBySubCourseAndNumberNotFound() {
        let course = makeCourse()
        XCTAssertNil(course.hole(subCourseIndex: 0, number: 9))
    }

    func testHoleBySubCourseIndexOutOfBounds() {
        let course = makeCourse()
        XCTAssertNil(course.hole(subCourseIndex: 5, number: 1))
    }

    func testHoleFromIndices() {
        let course = makeCourse()
        let h = course.holeFromIndices(subCourse: 1, hole: 1)
        XCTAssertNotNil(h)
        XCTAssertEqual(h?.par, 5)
    }

    func testHoleFromIndicesOutOfBounds() {
        let course = makeCourse()
        XCTAssertNil(course.holeFromIndices(subCourse: 0, hole: 10))
        XCTAssertNil(course.holeFromIndices(subCourse: 5, hole: 0))
    }
}

// MARK: - Hole Helper Tests

final class HoleHelperTests: XCTestCase {
    func testGreenFromFeatures() {
        let green = hole1.green(from: features)
        XCTAssertNotNil(green)
        XCTAssertEqual(green?.id, 3)
        XCTAssertEqual(green?.type, .green)
    }

    func testGreenFromFeaturesWhenNoGreen() {
        let hole = Hole(number: 1, par: 4, features: [1, 2])
        let green = hole.green(from: features)
        XCTAssertNil(green)
    }

    func testVectorForFeature() {
        let v = hole1.vector(for: 3, from: features)
        XCTAssertNotNil(v)
        // The green's centroid (~39.9405, ~-105.0295) is closest to the second
        // segment (39.937 -> 39.941), which goes northeast. dx should be positive.
        XCTAssertGreaterThan(v!.dx, 0)
    }

    func testVectorForFeatureWithInsufficientCenterline() {
        let hole = Hole(number: 1, par: 4, features: [3], centerline: [
            Coordinate(latitude: 39.930, longitude: -105.030)
        ])
        XCTAssertNil(hole.vector(for: 3, from: features))
    }

    func testVectorForMissingFeature() {
        XCTAssertNil(hole1.vector(for: 999, from: features))
    }

    func testVectorIsUnitLength() {
        let v = hole1.vector(for: 2, from: features)!
        let magnitude = sqrt(v.dx * v.dx + v.dy * v.dy)
        XCTAssertEqual(magnitude, 1.0, accuracy: 1e-9)
    }

    func testOnFairway() {
        // Point inside the fairway polygon
        let inside = Coordinate(latitude: 39.937, longitude: -105.030)
        XCTAssertTrue(hole1.onFairway(inside, from: features))
    }

    func testOnFairwayOutside() {
        // Point well outside
        let outside = Coordinate(latitude: 39.900, longitude: -105.000)
        XCTAssertFalse(hole1.onFairway(outside, from: features))
    }

    func testOnGreen() {
        // Point inside the green polygon
        let inside = Coordinate(latitude: 39.9405, longitude: -105.0295)
        XCTAssertTrue(hole1.onGreen(inside, from: features))
    }

    func testOnGreenOutside() {
        let outside = Coordinate(latitude: 39.900, longitude: -105.000)
        XCTAssertFalse(hole1.onGreen(outside, from: features))
    }
}

// MARK: - Feature Helper Tests

final class FeatureHelperTests: XCTestCase {
    func testCenter() {
        let green = features[2] // id: 3, green
        let c = green.center
        XCTAssertEqual(c.latitude, 39.9405, accuracy: 0.001)
        XCTAssertEqual(c.longitude, -105.0295, accuracy: 0.001)
    }

    func testMiddleEqualsCenter() {
        let green = features[2]
        let c = green.center
        let m = green.middle()
        XCTAssertEqual(c.latitude, m.latitude, accuracy: 1e-10)
        XCTAssertEqual(c.longitude, m.longitude, accuracy: 1e-10)
    }

    func testFrontAndBack() {
        let green = features[2] // id: 3, green
        // Vector pointing north (positive latitude)
        let northVector = Vector2D(dx: 1, dy: 0)
        let front = green.front(vector: northVector)
        let back = green.back(vector: northVector)

        // Front should be the southern vertices (lower latitude)
        XCTAssertEqual(front.latitude, 39.940, accuracy: 1e-6)
        // Back should be the northern vertices (higher latitude)
        XCTAssertEqual(back.latitude, 39.941, accuracy: 1e-6)
    }

    func testFrontAndBackWithEastVector() {
        let green = features[2]
        // Vector pointing east (positive longitude)
        let eastVector = Vector2D(dx: 0, dy: 1)
        let front = green.front(vector: eastVector)
        let back = green.back(vector: eastVector)

        // Front should be the western edge (more negative longitude)
        XCTAssertEqual(front.longitude, -105.030, accuracy: 1e-6)
        // Back should be the eastern edge (less negative longitude)
        XCTAssertEqual(back.longitude, -105.029, accuracy: 1e-6)
    }

    func testFrontAndBackEmptyPolygon() {
        let empty = Feature(id: 99, type: .green, polygon: [])
        let v = Vector2D(dx: 1, dy: 0)
        XCTAssertEqual(empty.front(vector: v).latitude, 0)
        XCTAssertEqual(empty.back(vector: v).latitude, 0)
    }
}

// MARK: - Vector2D Tests

final class Vector2DTests: XCTestCase {
    func testNormalized() {
        let v = Vector2D(dx: 3, dy: 4).normalized()
        XCTAssertEqual(v.dx, 0.6, accuracy: 1e-10)
        XCTAssertEqual(v.dy, 0.8, accuracy: 1e-10)
    }

    func testNormalizedZeroVector() {
        let v = Vector2D(dx: 0, dy: 0).normalized()
        XCTAssertEqual(v.dx, 0)
        XCTAssertEqual(v.dy, 0)
    }

    func testEquality() {
        let a = Vector2D(dx: 1, dy: 2)
        let b = Vector2D(dx: 1, dy: 2)
        XCTAssertEqual(a, b)
    }
}

// MARK: - PolygonGeometry Segment Distance Tests

final class SegmentDistanceTests: XCTestCase {
    func testPointOnSegment() {
        let start = Coordinate(latitude: 0, longitude: 0)
        let end = Coordinate(latitude: 10, longitude: 0)
        let point = Coordinate(latitude: 5, longitude: 0)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 0, accuracy: 1e-10)
    }

    func testPointPerpendicularToSegment() {
        let start = Coordinate(latitude: 0, longitude: 0)
        let end = Coordinate(latitude: 10, longitude: 0)
        let point = Coordinate(latitude: 5, longitude: 3)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 9, accuracy: 1e-10)
    }

    func testPointBeyondSegmentEnd() {
        let start = Coordinate(latitude: 0, longitude: 0)
        let end = Coordinate(latitude: 10, longitude: 0)
        let point = Coordinate(latitude: 15, longitude: 0)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 25, accuracy: 1e-10)
    }

    func testPointBeforeSegmentStart() {
        let start = Coordinate(latitude: 0, longitude: 0)
        let end = Coordinate(latitude: 10, longitude: 0)
        let point = Coordinate(latitude: -3, longitude: 4)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 25, accuracy: 1e-10)
    }

    func testDegenerateSegment() {
        let point = Coordinate(latitude: 0, longitude: 0)
        let seg = Coordinate(latitude: 3, longitude: 4)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: seg, segEnd: seg)
        XCTAssertEqual(distSq, 25, accuracy: 1e-10)
    }
}
