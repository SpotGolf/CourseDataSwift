import Foundation

/// A two-dimensional direction vector used for projecting golf course features
/// relative to the direction of play along a hole's centerline.
///
/// `Vector2D` is not a geographic coordinate — it represents a direction in flat
/// latitude/longitude space. This is suitable for the small distances involved
/// in golf course geometry.
public struct Vector2D: Equatable, Hashable, Sendable {
    /// The latitude component of the direction vector.
    public var dx: Double

    /// The longitude component of the direction vector.
    public var dy: Double

    /// Creates a new direction vector with the given components.
    ///
    /// - Parameters:
    ///   - dx: The latitude component.
    ///   - dy: The longitude component.
    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }

    /// Returns a unit vector pointing in the same direction.
    ///
    /// If the vector has zero magnitude, returns a zero vector.
    public func normalized() -> Vector2D {
        let magnitude = sqrt(dx * dx + dy * dy)
        guard magnitude > 1e-10 else {
            return Vector2D(dx: 0, dy: 0)
        }
        return Vector2D(dx: dx / magnitude, dy: dy / magnitude)
    }
}
