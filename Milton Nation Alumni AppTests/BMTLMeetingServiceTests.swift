import Testing
import Foundation
import CoreLocation
@testable import Milton_Nation_Alumni_App

// MARK: - BMTLMeetingRaw tests

@Suite("BMTLMeetingRaw Tests")
struct BMTLMeetingRawTests {

    @Test("toBMTLMeeting returns nil when id is missing")
    func missingId() {
        let raw = BMTLMeetingRaw.make(id: nil)
        #expect(raw.toBMTLMeeting() == nil)
    }

    @Test("toBMTLMeeting returns nil when latitude is non-numeric")
    func badLatitude() {
        let raw = BMTLMeetingRaw.make(latitude: "not-a-number")
        #expect(raw.toBMTLMeeting() == nil)
    }

    @Test("toBMTLMeeting returns nil when longitude is non-numeric")
    func badLongitude() {
        let raw = BMTLMeetingRaw.make(longitude: "bad")
        #expect(raw.toBMTLMeeting() == nil)
    }

    @Test("toBMTLMeeting succeeds with valid fields")
    func validRaw() throws {
        let raw = BMTLMeetingRaw.make()
        let meeting = try #require(raw.toBMTLMeeting())
        #expect(meeting.id == "42")
        #expect(meeting.name == "Test Group")
        #expect(meeting.latitude == 40.7128)
        #expect(meeting.longitude == -74.0060)
    }

    @Test("toBMTLMeeting uses fallback name when meeting_name is nil")
    func fallbackName() throws {
        let raw = BMTLMeetingRaw.make(name: nil)
        let meeting = try #require(raw.toBMTLMeeting())
        #expect(meeting.name == "Unnamed Meeting")
    }
}

// MARK: - BMTLMeeting model tests

@Suite("BMTLMeeting Model Tests")
struct BMTLMeetingModelTests {

    @Test("weekdayName returns correct day for valid weekday")
    func weekdayNameValid() {
        let m = BMTLMeeting.make(weekday: 2)   // Monday
        #expect(m.weekdayName == "Monday")
    }

    @Test("weekdayName returns Unknown for out-of-range weekday")
    func weekdayNameInvalid() {
        let m = BMTLMeeting.make(weekday: 0)
        #expect(m.weekdayName == "Unknown")
    }

    @Test("formattedDistance returns empty string when distanceMiles is nil")
    func noDistance() {
        let m = BMTLMeeting.make(distanceMiles: nil)
        #expect(m.formattedDistance == "")
    }

    @Test("formattedDistance formats to one decimal place")
    func formattedDistance() {
        let m = BMTLMeeting.make(distanceMiles: 3.567)
        #expect(m.formattedDistance == "3.6 mi")
    }

    @Test("fullAddress joins non-empty components")
    func fullAddress() {
        let m = BMTLMeeting.make()
        #expect(m.fullAddress.contains("Main St"))
        #expect(m.fullAddress.contains("Teaneck"))
    }

    @Test("fullAddress skips empty components")
    func fullAddressSkipsEmpty() {
        var m = BMTLMeeting.make()
        m = BMTLMeeting(
            id: m.id, name: m.name, weekday: m.weekday,
            startTime: m.startTime, duration: m.duration,
            latitude: m.latitude, longitude: m.longitude,
            locationName: m.locationName,
            streetAddress: "", city: "Newark", state: "NJ", zip: "",
            formats: m.formats, fellowship: .na, distanceMiles: nil
        )
        #expect(m.fullAddress == "Newark, NJ")
    }

    @Test("coordinate returns correct CLLocationCoordinate2D")
    func coordinate() {
        let m = BMTLMeeting.make(lat: 40.0, lng: -74.0)
        #expect(m.coordinate.latitude == 40.0)
        #expect(m.coordinate.longitude == -74.0)
    }

    @Test("formattedStartTime parses HH:MM:SS correctly")
    func startTime() {
        let m = BMTLMeeting.make(startTime: "19:30:00")
        // Should return a non-empty localized time string
        #expect(!m.formattedStartTime.isEmpty)
        #expect(m.formattedStartTime != "19:30:00")   // was formatted
    }

