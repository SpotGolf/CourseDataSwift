import Foundation
import CoreLocation

public struct Coordinate: Equatable, Hashable {
    public var latitude: Double
    public var longitude: Double

    /// The elevation above mean sea level, in meters, or `nil` if unknown.
    public var elevation: Double?

    public init(latitude: Double, longitude: Double, elevation: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }

    public init(_ clCoordinate: CLLocationCoordinate2D, elevation: Double? = nil) {
        self.latitude = clCoordinate.latitude
        self.longitude = clCoordinate.longitude
        self.elevation = elevation
    }

    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// A `CLLocation` for this coordinate. The altitude is set only when ``elevation`` is known;
    /// otherwise the location's `verticalAccuracy` is negative (invalid altitude).
    public var clLocation: CLLocation {
        guard let elevation else {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        return CLLocation(
            coordinate: clCoordinate,
            altitude: elevation,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date()
        )
    }
}

/// Encoded as a compact JSON array: `[latitude, longitude]`, or
/// `[latitude, longitude, elevation]` when the elevation is known.
extension Coordinate: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        latitude = try container.decode(Double.self)
        longitude = try container.decode(Double.self)
        elevation = try container.decodeIfPresent(Double.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
        if let elevation {
            try container.encode(elevation)
        }
    }
}
