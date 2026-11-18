import XCTest
import CourseDataSwift

/// Tests the rating, slope, and handicaps of a round over sub-courses picked in any order. The
/// numbers come from real scorecards and rating sheets.
final class RoundTests: XCTestCase {
    private let location = CourseLocation(address: "", city: "", state: "", country: "", coordinate: Coordinate(lat: 0, lon: 0))

    private func subCourse(
        _ name: String,
        male: [Int],
        female: [Int]? = nil,
        tees: [String: SubCourseTee] = [:],
        comboTees: [String: SubCourseTee] = [:]
    ) -> SubCourse {
        SubCourse(
            name: name,
            holes: male.indices.map { index in
                Hole(number: index + 1, par: 4, maleHandicap: male[index], femaleHandicap: female?[index] ?? 0)
            },
            tees: tees,
            comboTees: comboTees
        )
    }

    private func men(_ rating: Double, _ slope: Int, yards: Int? = nil, par: Int? = nil) -> SubCourseTee {
        SubCourseTee(male: TeeInformation(rating: rating, slope: slope, totalYards: yards, parTotal: par))
    }

    /// Omni Interlocken: three nines, stored the way CourseBuilder imports them. Eldorado has
    /// odd handicaps, and Vista and Sunshine have even ones. The Black ratings are the per-nine
    /// values worked out from the three published 18-hole ratings.
    private var interlocken: Course {
        Course(
            name: "Omni Interlocken Resort",
            location: location,
            subCourses: [
                subCourse("Eldorado", male: [7, 13, 1, 15, 3, 9, 11, 5, 17], female: [7, 15, 3, 11, 1, 17, 13, 9, 5],
                          tees: ["Black": men(35.9, 138, yards: 3434, par: 36)]),
                subCourse("Vista", male: [10, 16, 12, 8, 6, 18, 2, 14, 4], female: [10, 16, 12, 6, 14, 18, 2, 8, 4],
                          tees: ["Black": men(36.2, 144, yards: 3499, par: 36)]),
                subCourse("Sunshine", male: [10, 4, 8, 12, 6, 18, 2, 14, 16], female: [6, 2, 18, 8, 12, 14, 4, 16, 10],
                          tees: ["Black": men(36.3, 136, yards: 3488, par: 36)])
            ]
        )
    }

    /// Arrowhead: a normal 18-hole course whose men's card has the even handicaps on the front.
    private var arrowhead: Course {
        Course(
            name: "Arrowhead Golf Club",
            location: location,
            subCourses: [
                subCourse("Front", male: [8, 2, 10, 6, 14, 4, 16, 12, 18]),
                subCourse("Back", male: [3, 17, 1, 9, 13, 5, 11, 7, 15])
            ]
        )
    }

    // MARK: - Rating and slope

    func testRatingIsTheSumAndSlopeIsTheAverage() {
        // The three published Interlocken pairs: 72.1 / 141, 72.5 / 140, and 72.2 / 137.
        let eldoradoVista = interlocken.teeInformation(subCourseIndices: [0, 1], tee: "Black", gender: .male)
        XCTAssertEqual(eldoradoVista?.rating, 72.1)
        XCTAssertEqual(eldoradoVista?.slope, 141)

        let vistaSunshine = interlocken.teeInformation(subCourseIndices: [1, 2], tee: "Black", gender: .male)
        XCTAssertEqual(vistaSunshine?.rating, 72.5)
        XCTAssertEqual(vistaSunshine?.slope, 140)

        let sunshineEldorado = interlocken.teeInformation(subCourseIndices: [2, 0], tee: "Black", gender: .male)
        XCTAssertEqual(sunshineEldorado?.rating, 72.2)
        XCTAssertEqual(sunshineEldorado?.slope, 137)
    }

    func testOrderDoesNotChangeRatingOrSlope() {
        XCTAssertEqual(
            interlocken.teeInformation(subCourseIndices: [1, 0], tee: "Black", gender: .male),
            interlocken.teeInformation(subCourseIndices: [0, 1], tee: "Black", gender: .male)
        )
    }

    func testYardsAndParAreSums() {
        let round = interlocken.teeInformation(subCourseIndices: [0, 1], tee: "Black", gender: .male)
        XCTAssertEqual(round?.totalYards, 6933)
        XCTAssertEqual(round?.parTotal, 72)
    }