    @Test("formattedStartTime returns raw string for malformed input")
    func startTimeFallback() {
        let m = BMTLMeeting.make(startTime: "bad")
        #expect(m.formattedStartTime == "bad")
    }
}

// MARK: - MockBMTLMeetingService tests

@Suite("MockBMTLMeetingService Tests")
struct MockBMTLMeetingServiceTests {

    @Test("fetchNearbyMeetings returns 10 results by default")
    func defaultResults() async throws {
        let svc = MockBMTLMeetingService()
        let results = try await svc.fetchNearbyMeetings(
            latitude: 40.89, longitude: -74.01,
            radiusMiles: 10, maxResults: 10
        )
        #expect(results.count == 10)
    }

    @Test("fetchNearbyMeetings respects maxResults cap")
    func respectsMaxResults() async throws {
        let svc = MockBMTLMeetingService()
        let results = try await svc.fetchNearbyMeetings(
            latitude: 40.89, longitude: -74.01,
            radiusMiles: 10, maxResults: 3
        )
        #expect(results.count == 3)
    }

    @Test("fetchNearbyMeetings returns no more than available meetings")
    func capsAtAvailable() async throws {
        let svc = MockBMTLMeetingService()
        let results = try await svc.fetchNearbyMeetings(
            latitude: 40.89, longitude: -74.01,
            radiusMiles: 10, maxResults: 50   // more than the 10 hardcoded
        )
        #expect(results.count == 10)
    }

    @Test("all returned meetings have non-empty names")
    func nonEmptyNames() async throws {
        let svc = MockBMTLMeetingService()
        let results = try await svc.fetchNearbyMeetings(
            latitude: 40.89, longitude: -74.01,
            radiusMiles: 10, maxResults: 10
        )
        #expect(results.filter { $0.name.isEmpty }.isEmpty)
    }

    @Test("all returned meetings have valid coordinates")
    func validCoordinates() async throws {
        let svc = MockBMTLMeetingService()
        let results = try await svc.fetchNearbyMeetings(
            latitude: 40.89, longitude: -74.01,
            radiusMiles: 10, maxResults: 10
        )
        for m in results {
            #expect(m.latitude >= -90 && m.latitude <= 90)
            #expect(m.longitude >= -180 && m.longitude <= 180)
        }
    }

    @Test("returned meetings have distanceMiles populated")
    func distancePopulated() async throws {
        let svc = MockBMTLMeetingService()
        let results = try await svc.fetchNearbyMeetings(
            latitude: 40.89, longitude: -74.01,
            radiusMiles: 10, maxResults: 10
        )
        for m in results {
            #expect(m.distanceMiles != nil)
        }
    }
}

// MARK: - Helpers

extension BMTLMeetingRaw {
    static func make(
        id: String? = "42",
        name: String? = "Test Group",
        weekday: String? = "2",
        startTime: String? = "19:00:00",
        latitude: String? = "40.7128",
        longitude: String? = "-74.0060"
    ) -> BMTLMeetingRaw {
        BMTLMeetingRaw(
            id_bigint: id,
            meeting_name: name,
            weekday_tinyint: weekday,
            start_time: startTime,
            duration_time: "01:00:00",
            latitude: latitude,
            longitude: longitude,
            location_text: "Test Hall",
            location_street: "1 Main St",
            location_municipality: "Teaneck",
            location_province: "NJ",
            location_postal_code_1: "07666",
            formats: "O,D"
        )
    }
}

extension BMTLMeeting {
    static func make(
        weekday: Int = 2,
        lat: Double = 40.7128,
        lng: Double = -74.0060,
        distanceMiles: Double? = 1.5,
        startTime: String = "19:00:00"
    ) -> BMTLMeeting {
        BMTLMeeting(
            id: "1",
            name: "Test Group",
            weekday: weekday,
            startTime: startTime,
            duration: "01:00:00",
            latitude: lat,
            longitude: lng,
            locationName: "Test Hall",
            streetAddress: "1 Main St",
            city: "Teaneck",
            state: "NJ",
            zip: "07666",
            formats: "O,D",
            fellowship: .na,
            distanceMiles: distanceMiles
        )
    }
}
