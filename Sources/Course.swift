import Foundation

public struct TeeInformation: Codable, Hashable, Sendable {
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

public struct SubCourseTee: Codable, Hashable, Sendable {
    public var male: TeeInformation?
    public var female: TeeInformation?

    public init(male: TeeInformation? = nil, female: TeeInformation? = nil) {
        self.male = male
        self.female = female
    }

    /// The information for a gender, or `nil` if the tee has none for it.
    public func information(for gender: Gender) -> TeeInformation? {
        switch gender {
        case .male: male
        case .female: female
        }
    }
}

public struct SubCourse: Identifiable, Codable, Hashable, Sendable {
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
}

public struct TeeDefinition: Codable, Hashable, Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var color: String

    public init(name: String, color: String) {
        self.name = name
        self.color = color
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

public struct ComboTeeDefinition: Codable, Hashable, Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var tees: [String]

    public init(name: String, tees: [String]) {
        self.name = name
        self.tees = tees
    }
}

public struct CourseLocation: Codable, Hashable, Sendable {
    public var address: String
    public var city: String
    public var state: String
    public var country: String
    public var coordinate: Coordinate

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

public struct Course: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var clubName: String
    public var golfCourseAPIIds: [String]
    /// The OpenStreetMap `leisure=golf_course` element for this course, in short form: `n`, `w`,
    /// or `r` for a node, way, or relation, followed by its ID, such as `w123456789`. `nil` when
    /// the course is not in OpenStreetMap. Left out of the JSON when `nil`.
    public var osmID: String?
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
        osmID: String? = nil,
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
        self.osmID = osmID
        self.location = location
        self.tees = tees
        self.comboTees = comboTees
        self.features = features
        self.subCourses = subCourses
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

    /// The rating, slope, yards, and par of a round over the given sub-courses, from one tee.
    ///
    /// The values come from each sub-course's own ``TeeInformation``:
    ///
    /// - The rating is the sum of the sub-courses' ratings, to one decimal place.
    /// - The slope is the average of the sub-courses' slopes, with a half rounded up.
    /// - The yards and par are sums.
    ///
    /// The order of the sub-courses does not change the result, and a sub-course can be listed
    /// twice for a nine that is played twice.
    ///
    /// - Parameters:
    ///   - subCourseIndices: Zero-based indices into ``subCourses``, in the order played.
    ///   - tee: The name of a ``TeeDefinition`` or a ``ComboTeeDefinition``.
    ///   - gender: The gender whose values to use.
    /// - Returns: The values for the round. A value is `nil` when any sub-course lacks it. The
    ///   result is `nil` when no sub-courses are given, an index is out of bounds, or a
    ///   sub-course has nothing for the tee and gender.
    public func teeInformation(subCourseIndices: [Int], tee: String, gender: Gender) -> TeeInformation? {
        guard !subCourseIndices.isEmpty else { return nil }
        var parts: [TeeInformation] = []
        for index in subCourseIndices {
            guard subCourses.indices.contains(index) else { return nil }
            let subCourse = subCourses[index]
            guard let part = (subCourse.tees[tee] ?? subCourse.comboTees[tee])?.information(for: gender) else {
                return nil
            }
            parts.append(part)
        }

        func total<Value: AdditiveArithmetic>(_ value: (TeeInformation) -> Value?) -> Value? {
            var sum = Value.zero
            for part in parts {
                guard let value = value(part) else { return nil }
                sum += value
            }
            return sum
        }

        // Rounds to hundredths first so that a sum such as 36.05 + 36.05 gives 72.1, and a lone
        // 36.05 gives 36.1, whatever the binary form of the stored values.
        let rating = total(\.rating).map { sum in
            ((sum * 100).rounded() / 10).rounded(.toNearestOrAwayFromZero) / 10
        }
        let slope = total(\.slope).map { sum in
            Int((Double(sum) / Double(parts.count)).rounded(.toNearestOrAwayFromZero))
        }
        return TeeInformation(rating: rating, slope: slope, totalYards: total(\.totalYards), parTotal: total(\.parTotal))
    }

    /// The handicap of each hole in a round over the given sub-courses.
    ///
    /// A course with one or two sub-courses stores each hole's handicap as its scorecard prints
    /// it, so when the stored handicaps of the round's holes are the numbers 1 up to the number
    /// of holes, each used once, they are returned as stored. Playing the back nine first does
    /// not change them.
    ///
    /// In every other case the handicaps are worked out. This covers a course with three or more
    /// sub-courses, where any two can be played together, and also one nine played alone or
    /// twice. Each sub-course's holes are ranked from hardest to easiest by their stored handicap,
    /// and the ranks are dealt out across the sub-courses in the order played. With two
    /// sub-courses, the first gets the odd numbers and the second gets the even numbers.
    ///
    /// - Parameters:
    ///   - subCourseIndices: Zero-based indices into ``subCourses``, in the order played.
    ///   - gender: The gender whose handicaps to use.
    /// - Returns: One handicap per hole: each sub-course in the order played, and within a
    ///   sub-course by ``Hole/number``. Empty when no sub-courses are given, an index is out of
    ///   bounds, or any hole has no handicap for the gender.
    public func handicaps(subCourseIndices: [Int], gender: Gender) -> [Int] {
        var stored: [[Int]] = []
        for index in subCourseIndices {
            guard subCourses.indices.contains(index) else { return [] }
            let holes = subCourses[index].holes.sorted { $0.number < $1.number }
            let handicaps = holes.map { gender == .male ? $0.maleHandicap : $0.femaleHandicap }
            guard handicaps.allSatisfy({ $0 > 0 }) else { return [] }
            stored.append(handicaps)
        }

        let flat = stored.flatMap { $0 }
        guard !flat.isEmpty else { return [] }
        if subCourses.count <= 2, flat.sorted() == Array(1...flat.count) {
            return flat
        }

        let count = stored.count
        return stored.enumerated().flatMap { position, handicaps in
            // A hole's rank is one more than the number of holes in its sub-course that are
            // harder. Holes with the same stored handicap keep their hole order.
            handicaps.indices.map { hole in
                let harder = handicaps.indices.filter { other in
                    handicaps[other] < handicaps[hole] || (handicaps[other] == handicaps[hole] && other < hole)
                }
                return harder.count * count + position + 1
            }
        }
    }
}
