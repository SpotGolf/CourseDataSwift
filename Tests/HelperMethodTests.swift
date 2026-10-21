import XCTest
import CourseDataSwift

// MARK: - Test Fixtures

private let greenPolygon: CoordinatePath = [
    Coordinate(lat: 39.940, lon: -105.030),
    Coordinate(lat: 39.940, lon: -105.029),
    Coordinate(lat: 39.941, lon: -105.029),
    Coordinate(lat: 39.941, lon: -105.030),
]

private let fairwayPolygon: CoordinatePath = [
    Coordinate(lat: 39.935, lon: -105.032),
    Coordinate(lat: 39.935, lon: -105.028),
    Coordinate(lat: 39.939, lon: -105.028),
    Coordinate(lat: 39.939, lon: -105.032),
]

private let bunkerPolygon: CoordinatePath = [
    Coordinate(lat: 39.9395, lon: -105.031),
    Coordinate(lat: 39.9395, lon: -105.030),
    Coordinate(lat: 39.9400, lon: -105.030),
    Coordinate(lat: 39.9400, lon: -105.031),
]

private let features = [
    Feature(id: 1, type: .tee, polygon: [
        Coordinate(lat: 39.930, lon: -105.031),
        Coordinate(lat: 39.930, lon: -105.030),
        Coordinate(lat: 39.931, lon: -105.030),
        Coordinate(lat: 39.931, lon: -105.031),
    ]),
    Feature(id: 2, type: .fairway, polygon: fairwayPolygon),
    Feature(id: 3, type: .green, polygon: greenPolygon),
    Feature(id: 4, type: .bunker, polygon: bunkerPolygon),
    Feature(id: 5, type: .fairway, polygon: [
        Coordinate(lat: 39.950, lon: -105.032),
        Coordinate(lat: 39.950, lon: -105.028),
        Coordinate(lat: 39.955, lon: -105.028),
        Coordinate(lat: 39.955, lon: -105.032),
    ]),
    Feature(id: 9, type: .centerline, polygon: [
        Coordinate(lat: 39.930, lon: -105.030),
        Coordinate(lat: 39.937, lon: -105.030),
        Coordinate(lat: 39.941, lon: -105.029),
    ]),
    Feature(id: 10, type: .centerline, polygon: [
        Coordinate(lat: 39.930, lon: -105.030)
    ]),
]

private let hole1 = Hole(
    number: 1,
    par: 4,
    features: [1, 2, 3, 4],
    centerline: 9
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
            coordinate: Coordinate(lat: 39.935, lon: -105.030)
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

    func testTeeBoxesFromFeatures() {
        let teePolygon: CoordinatePath = [
            Coordinate(lat: 39.932, lon: -105.031),
            Coordinate(lat: 39.932, lon: -105.030),
            Coordinate(lat: 39.933, lon: -105.030),
        ]
        let allFeatures = features + [
            Feature(id: 6, type: .tee, polygon: teePolygon),
            Feature(id: 7, type: .tee, polygon: teePolygon),
            Feature(id: 8, type: .tee, polygon: teePolygon),
        ]
        // Feature 7 is a tee box on another hole.
        let hole = Hole(number: 1, par: 4, features: [1, 2, 3, 6, 8])
        let teeBoxes = hole.teeBoxes(from: allFeatures)
        XCTAssertEqual(teeBoxes.map(\.id), [1, 6, 8])
        XCTAssertTrue(teeBoxes.allSatisfy { $0.type == .tee })
    }

    func testTeeBoxesFromFeaturesWhenNoTeeBoxes() {
        let hole = Hole(number: 1, par: 4, features: [2, 3])
        XCTAssertTrue(hole.teeBoxes(from: features).isEmpty)
    }

    func testVectorForFeature() {
        let v = hole1.vector(for: 3, from: features)
        XCTAssertNotNil(v)
        // The green's centroid (~39.9405, ~-105.0295) is closest to the second
        // segment (39.937 -> 39.941), which goes northeast. dx should be positive.
        XCTAssertGreaterThan(v!.dx, 0)
    }

    func testVectorForFeatureWithInsufficientCenterline() {
        let hole = Hole(number: 1, par: 4, features: [3], centerline: 10)
        XCTAssertNil(hole.vector(for: 3, from: features))
    }

    func testVectorForFeatureWithoutCenterline() {
        let hole = Hole(number: 1, par: 4, features: [3])
        XCTAssertNil(hole.vector(for: 3, from: features))
    }

    func testVectorForFeatureWithMissingCenterlineFeature() {
        let hole = Hole(number: 1, par: 4, features: [3], centerline: 999)
        XCTAssertNil(hole.vector(for: 3, from: features))
    }

    func testCenterlineFromFeatures() {
        let centerline = hole1.centerline(from: features)
        XCTAssertEqual(centerline?.id, 9)
        XCTAssertEqual(centerline?.type, .centerline)
        XCTAssertEqual(centerline?.polygon.count, 3)
    }

    func testCenterlineFromFeaturesWhenNoCenterline() {
        XCTAssertNil(hole2.centerline(from: features))
        XCTAssertNil(Hole(number: 1, par: 4, centerline: 999).centerline(from: features))
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
        let inside = Coordinate(lat: 39.937, lon: -105.030)
        XCTAssertTrue(hole1.onFairway(inside, from: features))
    }

    func testOnFairwayOutside() {
        // Point well outside
        let outside = Coordinate(lat: 39.900, lon: -105.000)
        XCTAssertFalse(hole1.onFairway(outside, from: features))
    }

    func testOnGreen() {
        // Point inside the green polygon
        let inside = Coordinate(lat: 39.9405, lon: -105.0295)
        XCTAssertTrue(hole1.onGreen(inside, from: features))
    }

    func testOnGreenOutside() {
        let outside = Coordinate(lat: 39.900, lon: -105.000)
        XCTAssertFalse(hole1.onGreen(outside, from: features))
    }
}

