import Foundation
import Supabase

/// Production meeting service — reads and writes the `meetings` table in Supabase.
/// RLS ensures only admin/super_admin users can insert, update, or delete.
final class SupabaseMeetingService: MeetingServiceProtocol {

    private let client = SupabaseConfig.client

    // MARK: - Fetch

    func fetchMeetings() async throws -> [Meeting] {
        let rows: [MeetingRow] = try await client
            .from("meetings")
            .select()
            .order("start_time", ascending: true)
            .execute()
            .value
        return rows.map { $0.toMeeting() }
    }

    // MARK: - Create

    func createMeeting(_ meeting: Meeting) async throws -> Meeting {
        let insert = MeetingInsertRow(from: meeting)
        let row: MeetingRow = try await client
            .from("meetings")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return row.toMeeting()
    }

    // MARK: - Update

    func updateMeeting(_ meeting: Meeting) async throws -> Meeting {
        let update = MeetingUpdateRow(from: meeting)
        let row: MeetingRow = try await client
            .from("meetings")
            .update(update)
            .eq("id", value: meeting.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        return row.toMeeting()
    }

    // MARK: - Delete

    func deleteMeeting(meetingId: UUID) async throws {
        try await client
            .from("meetings")
            .delete()
            .eq("id", value: meetingId.uuidString)
            .execute()
    }
}

// MARK: - Row Types (snake_case ↔ camelCase mapping)

// Property names MUST be camelCase: the shared decoder uses
// .convertFromSnakeCase, so JSON "meeting_type" arrives as "meetingType".
// snake_case property names here would be keyNotFound on every fetch.
private struct MeetingRow: Decodable {
    let id: UUID
    let title: String
    let description: String?
    let meetingType: String
    let date: String            // "YYYY-MM-DD" (Postgres DATE)
    let startTime: Date         // TIMESTAMPTZ
    let endTime: Date           // TIMESTAMPTZ
    let locationAddress: String?
    let locationLat: Double?
    let locationLng: Double?
    let virtualLink: String?
    let isRecurring: Bool
    let recurrencePattern: String?
    let recurrenceEndDate: String?  // "YYYY-MM-DD"
    let parentMeetingId: UUID?
    let createdBy: UUID
    let createdAt: Date

    func toMeeting() -> Meeting {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")

        let parsedDate = df.date(from: date) ?? startTime
        let recurrenceEnd = recurrenceEndDate.flatMap { df.date(from: $0) }

        return Meeting(
            id: id,
            title: title,
            description: description,
            meetingType: MeetingType(rawValue: meetingType) ?? .inPerson,
            date: parsedDate,
            startTime: startTime,
            endTime: endTime,
            locationAddress: locationAddress,
            locationLat: locationLat,
            locationLng: locationLng,
            virtualLink: virtualLink,
            isRecurring: isRecurring,
            recurrencePattern: recurrencePattern.flatMap { RecurrencePattern(rawValue: $0) },
            recurrenceEndDate: recurrenceEnd,
            parentMeetingId: parentMeetingId,
            createdBy: createdBy,
            createdAt: createdAt
        )
    }
}

private struct MeetingInsertRow: Encodable {
    let title: String
    let description: String?
    let meeting_type: String
    let date: String
    let start_time: String
    let end_time: String
    let location_address: String?
    let location_lat: Double?
    let location_lng: Double?
    let virtual_link: String?
    let is_recurring: Bool
    let recurrence_pattern: String?
    let recurrence_end_date: String?
    let created_by: String

    init(from meeting: Meeting) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        title = meeting.title
        description = meeting.description
        meeting_type = meeting.meetingType.rawValue
        date = df.string(from: meeting.startTime)
        start_time = iso.string(from: meeting.startTime)
        end_time = iso.string(from: meeting.endTime)
        location_address = meeting.locationAddress
        location_lat = meeting.locationLat
        location_lng = meeting.locationLng
        virtual_link = meeting.virtualLink
        is_recurring = meeting.isRecurring
        recurrence_pattern = meeting.recurrencePattern?.rawValue
        recurrence_end_date = meeting.recurrenceEndDate.map { df.string(from: $0) }
        created_by = meeting.createdBy.uuidString
    }
}

private struct MeetingUpdateRow: Encodable {
    let title: String
    let description: String?
    let meeting_type: String
    let date: String
    let start_time: String
    let end_time: String
    let location_address: String?
    let location_lat: Double?
    let location_lng: Double?
    let virtual_link: String?
    let is_recurring: Bool
    let recurrence_pattern: String?
    let recurrence_end_date: String?

    init(from meeting: Meeting) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        title = meeting.title
        description = meeting.description
        meeting_type = meeting.meetingType.rawValue
        date = df.string(from: meeting.startTime)
        start_time = iso.string(from: meeting.startTime)
        end_time = iso.string(from: meeting.endTime)
        location_address = meeting.locationAddress
        location_lat = meeting.locationLat
        location_lng = meeting.locationLng
        virtual_link = meeting.virtualLink
        is_recurring = meeting.isRecurring
        recurrence_pattern = meeting.recurrencePattern?.rawValue
        recurrence_end_date = meeting.recurrenceEndDate.map { df.string(from: $0) }
    }
}
