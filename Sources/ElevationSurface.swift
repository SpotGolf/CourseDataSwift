import Foundation

/// The height of the ground across a green, as a grid of cells.
///
/// The grid is laid out in meters east and north of ``origin`` on a flat local plane: the
/// center of the cell at `column`, `row` is `column * spacing` meters east and `row * spacing`
/// meters north of the origin. One degree of longitude is taken as one degree of latitude times
/// the cosine of the origin's latitude, which is the projection SpotGolf's `GroundPlane` uses.
///
/// Each elevation is kept as a whole number of centimeters, so it is accurate to within half a
/// centimeter. A cell outside the green has no elevation.
///
/// Encoded as `{"origin": {...}, "spacing": 1, "columns": 3, "elevations": [...]}`. The number
/// of rows is not encoded: it is the number of elevations divided by `columns`. The elevations run row by row from south to north, and west to east within a row. Each
/// number is the difference from the last known elevation, and the first known one is encoded
/// as it is. A cell with no elevation is encoded as `null`.
public struct ElevationSurface: Codable, Hashable, Sendable {
    /// Meters per unit of elevation (one centimeter).
    static let metersPerElevationUnit = 0.01

    /// Marks a cell whose elevation is unknown.
    static let noElevation = Int.min

    /// The center of the grid's south-west cell.
    public let origin: Coordinate

    /// The distance between the centers of neighboring cells, in meters.
    public let spacing: Double

    /// The number of cells from west to east.
    public let columns: Int

    /// One value per cell, in centimeters, row by row from south to north.
    private var elevations: [Int]

    /// The number of cells from south to north.
    public var rows: Int {
        columns == 0 ? 0 : elevations.count / columns
    }

    /// - Parameter elevations: The elevation of each cell above mean sea level, in meters, row
    ///   by row from south to north and west to east within a row, with `nil` for a cell
    ///   outside the green. Must hold a whole number of rows of `columns` values.
    public init(origin: Coordinate, spacing: Double = 1.0, columns: Int, elevations: [Double?]) {
        precondition(columns >= 0, "Columns can't be negative")
        precondition(
            Self.fillsWholeRows(elevations.count, columns: columns),
            "Expected a multiple of \(columns) elevations, found \(elevations.count)"
        )
        self.origin = origin
        self.spacing = spacing
        self.columns = columns
        self.elevations = elevations.map {
            $0.map { Int(($0 / Self.metersPerElevationUnit).rounded()) } ?? Self.noElevation
        }
    }

    /// Whether `count` cells make up a whole number of rows of `columns` cells.
    private static func fillsWholeRows(_ count: Int, columns: Int) -> Bool {
        columns == 0 ? count == 0 : count % columns == 0
    }

    /// The elevation of a cell above mean sea level, in meters, or `nil` if the cell is outside
    /// the green or outside the grid.
    ///
    /// - Parameters:
    ///   - column: The cell's column, counted east from 0 at the origin.
    ///   - row: The cell's row, counted north from 0 at the origin.
    public func elevation(column: Int, row: Int) -> Double? {
        guard column >= 0, column < columns, row >= 0, row < rows else {
            return nil
        }
        let value = elevations[row * columns + column]
        return value == Self.noElevation ? nil : Double(value) * Self.metersPerElevationUnit
    }

    // SwiftData requires each key to match a stored property name
    enum CodingKeys: String, CodingKey {
        case origin
        case spacing
        case columns
        case elevations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        origin = try container.decode(Coordinate.self, forKey: .origin)
        spacing = try container.decode(Double.self, forKey: .spacing)
        columns = try container.decode(Int.self, forKey: .columns)
        guard columns >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .columns,
                in: container,
                debugDescription: "Columns can't be negative (\(columns))"
            )
        }

        let deltas = try container.decode([Int?].self, forKey: .elevations)
        guard Self.fillsWholeRows(deltas.count, columns: columns) else {
            throw DecodingError.dataCorruptedError(
                forKey: .elevations,
                in: container,
                debugDescription: "Expected a multiple of \(columns) elevations, found \(deltas.count)"
            )
        }

        elevations = []
        elevations.reserveCapacity(deltas.count)
        var lastElevation = 0
        for delta in deltas {
            guard let delta else {
                elevations.append(Self.noElevation)
                continue
            }
            lastElevation += delta
            elevations.append(lastElevation)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var deltas: [Int?] = []
        deltas.reserveCapacity(elevations.count)
        var lastElevation = 0
        for value in elevations {
            guard value != Self.noElevation else {
                deltas.append(nil)
                continue
            }
            deltas.append(value - lastElevation)
            lastElevation = value
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin, forKey: .origin)
        try container.encode(spacing, forKey: .spacing)
        try container.encode(columns, forKey: .columns)
        try container.encode(deltas, forKey: .elevations)
    }
}