// MARK: - Feature Helper Tests

final class FeatureHelperTests: XCTestCase {
    func testCenter() {
        let green = features[2] // id: 3, green
        let c = green.center
        XCTAssertEqual(c.lat, 39.9405, accuracy: 0.001)
        XCTAssertEqual(c.lon, -105.0295, accuracy: 0.001)
    }

    func testFrontAndBack() {
        let green = features[2] // id: 3, green
        // Vector pointing north (positive latitude)
        let northVector = Vector2D(dx: 1, dy: 0)
        let front = green.front(vector: northVector)
        let back = green.back(vector: northVector)

        // Front should be the southern vertices (lower latitude)
        XCTAssertEqual(front.lat, 39.940, accuracy: 1e-6)
        // Back should be the northern vertices (higher latitude)
        XCTAssertEqual(back.lat, 39.941, accuracy: 1e-6)
    }

    func testFrontAndBackWithEastVector() {
        let green = features[2]
        // Vector pointing east (positive longitude)
        let eastVector = Vector2D(dx: 0, dy: 1)
        let front = green.front(vector: eastVector)
        let back = green.back(vector: eastVector)

        // Front should be the western edge (more negative longitude)
        XCTAssertEqual(front.lon, -105.030, accuracy: 1e-6)
        // Back should be the eastern edge (less negative longitude)
        XCTAssertEqual(back.lon, -105.029, accuracy: 1e-6)
    }

    func testFrontAndBackEmptyPolygon() {
        let empty = Feature(id: 99, type: .green, polygon: [])
        let v = Vector2D(dx: 1, dy: 0)
        XCTAssertEqual(empty.front(vector: v).lat, 0)
        XCTAssertEqual(empty.back(vector: v).lat, 0)
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
        let start = Coordinate(lat: 0, lon: 0)
        let end = Coordinate(lat: 10, lon: 0)
        let point = Coordinate(lat: 5, lon: 0)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 0, accuracy: 1e-10)
    }

    func testPointPerpendicularToSegment() {
        let start = Coordinate(lat: 0, lon: 0)
        let end = Coordinate(lat: 10, lon: 0)
        let point = Coordinate(lat: 5, lon: 3)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 9, accuracy: 1e-10)
    }

    func testPointBeyondSegmentEnd() {
        let start = Coordinate(lat: 0, lon: 0)
        let end = Coordinate(lat: 10, lon: 0)
        let point = Coordinate(lat: 15, lon: 0)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 25, accuracy: 1e-10)
    }

    func testPointBeforeSegmentStart() {
        let start = Coordinate(lat: 0, lon: 0)
        let end = Coordinate(lat: 10, lon: 0)
        let point = Coordinate(lat: -3, lon: 4)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: start, segEnd: end)
        XCTAssertEqual(distSq, 25, accuracy: 1e-10)
    }

    func testDegenerateSegment() {
        let point = Coordinate(lat: 0, lon: 0)
        let seg = Coordinate(lat: 3, lon: 4)
        let distSq = PolygonGeometry.squaredDistanceToSegment(point, segStart: seg, segEnd: seg)
        XCTAssertEqual(distSq, 25, accuracy: 1e-10)
    }
}
