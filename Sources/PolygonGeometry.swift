import Foundation
import CoreLocation

public enum PolygonGeometry {
    /// Computes the centroid of a polygon in flat latitude/longitude space.
    ///
    /// The centroid's elevation is the mean of the vertex elevations when every vertex
    /// has one, and `nil` otherwise.
    public static func centroid(of polygon: some RandomAccessCollection<Coordinate>) -> Coordinate {
        guard !polygon.isEmpty else {
            return Coordinate(lat: 0, lon: 0)
        }
        let origin = polygon[polygon.startIndex]
        guard polygon.count > 1 else {
            return origin
        }

        let elevations = polygon.compactMap(\.ele)
        let elevation = elevations.count == polygon.count ? elevations.reduce(0, +) / Double(elevations.count) : nil

        // Translate relative to the first vertex to avoid catastrophic cancellation
        // in the shoelace formula when coordinates have large absolute values.
        var cx = 0.0, cy = 0.0, area = 0.0
        let n = polygon.count
        forEachEdge(of: polygon) { current, next in
            let xi = current.lat - origin.lat
            let yi = current.lon - origin.lon
            let xj = next.lat - origin.lat
            let yj = next.lon - origin.lon
            let cross = xi * yj - xj * yi
            area += cross
            cx += (xi + xj) * cross
            cy += (yi + yj) * cross
        }
        area /= 2.0
        guard abs(area) > 1e-20 else {
            let lat = polygon.map(\.lat).reduce(0, +) / Double(n)
            let lon = polygon.map(\.lon).reduce(0, +) / Double(n)
            return Coordinate(lat: lat, lon: lon, ele: elevation)
        }
        cx /= (6.0 * area)
        cy /= (6.0 * area)
        return Coordinate(lat: cx + origin.lat, lon: cy + origin.lon, ele: elevation)
    }

    public static func area(of polygon: some RandomAccessCollection<Coordinate>) -> Double {
        guard polygon.count >= 3 else { return 0 }
        var area = 0.0
        forEachEdge(of: polygon) { current, next in
            area += current.lat * next.lon
            area -= next.lat * current.lon
        }
        return abs(area / 2.0)
    }

    public static func nearestPoint(on polygon: some RandomAccessCollection<Coordinate>, to reference: Coordinate) -> Coordinate {
        guard !polygon.isEmpty else {
            return Coordinate(lat: 0, lon: 0)
        }
        let refLocation = reference.clLocation
        return polygon.min(by: {
            $0.clLocation.distance(from: refLocation) < $1.clLocation.distance(from: refLocation)
        })!
    }

    public static func farthestPoint(on polygon: some RandomAccessCollection<Coordinate>, to reference: Coordinate) -> Coordinate {
        guard !polygon.isEmpty else {
            return Coordinate(lat: 0, lon: 0)
        }
        let refLocation = reference.clLocation
        return polygon.max(by: {
            $0.clLocation.distance(from: refLocation) < $1.clLocation.distance(from: refLocation)
        })!
    }

    /// Computes the squared Euclidean distance from a point to a line segment in flat
    /// latitude/longitude space.
    ///
    /// Projects the point onto the infinite line defined by the segment, clamps the
    /// parameter to `[0, 1]`, and returns the squared distance to the clamped point.
    /// Squared distance is used to avoid an unnecessary `sqrt` when only relative
    /// comparisons are needed.
    ///
    /// - Parameters:
    ///   - point: The reference point.
    ///   - segStart: The first endpoint of the segment.
    ///   - segEnd: The second endpoint of the segment.
    /// - Returns: The squared distance from `point` to the nearest location on the segment.
    public static func squaredDistanceToSegment(_ point: Coordinate, segStart: Coordinate, segEnd: Coordinate) -> Double {
        let sx = segEnd.lat - segStart.lat
        let sy = segEnd.lon - segStart.lon
        let lengthSq = sx * sx + sy * sy

        // Degenerate segment (both endpoints are the same point)
        guard lengthSq > 1e-20 else {
            let dx = point.lat - segStart.lat
            let dy = point.lon - segStart.lon
            return dx * dx + dy * dy
        }

        // Project point onto the line, clamped to [0, 1]
        let t = max(0, min(1, ((point.lat - segStart.lat) * sx + (point.lon - segStart.lon) * sy) / lengthSq))
        let projLat = segStart.lat + t * sx
        let projLon = segStart.lon + t * sy
        let dx = point.lat - projLat
        let dy = point.lon - projLon
        return dx * dx + dy * dy
    }

    public static func contains(_ point: Coordinate, in polygon: some RandomAccessCollection<Coordinate>) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        forEachEdge(of: polygon) { current, next in
            let yi = current.lat, xi = current.lon
            let yj = next.lat, xj = next.lon
            if ((yi > point.lat) != (yj > point.lat)) &&
                (point.lon < (xj - xi) * (point.lat - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
        }
        return inside
    }

    /// Calls `body` with each pair of neighboring vertices, including the pair from the last
    /// vertex back to the first.
    private static func forEachEdge(
        of polygon: some RandomAccessCollection<Coordinate>,
        _ body: (_ current: Coordinate, _ next: Coordinate) -> Void
    ) {
        guard let first = polygon.first else { return }
        var previous = first
        for vertex in polygon.dropFirst() {
            body(previous, vertex)
            previous = vertex
        }
        body(previous, first)
    }
}
