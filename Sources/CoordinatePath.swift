import Foundation

/// An ordered list of coordinates, such as a feature's polygon or a hole's centerline, stored
/// compactly.
///
/// Each point is kept as three whole numbers, each in units of about 1 foot: latitude and
/// longitude in 1/365,000 of a degree (30.5 cm of latitude, and less of longitude), and elevation
/// in feet. Points are rounded to the nearest unit, so they are accurate to within half a foot.
///
/// Encoded as `{"values": [...]}`, where each number is the difference from the same number in
/// the previous point. Neighboring points are close together, so the differences are short.
/// The first point's numbers are encoded as they are. A missing elevation is encoded as `null`,
/// and the next known elevation is the difference from the last known one.
public struct CoordinatePath: Codable, Hashable, Sendable, RandomAccessCollection, ExpressibleByArrayLiteral {
    /// Units per degree of latitude or longitude.
    static let degreeScale = 365_000.0

    /// Meters per unit of elevation (one foot).
    static let metersPerElevationUnit = 0.3048

    /// Marks a point whose elevation is unknown.
    static let noElevation = Int.min

    /// Three values per point: latitude, longitude, elevation.
    private var values: [Int]

    public init(_ coordinates: some Sequence<Coordinate> = []) {
        values = []
        for coordinate in coordinates {
            append(coordinate)
        }
    }

    public init(arrayLiteral coordinates: Coordinate...) {
        self.init(coordinates)
    }

    public var startIndex: Int { 0 }

    public var endIndex: Int { values.count / 3 }

    public subscript(index: Int) -> Coordinate {
        let ele = values[index * 3 + 2]
        return Coordinate(
            lat: Double(values[index * 3]) / Self.degreeScale,
            lon: Double(values[index * 3 + 1]) / Self.degreeScale,
            ele: ele == Self.noElevation ? nil : Double(ele) * Self.metersPerElevationUnit
        )
    }

    public mutating func append(_ coordinate: Coordinate) {
        values.append(Int((coordinate.lat * Self.degreeScale).rounded()))
        values.append(Int((coordinate.lon * Self.degreeScale).rounded()))
        values.append(coordinate.ele.map { Int(($0 / Self.metersPerElevationUnit).rounded()) } ?? Self.noElevation)
    }

    // SwiftData requires each key to match a stored property name
    enum CodingKeys: String, CodingKey {
        case values
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let deltas = try container.decode([Int?].self, forKey: .values)
        guard deltas.count % 3 == 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .values,
                in: container,
                debugDescription: "Expected three values per point, found \(deltas.count) values"
            )
        }

        values = []
        values.reserveCapacity(deltas.count)
        var lastElevation = 0
        for (index, delta) in deltas.enumerated() {
            if index % 3 == 2 {
                guard let delta else {
                    values.append(Self.noElevation)
                    continue
                }
                lastElevation += delta
                values.append(lastElevation)
            } else {
                guard let delta else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .values,
                        in: container,
                        debugDescription: "Latitude and longitude can't be null (value \(index))"
                    )
                }
                values.append(index < 3 ? delta : values[index - 3] + delta)
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var deltas: [Int?] = []
        deltas.reserveCapacity(values.count)
        var lastElevation = 0
        for (index, value) in values.enumerated() {
            if index % 3 == 2 {
                guard value != Self.noElevation else {
                    deltas.append(nil)
                    continue
                }
                deltas.append(value - lastElevation)
                lastElevation = value
            } else {
                deltas.append(index < 3 ? value : value - values[index - 3])
            }
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deltas, forKey: .values)
    }
}
