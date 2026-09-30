import Foundation

public struct TeeInformation: Codable, Equatable, Hashable {
    public var rating: Double?
    public var slope: Int?
    public var totalYards: Int?
    public var parTotal: Int?

    public init(rating: Double? = nil, slope: Int? = nil, totalYards: Int? = nil, parTotal: Int? = nil) {
        self.rating = rating
        self.slope = slope
        self.totalYards = totalYards
        self.parTotal = parTotal
    }
}

public struct SubCourseTee: Codable, Equatable, Hashable {
    public var male: TeeInformation?
    public var female: TeeInformation?

    public init(male: TeeInformation? = nil, female: TeeInformation? = nil) {
        self.male = male
        self.female = female
    }
}

public struct SubCourse: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var holes: [Hole]
    public var tees: [String: SubCourseTee]
    public var comboTees: [String: SubCourseTee]

    public init(
        id: UUID = UUID(),
        name: String,
        holes: [Hole] = [],
        tees: [String: SubCourseTee] = [:],
        comboTees: [String: SubCourseTee] = [:]
    ) {
        self.id = id
        self.name = name
        self.holes = holes
        self.tees = tees
        self.comboTees = comboTees
    }

    enum CodingKeys: String, CodingKey {
        case id, name, holes, tees, comboTees
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        holes = try container.decode([Hole].self, forKey: .holes)
        tees = try container.decode([String: SubCourseTee].self, forKey: .tees)
        // Older course JSON does not have comboTees
        comboTees = try container.decodeIfPresent([String: SubCourseTee].self, forKey: .comboTees) ?? [:]
    }
}

public struct TeeDefinition: Codable, Equatable, Hashable, Identifiable {
    public var id: String { name }
    public var name: String
    public var color: String

    public init(name: String, color: String) {
        self.name = name
        self.color = color
    }

    enum CodingKeys: String, CodingKey {
        case name, color
    }

    public static func defaultColor(for teeName: String) -> String {
        switch teeName.lowercased() {
        case "black": "#000000"
        case "gold": "#FFD700"
        case "blue": "#0000FF"
        case "white": "#FFFFFF"
        case "silver": "#C0C0C0"
        case "red": "#FF0000"
        case "green": "#008000"
        default: "#808080"
        }
    }
}

public struct ComboTeeDefinition: Codable, Equatable, Hashable, Identifiable {
    public var id: String { name }
    public var name: String
    public var tees: [String]

    public init(name: String, tees: [String]) {
        self.name = name
        self.tees = tees
    }

    enum CodingKeys: String, CodingKey {
        case name, tees
    }
}

public struct CourseLocation: Codable, Equatable, Hashable {
    public var address: String
    public var city: String
    public var state: String
    public var country: String
    public var coordinate: Coordinate

    enum CodingKeys: String, CodingKey {
        case address, city, state, country
        case coordinate = "coordinates"
    }

    public init(address: String, city: String, state: String, country: String, coordinate: Coordinate) {
        self.address = address
        self.city = city
        self.state = state
        self.country = country
        self.coordinate = coordinate
    }

    /// Returns "City, State" when state is present, or just "City" when state is empty.
    public var cityStateDisplay: String {
        if state.isEmpty {
            return city
        }
        return "\(city), \(state)"
    }
}

public struct Course: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var clubName: String
    public var golfCourseAPIIds: [String]
    public var location: CourseLocation
    public var tees: [TeeDefinition]
    public var comboTees: [ComboTeeDefinition]
    public var features: [Feature]
    public var subCourses: [SubCourse]

    public var nextFeatureID: Int {
        (features.map(\.id).max() ?? 0) + 1
    }

    public init(
        id: UUID = UUID(),
        name: String,
        clubName: String = "",
        golfCourseAPIIds: [String] = [],
        location: CourseLocation,
        tees: [TeeDefinition] = [],
        comboTees: [ComboTeeDefinition] = [],
        features: [Feature] = [],
        subCourses: [SubCourse] = []
    ) {
        self.id = id
        self.name = name
        self.clubName = clubName
        self.golfCourseAPIIds = golfCourseAPIIds
        self.location = location
        self.tees = tees
        self.comboTees = comboTees
        self.features = features
        self.subCourses = subCourses
    }

    enum CodingKeys: String, CodingKey {
        case id, name, clubName, golfCourseAPIIds, location, tees, comboTees, features, subCourses
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        clubName = try container.decode(String.self, forKey: .clubName)
        golfCourseAPIIds = try container.decode([String].self, forKey: .golfCourseAPIIds)
        location = try container.decode(CourseLocation.self, forKey: .location)
        tees = try container.decode([TeeDefinition].self, forKey: .tees)
        // Older course JSON does not have comboTees
        comboTees = try container.decodeIfPresent([ComboTeeDefinition].self, forKey: .comboTees) ?? []
        features = try container.decode([Feature].self, forKey: .features)
        subCourses = try container.decode([SubCourse].self, forKey: .subCourses)
    }

    /// Finds a feature by its unique integer identifier.
    ///
    /// - Parameter id: The feature ID to search for.
    /// - Returns: The matching ``Feature``, or `nil` if no feature has that ID.
    public func findFeature(id: Int) -> Feature? {
        features.first { $0.id == id }
    }

    /// Returns all features that belong to the given hole.
    ///
    /// Resolves the hole's `features` ID list against this course's ``features`` array.
    ///
    /// - Parameter hole: The hole whose features should be resolved.
    /// - Returns: An array of ``Feature`` objects whose IDs appear in `hole.features`,
    ///   in the same order they appear in the course's features array.
    public func features(for hole: Hole) -> [Feature] {
        let ids = Set(hole.features)
        return features.filter { ids.contains($0.id) }
    }

    /// Looks up a hole by sub-course index and hole number.
    ///
    /// - Parameters:
    ///   - subCourseIndex: Zero-based index into ``subCourses``.
    ///   - number: The hole's ``Hole/number`` property (1-based).
    /// - Returns: The matching ``Hole``, or `nil` if the sub-course index is out of bounds
    ///   or no hole in that sub-course has the given number.
    public func hole(subCourseIndex: Int, number: Int) -> Hole? {
        guard subCourses.indices.contains(subCourseIndex) else { return nil }
        return subCourses[subCourseIndex].holes.first { $0.number == number }
    }

    /// Looks up a hole using raw zero-based array indices.
    ///
    /// - Parameters:
    ///   - subCourse: Zero-based index into ``subCourses``.
    ///   - hole: Zero-based index into the sub-course's ``SubCourse/holes`` array.
    /// - Returns: The ``Hole`` at that position, or `nil` if either index is out of bounds.
    public func holeFromIndices(subCourse: Int, hole: Int) -> Hole? {
        guard subCourses.indices.contains(subCourse) else { return nil }
        let holes = subCourses[subCourse].holes
        guard holes.indices.contains(hole) else { return nil }
        return holes[hole]
    }
}
