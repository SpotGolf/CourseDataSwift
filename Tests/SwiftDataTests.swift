import XCTest
import SwiftData
import CourseDataSwift

@Model final class CoordinateRecord {
    var coordinate: Coordinate
    init(_ coordinate: Coordinate) { self.coordinate = coordinate }
}

@Model final class LocationRecord {
    var location: CourseLocation
    init(_ location: CourseLocation) { self.location = location }
}

@Model final class PathRecord {
    var path: CoordinatePath
    init(_ path: CoordinatePath) { self.path = path }
}

@Model final class HoleRecord {
    var hole: Hole
    init(_ hole: Hole) { self.hole = hole }
}

@Model final class FeaturesRecord {
    var features: [Feature]
    init(_ features: [Feature]) { self.features = features }
}

@Model final class CourseRecord {
    var course: Course
    init(_ course: Course) { self.course = course }
}

/// Saves each type in a SwiftData store on disk, then reads it back with a new container.
final class SwiftDataTests: XCTestCase {
    private let path = CoordinatePath([
        Coordinate(lat: 39.9401, lon: -105.0271, ele: 1600.25),
        Coordinate(lat: 39.9402, lon: -105.0272),
        Coordinate(lat: 39.9401, lon: -105.0273, ele: 1600.75)
    ])

    private let location = CourseLocation(
        address: "4380 W 144th Ave",
        city: "Broomfield",
        state: "CO",
        country: "US",
        coordinate: Coordinate(lat: 39.9397, lon: -105.0267, ele: 1600.5)
    )

    private var hole: Hole {
        Hole(number: 1, par: 4, yardages: ["Blue": 401], features: [1], tees: ["Blue": 1],
             comboTees: ["Blue/White": "Blue"], centerline: path)
    }

    private var storeURL: URL!

    override func setUp() {
        storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).store")
    }

    override func tearDown() {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
    }

    private func saveAndFetch<T: PersistentModel>(_ record: T) throws -> T? {
        let schema = Schema([T.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let context = ModelContext(try ModelContainer(for: schema, configurations: configuration))
        context.insert(record)
        try context.save()

        let freshContext = ModelContext(try ModelContainer(for: schema, configurations: configuration))
        return try freshContext.fetch(FetchDescriptor<T>()).first
    }

    func testCoordinate() throws {
        let coordinate = Coordinate(lat: 39.9397, lon: -105.0267, ele: 1600.5)
        XCTAssertEqual(try saveAndFetch(CoordinateRecord(coordinate))?.coordinate, coordinate)
    }

    func testCoordinateWithoutElevation() throws {
        let coordinate = Coordinate(lat: 39.9397, lon: -105.0267)
        XCTAssertEqual(try saveAndFetch(CoordinateRecord(coordinate))?.coordinate, coordinate)
    }

    func testCourseLocation() throws {
        XCTAssertEqual(try saveAndFetch(LocationRecord(location))?.location, location)
    }

    func testCoordinatePath() throws {
        XCTAssertEqual(try saveAndFetch(PathRecord(path))?.path, path)
    }

    func testHole() throws {
        XCTAssertEqual(try saveAndFetch(HoleRecord(hole))?.hole, hole)
    }

    func testFeatures() throws {
        let features = [Feature(id: 1, type: .green, polygon: path), Feature(id: 2, type: .bunker, polygon: [])]
        XCTAssertEqual(try saveAndFetch(FeaturesRecord(features))?.features, features)
    }

    func testCourse() throws {
        let course = Course(
            name: "The Broadlands Golf Course",
            clubName: "Broadlands",
            golfCourseAPIIds: ["19198"],
            location: location,
            tees: [TeeDefinition(name: "Blue", color: "#0000FF")],
            comboTees: [ComboTeeDefinition(name: "Blue/White", tees: ["Blue", "White"])],
            features: [Feature(id: 1, type: .green, polygon: path)],
            subCourses: [
                SubCourse(
                    name: "Front",
                    holes: [hole],
                    tees: ["Blue": SubCourseTee(male: TeeInformation(rating: 37.6, slope: 134))],
                    comboTees: ["Blue/White": SubCourseTee(female: TeeInformation(totalYards: 3100))]
                )
            ]
        )
        XCTAssertEqual(try saveAndFetch(CourseRecord(course))?.course, course)
    }
}
