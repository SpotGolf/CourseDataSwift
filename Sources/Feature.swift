import Foundation

public enum FeatureType: String, Codable, CaseIterable, Hashable, Sendable {
    case fairway
    case green
    case tee
    case bunker
    case water
    /// A hole's line of play from tee to green. Its ``Feature/polygon`` is an open line, not a
    /// closed shape.
    case centerline
}

public struct Feature: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let type: FeatureType
    /// The feature's points. A closed shape for most types, and an open line for
    /// ``FeatureType/centerline``.
    public var polygon: CoordinatePath
    /// The OpenStreetMap element this feature came from, in short form: `n`, `w`, or `r` for a
    /// node, way, or relation, followed by its ID, such as `w123456789`. `nil` when the feature
    /// is not in OpenStreetMap. Left out of the JSON when `nil`.
    public var osmID: String?

    public init(id: Int, type: FeatureType, polygon: CoordinatePath, osmID: String? = nil) {
        self.id = id
        self.type = type
        self.polygon = polygon
        self.osmID = osmID
    }

    /// The centroid of this feature's polygon.
    ///
    /// Computed using the shoelace-formula centroid from ``PolygonGeometry/centroid(of:)``.
    /// For degenerate polygons (empty or collinear points), falls back to the arithmetic
    /// mean of the vertices.
    public var center: Coordinate {
        PolygonGeometry.centroid(of: polygon)
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
            return Coordinate(lat: 0, lon: 0)
        }
        return polygon.min(by: {
            ($0.lat * vector.dx + $0.lon * vector.dy) <
            ($1.lat * vector.dx + $1.lon * vector.dy)
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
            return Coordinate(lat: 0, lon: 0)
        }
        return polygon.max(by: {
            ($0.lat * vector.dx + $0.lon * vector.dy) <
            ($1.lat * vector.dx + $1.lon * vector.dy)
        })!
    }
}