    func testHalfSlopeRoundsUp() {
        // Waikoloa Beach/Kings and Kings/Lakes, from the Hawaii State Golf Association sheets.
        let waikoloa = Course(
            name: "Waikoloa Beach & Golf Resort",
            location: location,
            subCourses: [
                subCourse("Beach", male: [], tees: ["Black": men(36.1, 116), "Red": men(32.2, 111)]),
                subCourse("Kings", male: [], tees: ["Black": men(35.8, 130), "Red": men(32.2, 108)]),
                subCourse("Lakes", male: [], tees: ["Black": men(36.2, 139), "Red": men(32.1, 111)])
            ]
        )
        let beachKingsBlack = waikoloa.teeInformation(subCourseIndices: [0, 1], tee: "Black", gender: .male)
        XCTAssertEqual(beachKingsBlack?.rating, 71.9)
        XCTAssertEqual(beachKingsBlack?.slope, 123)

        // 111 and 108 average 109.5, published as 110.
        let beachKingsRed = waikoloa.teeInformation(subCourseIndices: [0, 1], tee: "Red", gender: .male)
        XCTAssertEqual(beachKingsRed?.rating, 64.4)
        XCTAssertEqual(beachKingsRed?.slope, 110)

        // 130 and 139 average 134.5, published as 135.
        let kingsLakesBlack = waikoloa.teeInformation(subCourseIndices: [1, 2], tee: "Black", gender: .male)
        XCTAssertEqual(kingsLakesBlack?.rating, 72.0)
        XCTAssertEqual(kingsLakesBlack?.slope, 135)
    }

    func testHalvedRatingsAddBackToThePublishedRating() {
        // An 18-hole rating split in half between the nines: 73.4 / 141 and 72.1 / 141.
        let course = Course(
            name: "Test",
            location: location,
            subCourses: [
                subCourse("Front", male: [], tees: ["Black": men(36.7, 141), "Gold": men(36.05, 141)]),
                subCourse("Back", male: [], tees: ["Black": men(36.7, 141), "Gold": men(36.05, 141)])
            ]
        )
        XCTAssertEqual(course.teeInformation(subCourseIndices: [0, 1], tee: "Black", gender: .male)?.rating, 73.4)
        XCTAssertEqual(course.teeInformation(subCourseIndices: [0, 1], tee: "Gold", gender: .male)?.rating, 72.1)
        XCTAssertEqual(course.teeInformation(subCourseIndices: [1, 0], tee: "Gold", gender: .male)?.slope, 141)
        // One nine alone, to one decimal place.
        XCTAssertEqual(course.teeInformation(subCourseIndices: [0], tee: "Gold", gender: .male)?.rating, 36.1)
    }

    func testOneNineAloneAndTheSameNineTwice() {
        // The USGA example: a nine rated 35.1 / 124 played twice is 70.2 / 124.
        let course = Course(
            name: "Test",
            location: location,
            subCourses: [subCourse("Front", male: [], tees: ["Blue": men(35.1, 124, yards: 3000, par: 36)])]
        )
        let once = course.teeInformation(subCourseIndices: [0], tee: "Blue", gender: .male)
        XCTAssertEqual(once, TeeInformation(rating: 35.1, slope: 124, totalYards: 3000, parTotal: 36))

        let twice = course.teeInformation(subCourseIndices: [0, 0], tee: "Blue", gender: .male)
        XCTAssertEqual(twice, TeeInformation(rating: 70.2, slope: 124, totalYards: 6000, parTotal: 72))
    }

    func testComboTeeAndGender() {
        let comboTee = SubCourseTee(
            male: TeeInformation(rating: 35.3, slope: 133),
            female: TeeInformation(rating: 37.0, slope: 140)
        )
        let course = Course(
            name: "Test",
            location: location,
            subCourses: [
                subCourse("Front", male: [], comboTees: ["Black/Gold": comboTee]),
                subCourse("Back", male: [], comboTees: ["Black/Gold": comboTee])
            ]
        )
        XCTAssertEqual(course.teeInformation(subCourseIndices: [0, 1], tee: "Black/Gold", gender: .male)?.rating, 70.6)
        XCTAssertEqual(course.teeInformation(subCourseIndices: [0, 1], tee: "Black/Gold", gender: .female)?.rating, 74.0)
        XCTAssertEqual(course.teeInformation(subCourseIndices: [0, 1], tee: "Black/Gold", gender: .female)?.slope, 140)
    }

    func testTeeInformationIsNilWhenItCannotBeWorkedOut() {
        XCTAssertNil(interlocken.teeInformation(subCourseIndices: [], tee: "Black", gender: .male))
        XCTAssertNil(interlocken.teeInformation(subCourseIndices: [0, 3], tee: "Black", gender: .male))
        XCTAssertNil(interlocken.teeInformation(subCourseIndices: [0, 1], tee: "Red", gender: .male))
        XCTAssertNil(interlocken.teeInformation(subCourseIndices: [0, 1], tee: "Black", gender: .female))
    }

    func testAMissingValueOnOneNineLeavesThatValueOut() {
        var course = interlocken
        course.subCourses[1].tees["Black"]?.male?.rating = nil
        let round = course.teeInformation(subCourseIndices: [0, 1], tee: "Black", gender: .male)
        XCTAssertNil(round?.rating)
        XCTAssertEqual(round?.slope, 141)
        XCTAssertEqual(round?.totalYards, 6933)
    }

    // MARK: - Handicaps

