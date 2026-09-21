import Foundation

public struct Hole: Identifiable, Codable, Equatable, Hashable {
    public var id: Int { number }
    public let number: Int
    public var par: Int
    public var maleHandicap: Int
    public var femaleHandicap: Int
    public var yardages: [String: Int]
    public var features: [Int]
    public var tees: [String: Int]
    public var centerline: [Coordinate]

    public init(
        number: Int,
        par: Int,
        maleHandicap: Int = 0,
        femaleHandicap: Int = 0,
        yardages: [String: Int] = [:],
        features: [Int] = [],
        tees: [String: Int] = [:],
        centerline: [Coordinate] = []
    ) {
        self.number = number
        self.par = par
        self.maleHandicap = maleHandicap
        self.femaleHandicap = femaleHandicap
        self.yardages = yardages
        self.features = features
        self.tees = tees
        self.centerline = centerline
    }

    public func renumbered(to newNumber: Int) -> Hole {
        Hole(
            number: newNumber,
            par: par,
            maleHandicap: maleHandicap,
            femaleHandicap: femaleHandicap,
            yardages: yardages,
            features: features,
            tees: tees,
            centerline: centerline
        )
    }

    /// Returns the green feature for this hole.
    ///
    /// Filters the provided features to those belonging to this hole and returns
    /// the first one with type ``FeatureType/green``.
    ///
    /// - Parameter features: The course's full ``Course/features`` array.
    /// - Returns: The green ``Feature``, or `nil` if this hole has no green.
    public func green(from features: [Feature]) -> Feature? {
        let ids = Set(self.features)
        return features.first { ids.contains($0.id) && $0.type == .green }
    }

    /// Determines the direction-of-play vector at a feature's location along this hole's centerline.
    ///
    /// Finds the centerline segment closest to the feature's centroid and returns that
    /// segment's direction as a unit ``Vector2D``. This handles doglegs correctly — a feature
    /// near the turn will use the segment direction at that part of the hole.
    ///
    /// - Parameters:
    ///   - featureID: The ID of the feature to compute the vector for. The feature does not
    ///     need to belong to this hole.
    ///   - features: The course's full ``Course/features`` array, used to resolve the feature ID.
    /// - Returns: A unit ``Vector2D`` representing the direction of play at the feature's location,
    ///   or `nil` if the feature can't be found or the centerline has fewer than 2 points.
    public func vector(for featureID: Int, from features: [Feature]) -> Vector2D? {
        guard centerline.count >= 2,
              let feature = features.first(where: { $0.id == featureID }),
              !feature.polygon.isEmpty else {
            return nil
        }

        let centroid = PolygonGeometry.centroid(of: feature.polygon)

        var bestDistSq = Double.infinity
        var bestIndex = 0
        for i in 0..<(centerline.count - 1) {
            let distSq = PolygonGeometry.squaredDistanceToSegment(centroid, segStart: centerline[i], segEnd: centerline[i + 1])
            if distSq < bestDistSq {
                bestDistSq = distSq
                bestIndex = i
            }
        }

        let dx = centerline[bestIndex + 1].latitude - centerline[bestIndex].latitude
        let dy = centerline[bestIndex + 1].longitude - centerline[bestIndex].longitude
        return Vector2D(dx: dx, dy: dy).normalized()
    }

    /// Tests whether a coordinate is on one of this hole's fairways.
    ///
    /// Filters the provided features to those belonging to this hole with type
    /// ``FeatureType/fairway``, then performs a point-in-polygon test for each.
    ///
    /// - Parameters:
    ///   - coordinate: The location to test.
    ///   - features: The course's full ``Course/features`` array.
    /// - Returns: `true` if `coordinate` is inside any of this hole's fairway polygons.
    public func onFairway(_ coordinate: Coordinate, from features: [Feature]) -> Bool {
        let ids = Set(self.features)
        return features.contains { feature in
            ids.contains(feature.id) && feature.type == .fairway && PolygonGeometry.contains(coordinate, in: feature.polygon)
        }
    }

    /// Tests whether a coordinate is on this hole's green.
    ///
    /// Filters the provided features to those belonging to this hole with type
    /// ``FeatureType/green``, then performs a point-in-polygon test.
    ///
    /// - Parameters:
    ///   - coordinate: The location to test.
    ///   - features: The course's full ``Course/features`` array.
    /// - Returns: `true` if `coordinate` is inside this hole's green polygon.
    public func onGreen(_ coordinate: Coordinate, from features: [Feature]) -> Bool {
        let ids = Set(self.features)
        return features.contains { feature in
            ids.contains(feature.id) && feature.type == .green && PolygonGeometry.contains(coordinate, in: feature.polygon)
        }
    }

    public static func splitIntoSubCourses(_ holes: [Hole], names: [String]) -> [(name: String, holes: [Hole])] {
        guard holes.count > 1, names.count >= 2, holes.count % names.count == 0 else {
            let renumbered = holes.enumerated().map { $1.renumbered(to: $0 + 1) }
            return [(names.first ?? "Front", renumbered)]
        }

        let groupSize = holes.count / names.count
        guard groupSize > 0 else {
            let renumbered = holes.enumerated().map { $1.renumbered(to: $0 + 1) }
            return [(names.first ?? "Front", renumbered)]
        }

        var groups: [(name: String, holes: [Hole])] = []
        for (i, name) in names.enumerated() {
            let start = i * groupSize
            let end = (i == names.count - 1) ? holes.count : start + groupSize
            let slice = Array(holes[start..<end])
            let renumbered = slice.enumerated().map { $1.renumbered(to: $0 + 1) }
            groups.append((name, renumbered))
        }
        return groups
    }
}
