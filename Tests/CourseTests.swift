import XCTest
import CourseDataSwift

final class CourseTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let course = Course(
            name: "The Broadlands Golf Course",
            location: CourseLocation(
                address: "4380 W 144th Ave",
                city: "Broomfield",
                state: "CO",
                country: "US",
                coordinate: Coordinate(lat: 39.9397, lon: -105.0267)
            ),
            tees: [
                TeeDefinition(name: "Black", color: "#000000"),
                TeeDefinition(name: "Gold", color: "#FFD700")
            ],
            features: [
                Feature(id: 1, type: .tee, polygon: [
                    Coordinate(lat: 39.9401, lon: -105.0271),
                    Coordinate(lat: 39.9402, lon: -105.0272),
                    Coordinate(lat: 39.9401, lon: -105.0273)
                ]),
                Feature(id: 2, type: .fairway, polygon: [
                    Coordinate(lat: 39.939, lon: -105.026),
                    Coordinate(lat: 39.938, lon: -105.025)
                ])
            ],
            subCourses: [
                SubCourse(
                    name: "Front",
                    holes: [
                        Hole(number: 1, par: 4, maleHandicap: 13,
                             yardages: ["Black": 401],
                             features: [1, 2])
                    ],
                    tees: ["Black": SubCourseTee(male: TeeInformation(rating: 37.6, slope: 134))]
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(course)
        let decoded = try JSONDecoder().decode(Course.self, from: data)

        XCTAssertEqual(course.id, decoded.id)
        XCTAssertEqual(course.name, decoded.name)
        XCTAssertEqual(course.location.city, "Broomfield")
        XCTAssertEqual(course.tees.count, 2)
        XCTAssertEqual(course.features.count, 2)
        XCTAssertEqual(course.features[0].type, .tee)
        XCTAssertEqual(course.features[1].type, .fairway)
        XCTAssertEqual(course.subCourses.count, 1)
        XCTAssertEqual(course.subCourses[0].holes[0].features, [1, 2])
        XCTAssertEqual(course.subCourses[0].tees["Black"]?.male?.rating, 37.6)
    }

    func testGolfCourseAPIIdsAreStringsInJSON() throws {
        let course = Course(
            name: "Test Course",
            golfCourseAPIIds: ["19198", "abc-123"],
            location: CourseLocation(address: "", city: "", state: "", country: "", coordinate: Coordinate(lat: 0, lon: 0))
        )
        let data = try JSONEncoder().encode(course)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["golfCourseAPIIds"] as? [String], ["19198", "abc-123"])

        let decoded = try JSONDecoder().decode(Course.self, from: data)
        XCTAssertEqual(decoded.golfCourseAPIIds, ["19198", "abc-123"])
    }

    func testOSMIDRoundTrip() throws {
        let course = Course(
            name: "Test Course",
            osmID: "w123456789",
            location: CourseLocation(address: "", city: "", state: "", country: "", coordinate: Coordinate(lat: 0, lon: 0))
        )
        let data = try JSONEncoder().encode(course)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["osmID"] as? String, "w123456789")

        let decoded = try JSONDecoder().decode(Course.self, from: data)
        XCTAssertEqual(decoded.osmID, "w123456789")
    }

    func testCourseWithoutOSMID() throws {
        let course = Course(
            name: "Test Course",
            location: CourseLocation(address: "", city: "", state: "", country: "", coordinate: Coordinate(lat: 0, lon: 0))
        )
        let data = try JSONEncoder().encode(course)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNil(json["osmID"])

        let decoded = try JSONDecoder().decode(Course.self, from: data)
        XCTAssertNil(decoded.osmID)
    }

    func testComboTeesRoundTrip() throws {
        let course = Course(
            name: "Test Course",
            location: CourseLocation(address: "", city: "", state: "", country: "", coordinate: Coordinate(lat: 0, lon: 0)),
            tees: [
                TeeDefinition(name: "Blue", color: "#0000FF"),
                TeeDefinition(name: "White", color: "#FFFFFF")
            ],
            comboTees: [ComboTeeDefinition(name: "Blue/White", tees: ["Blue", "White"])],
            subCourses: [
                SubCourse(
                    name: "Front",
                    holes: [
                        Hole(number: 1, par: 4, yardages: ["Blue": 410, "White": 385], comboTees: ["Blue/White": "Blue"]),
                        Hole(number: 2, par: 3, yardages: ["Blue": 180, "White": 165], comboTees: ["Blue/White": "White"])
                    ],
                    comboTees: ["Blue/White": SubCourseTee(male: TeeInformation(rating: 34.6, slope: 125))]
                )
            ]
        )

        let data = try JSONEncoder().encode(course)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let comboJSON = json["comboTees"] as! [[String: Any]]
        XCTAssertNil(comboJSON[0]["id"])
        XCTAssertEqual(comboJSON[0]["name"] as? String, "Blue/White")
        XCTAssertEqual(comboJSON[0]["tees"] as? [String], ["Blue", "White"])

        let decoded = try JSONDecoder().decode(Course.self, from: data)
        XCTAssertEqual(decoded, course)
        XCTAssertEqual(decoded.subCourses[0].holes[1].comboTees["Blue/White"], "White")
        XCTAssertEqual(decoded.subCourses[0].comboTees["Blue/White"]?.male?.slope, 125)
    }

    func testLocationJSONFormat() throws {
        let location = CourseLocation(
            address: "4380 W 144th Ave",
            city: "Broomfield",
            state: "CO",
            country: "US",
            coordinate: Coordinate(lat: 39.9397, lon: -105.0267)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(location), as: UTF8.self)
        XCTAssertEqual(
            json,
            #"{"address":"4380 W 144th Ave","city":"Broomfield","coordinate":{"lat":39.9397,"lon":-105.0267},"country":"US","state":"CO"}"#
        )
    }

    func testTeeDefinitionHasNoIdInJSON() throws {
        let tee = TeeDefinition(name: "Blue", color: "#0000FF")
        let data = try JSONEncoder().encode(tee)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNil(json["id"])
        XCTAssertEqual(json["name"] as? String, "Blue")
        XCTAssertEqual(json["color"] as? String, "#0000FF")
    }

    func testDefaultTeeColors() {
        XCTAssertEqual(TeeDefinition.defaultColor(for: "Black"), "#000000")
        XCTAssertEqual(TeeDefinition.defaultColor(for: "BLUE"), "#0000FF")
        XCTAssertEqual(TeeDefinition.defaultColor(for: "Red"), "#FF0000")
        XCTAssertEqual(TeeDefinition.defaultColor(for: "White"), "#FFFFFF")
        XCTAssertEqual(TeeDefinition.defaultColor(for: "Gold"), "#FFD700")
        XCTAssertEqual(TeeDefinition.defaultColor(for: "Silver"), "#C0C0C0")
        XCTAssertEqual(TeeDefinition.defaultColor(for: "Green"), "#008000")
        XCTAssertEqual(TeeDefinition.defaultColor(for: "Unknown"), "#808080")
    }

    func testEmptyCourse() {
        let course = Course(
            name: "Test Course",
            location: CourseLocation(
                address: "",
                city: "Denver",
                state: "CO",
                country: "",
                coordinate: Coordinate(lat: 39.0, lon: -105.0)
            )
        )
        XCTAssertTrue(course.tees.isEmpty)
        XCTAssertTrue(course.comboTees.isEmpty)
        XCTAssertTrue(course.features.isEmpty)
        XCTAssertTrue(course.subCourses.isEmpty)
    }

    func testNextFeatureID() {
        var course = Course(
            name: "Test",
            location: CourseLocation(address: "", city: "", state: "", country: "", coordinate: Coordinate(lat: 0, lon: 0)),
            features: [
                Feature(id: 1, type: .fairway, polygon: []),
                Feature(id: 5, type: .green, polygon: []),
                Feature(id: 3, type: .bunker, polygon: [])
            ]
        )
        XCTAssertEqual(course.nextFeatureID, 6)

        course.features = []
        XCTAssertEqual(course.nextFeatureID, 1)
    }
}