    func testHandicapsAtAClubWithThreeNines() {
        // Each result is the handicap row Golf Course API gives for that pair.
        XCTAssertEqual(
            interlocken.handicaps(subCourseIndices: [0, 1], gender: .male),
            [7, 13, 1, 15, 3, 9, 11, 5, 17] + [10, 16, 12, 8, 6, 18, 2, 14, 4]
        )
        XCTAssertEqual(
            interlocken.handicaps(subCourseIndices: [1, 2], gender: .male),
            [9, 15, 11, 7, 5, 17, 1, 13, 3] + [10, 4, 8, 12, 6, 18, 2, 14, 16]
        )
        XCTAssertEqual(
            interlocken.handicaps(subCourseIndices: [2, 0], gender: .male),
            [9, 3, 7, 11, 5, 17, 1, 13, 15] + [8, 14, 2, 16, 4, 10, 12, 6, 18]
        )
        XCTAssertEqual(
            interlocken.handicaps(subCourseIndices: [2, 0], gender: .female),
            [5, 1, 17, 7, 11, 13, 3, 15, 9] + [8, 16, 4, 12, 2, 18, 14, 10, 6]
        )
    }

    func testFirstNinePlayedGetsTheOddHandicapsAtAClubWithThreeNines() {
        // Vista then Eldorado: Vista moves to the odd numbers and Eldorado to the even ones.
        XCTAssertEqual(
            interlocken.handicaps(subCourseIndices: [1, 0], gender: .male),
            [9, 15, 11, 7, 5, 17, 1, 13, 3] + [8, 14, 2, 16, 4, 10, 12, 6, 18]
        )
    }

    func testHandicapsStayAsPrintedAtAnEighteenHoleCourse() {
        XCTAssertEqual(
            arrowhead.handicaps(subCourseIndices: [0, 1], gender: .male),
            [8, 2, 10, 6, 14, 4, 16, 12, 18] + [3, 17, 1, 9, 13, 5, 11, 7, 15]
        )
        // Back nine first: every hole keeps its printed handicap.
        XCTAssertEqual(
            arrowhead.handicaps(subCourseIndices: [1, 0], gender: .male),
            [3, 17, 1, 9, 13, 5, 11, 7, 15] + [8, 2, 10, 6, 14, 4, 16, 12, 18]
        )
    }

    func testOneNineAloneIsRankedOneToNine() {
        XCTAssertEqual(arrowhead.handicaps(subCourseIndices: [0], gender: .male), [4, 1, 5, 3, 7, 2, 8, 6, 9])
        // Kennedy's Babe Lind nine: the card prints 6, 4, 3, 8, 9, 1, 2, 7, 5.
        let kennedy = Course(
            name: "Kennedy Golf Course",
            location: location,
            subCourses: [
                subCourse("West", male: [11, 7, 9, 15, 3, 13, 1, 5, 17]),
                subCourse("Babe Lind", male: [12, 8, 6, 16, 18, 2, 4, 14, 10]),
                subCourse("Creek", male: [14, 12, 8, 2, 16, 4, 18, 10, 6])
            ]
        )
        XCTAssertEqual(kennedy.handicaps(subCourseIndices: [1], gender: .male), [6, 4, 3, 8, 9, 1, 2, 7, 5])
    }

    func testTheSameNineTwice() {
        XCTAssertEqual(
            arrowhead.handicaps(subCourseIndices: [0, 0], gender: .male),
            [7, 1, 9, 5, 13, 3, 15, 11, 17] + [8, 2, 10, 6, 14, 4, 16, 12, 18]
        )
    }

    func testNineHoleCourseKeepsItsHandicaps() {
        let course = Course(
            name: "Test",
            location: location,
            subCourses: [subCourse("Front", male: [3, 1, 2])]
        )
        XCTAssertEqual(course.handicaps(subCourseIndices: [0], gender: .male), [3, 1, 2])
    }

    func testHandicapsFollowHoleNumberOrder() {
        var course = arrowhead
        course.subCourses[0].holes.reverse()
        XCTAssertEqual(
            course.handicaps(subCourseIndices: [0, 1], gender: .male),
            [8, 2, 10, 6, 14, 4, 16, 12, 18] + [3, 17, 1, 9, 13, 5, 11, 7, 15]
        )
    }

    func testHandicapsAreEmptyWhenUnknown() {
        XCTAssertEqual(interlocken.handicaps(subCourseIndices: [], gender: .male), [])
        XCTAssertEqual(interlocken.handicaps(subCourseIndices: [0, 3], gender: .male), [])
        // Arrowhead has no women's handicaps.
        XCTAssertEqual(arrowhead.handicaps(subCourseIndices: [0, 1], gender: .female), [])

        var course = arrowhead
        course.subCourses[1].holes[4].maleHandicap = 0
        XCTAssertEqual(course.handicaps(subCourseIndices: [0, 1], gender: .male), [])
    }
}
