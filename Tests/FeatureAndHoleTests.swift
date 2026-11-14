import XCTest
import CourseDataSwift

final class FeatureTests: XCTestCase {
    func testPolygonFeatureCodableRoundTrip() throws {
        let feature = Feature(
            id: 1,
            type: .fairway,
            polygon: [
                Coordinate(lat: 39.788, lon: -74.958),
                Coordinate(lat: 39.787, lon: -74.957),
                Coordinate(lat: 39.786, lon: -74.956),
                Coordinate(lat: 39.787, lon: -74.959)
            ]
        )
        let data = try JSONEncoder().encode(feature)
        let decoded = try JSONDecoder().decode(Feature.self, from: data)
        XCTAssertEqual(feature, decoded)
        XCTAssertEqual(decoded.id, 1)
        XCTAssertEqual(decoded.type, .fairway)
        XCTAssertEqual(decoded.polygon.count, 4)
    }

    func testAllFeatureTypes() throws {
        for type in FeatureType.allCases {
            let feature = Feature(
                id: 1,
                type: type,
                polygon: [Coordinate(lat: 0, lon: 0)]
            )
            let data = try JSONEncoder().encode(feature)
            let decoded = try JSONDecoder().decode(Feature.self, from: data)
            XCTAssertEqual(decoded.type, type)
        }
    }

    func testFeatureJSONFormat() throws {
        let feature = Feature(
            id: 42,
            type: .bunker,
            polygon: [
                Coordinate(lat: 39.0, lon: -105.0),
                Coordinate(lat: 39.1, lon: -105.1)
            ]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(feature)
        XCTAssertEqual(
            String(decoding: data, as: UTF8.self),
            #"{"id":42,"polygon":{"values":[14235000,-38325000,null,36500,-36500,null]},"type":"bunker"}"#
        )
    }

    func testFeatureJSONFormatWithOSMID() throws {
        let feature = Feature(
            id: 42,
            type: .centerline,
            polygon: [Coordinate(lat: 39.0, lon: -105.0)],
            osmID: "w123456789"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(feature)
        XCTAssertEqual(
            String(decoding: data, as: UTF8.self),
            #"{"id":42,"osmID":"w123456789","polygon":{"values":[14235000,-38325000,null]},"type":"centerline"}"#
        )
        XCTAssertEqual(try JSONDecoder().decode(Feature.self, from: data), feature)
    }

    func testFeatureWithoutOSMIDDecodes() throws {
        let json = #"{"id":1,"polygon":{"values":[]},"type":"green"}"#
        let feature = try JSONDecoder().decode(Feature.self, from: Data(json.utf8))
        XCTAssertNil(feature.osmID)
    }

    func testFeatureWithSurfaceRoundTrip() throws {
        let surface = ElevationSurface(
            origin: Coordinate(lat: 39.0, lon: -105.0),
            columns: 2,
            elevations: [nil, 1600.12, 1600.15, 1600.09]
        )
        let feature = Feature(
            id: 7,
            type: .green,
            polygon: [Coordinate(lat: 39.0, lon: -105.0)],
            surface: surface
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(feature)
        XCTAssertEqual(
            String(decoding: data, as: UTF8.self),
            #"{"id":7,"polygon":{"values":[14235000,-38325000,null]},"surface":{"columns":2,"elevations":[null,160012,3,-6],"origin":{"lat":39,"lon":-105},"spacing":1},"type":"green"}"#
        )
        let decoded = try JSONDecoder().decode(Feature.self, from: data)
        XCTAssertEqual(decoded, feature)
        XCTAssertEqual(decoded.surface, surface)
    }

    func testFeatureWithoutSurfaceDecodes() throws {
        let json = #"{"id":1,"osmID":"w1","polygon":{"values":[]},"type":"green"}"#
        let feature = try JSONDecoder().decode(Feature.self, from: Data(json.utf8))
        XCTAssertNil(feature.surface)
    }

    func testFeatureWithoutSurfaceLeavesItOutOfJSON() throws {
        let feature = Feature(id: 1, type: .green, polygon: [])
        let data = try JSONEncoder().encode(feature)
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("surface"))
    }
}

final class HoleTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let hole = Hole(
            number: 1,
            par: 4,
            maleHandicap: 13,
            yardages: ["Black": 401, "Gold": 378],
            features: [1, 2, 3],
            centerline: 4
        )
        let data = try JSONEncoder().encode(hole)
        let decoded = try JSONDecoder().decode(Hole.self, from: data)
        XCTAssertEqual(hole, decoded)
        XCTAssertEqual(decoded.number, 1)
        XCTAssertEqual(decoded.par, 4)
        XCTAssertEqual(decoded.features, [1, 2, 3])
        XCTAssertEqual(decoded.centerline, 4)
    }

