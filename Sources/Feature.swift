import Foundation

public enum FeatureType: String, Codable, CaseIterable, Hashable {
    case fairway
    case green
    case tee
    case bunker
    case water
    case rough
}

public struct Feature: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public let type: FeatureType
    public var polygon: [Coordinate]

    public init(id: Int, type: FeatureType, polygon: [Coordinate]) {
        self.id = id
        self.type = type
        self.polygon = polygon
    }

    /// The centroid of this feature's polygon.
    ///
    /// Computed using the shoelace-formula centroid from ``PolygonGeometry/centroid(of:)``.
    /// For degenerate polygons (empty or collinear points), falls back to the arithmetic
    /// mean of the vertices.
    public var center: Coordinate {
        PolygonGeometry.centroid(of: polygon)
    }

    /// The centroid of this feature's polygon.
    ///
    /// Equivalent to ``center``. Provided for readability alongside ``front(vector:)``
    /// and ``back(vector:)``.
    public func middle() -> Coordinate {
        center
    }

    /// Returns the polygon vertex closest to the origin of play.
    ///
    /// Projects all polygon vertices onto the given direction vector using a dot product
    /// and returns the vertex with the smallest projection — i.e., the point nearest to
    /// where the ball is coming from.
    ///
    /// Uses a flat-earth approximation (raw latitude/longitude as Cartesian coordinates).
    /// At the scale of golf course features this is accurate to within centimeters.
    ///
    /// - Parameter vector: The direction of play, typically obtained from
    ///   ``Hole/vector(for:from:)``.
    /// - Returns: The polygon vertex that is the "front" of the feature relative to
    ///   the direction of play. Returns `(0, 0)` if the polygon is empty.
    public func front(vector: Vector2D) -> Coordinate {
        guard !polygon.isEmpty else {
            return Coordinate(latitude: 0, longitude: 0)
        }
        return polygon.min(by: {
            ($0.latitude * vector.dx + $0.longitude * vector.dy) <
            ($1.latitude * vector.dx + $1.longitude * vector.dy)
        })!
    }

    /// Returns the polygon vertex farthest along the direction of play.
    ///
    /// Projects all polygon vertices onto the given direction vector using a dot product
    /// and returns the vertex with the largest projection — i.e., the point farthest
    /// from where the ball is coming from.
    ///
    /// Uses a flat-earth approximation (raw latitude/longitude as Cartesian coordinates).
    /// At the scale of golf course features this is accurate to within centimeters.
    ///
    /// - Parameter vector: The direction of play, typically obtained from
    ///   ``Hole/vector(for:from:)``.
    /// - Returns: The polygon vertex that is the "back" of the feature relative to
    ///   the direction of play. Returns `(0, 0)` if the polygon is empty.
    public func back(vector: Vector2D) -> Coordinate {
        guard !polygon.isEmpty else {
            return Coordinate(latitude: 0, longitude: 0)
        }
        return polygon.max(by: {
            ($0.latitude * vector.dx + $0.longitude * vector.dy) <
            ($1.latitude * vector.dx + $1.longitude * vector.dy)
        })!
    }
}
