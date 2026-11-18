/// The gender a handicap or rating applies to. Golf rates each tee separately for men and women.
public enum Gender: String, Codable, CaseIterable, Hashable, Sendable {
    case male
    case female
}
