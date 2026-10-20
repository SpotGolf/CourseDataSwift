import Foundation
import CoreLocation

/// A geographic point. The short property names keep encoded data small, and they double as
/// the JSON keys: `{"lat": 39.7879, "lon": -74.958, "ele": 12.25}`. SwiftData requires each
/// JSON key to match its property name.
public struct Coordinate: Codable, Hashable, Sendable {
    /// The latitude, in degrees.
    public var lat: Double

    /// The longitude, in degrees.
    public var lon: Double

    /// The elevation above mean sea level, in meters, or `nil` if unknown.
    public var ele: Double?

    public init(lat: Double, lon: Double, ele: Double? = nil) {
        self.lat = lat
        self.lon = lon
        self.ele = ele
    }

    public init(_ clCoordinate: CLLocationCoordinate2D, ele: Double? = nil) {
        self.lat = clCoordinate.latitude
        self.lon = clCoordinate.longitude
        self.ele = ele
    }

    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// A `CLLocation` for this coordinate. The altitude is set only when ``ele`` is known;
    /// otherwise the location's `verticalAccuracy` is negative (invalid altitude).
    public var clLocation: CLLocation {
        guard let ele else {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return CLLocation(
            coordinate: clCoordinate,
            altitude: ele,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date()
        )
    }
}