    func testCodableWithoutCenterline() throws {
        let data = try JSONEncoder().encode(Hole(number: 1, par: 4))
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("centerline"))
        XCTAssertNil(try JSONDecoder().decode(Hole.self, from: data).centerline)
    }

    func testRenumbered() {
        let hole = Hole(
            number: 7,
            par: 5,
            maleHandicap: 3,
            femaleHandicap: 5,
            yardages: ["Blue": 545],
            features: [10, 11],
            comboTees: ["Blue/White": "Blue"],
            centerline: 12
        )
        let renumbered = hole.renumbered(to: 1)
        XCTAssertEqual(renumbered.number, 1)
        XCTAssertEqual(renumbered.par, 5)
        XCTAssertEqual(renumbered.maleHandicap, 3)
        XCTAssertEqual(renumbered.femaleHandicap, 5)
        XCTAssertEqual(renumbered.yardages["Blue"], 545)
        XCTAssertEqual(renumbered.features, [10, 11])
        XCTAssertEqual(renumbered.comboTees, ["Blue/White": "Blue"])
        XCTAssertEqual(renumbered.centerline, 12)
        XCTAssertEqual(renumbered.id, 1)
    }

    func testEmptyHole() {
        let hole = Hole(number: 5, par: 3, maleHandicap: 7)
        XCTAssertTrue(hole.yardages.isEmpty)
        XCTAssertTrue(hole.features.isEmpty)
        XCTAssertNil(hole.centerline)
    }

    func testSplitIntoSubCourses18Holes() {
        let holes = (1...18).map { Hole(number: $0, par: $0 <= 9 ? 4 : 5) }
        let groups = Hole.splitIntoSubCourses(holes, names: ["Front", "Back"])
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].name, "Front")
        XCTAssertEqual(groups[0].holes.count, 9)
        XCTAssertEqual(groups[0].holes[0].number, 1)
        XCTAssertEqual(groups[0].holes[0].par, 4)
        XCTAssertEqual(groups[1].name, "Back")
        XCTAssertEqual(groups[1].holes.count, 9)
        XCTAssertEqual(groups[1].holes[0].number, 1)
        XCTAssertEqual(groups[1].holes[0].par, 5)
    }

    func testSplitIntoSubCourses9Holes() {
        let holes = (1...9).map { Hole(number: $0, par: 4) }
        let groups = Hole.splitIntoSubCourses(holes, names: ["Front", "Back"])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].name, "Front")
        XCTAssertEqual(groups[0].holes.count, 9)
    }

    func testSplitIntoSubCourses27HolesThreeNames() {
        let holes = (1...27).map { Hole(number: $0, par: 4) }
        let groups = Hole.splitIntoSubCourses(holes, names: ["Eldorado", "Vista", "Conquistador"])
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].name, "Eldorado")
        XCTAssertEqual(groups[0].holes.count, 9)
        XCTAssertEqual(groups[1].name, "Vista")
        XCTAssertEqual(groups[1].holes.count, 9)
        XCTAssertEqual(groups[2].name, "Conquistador")
        XCTAssertEqual(groups[2].holes.count, 9)
        XCTAssertEqual(groups[2].holes[0].number, 1)
        XCTAssertEqual(groups[2].holes[8].number, 9)
    }
}
