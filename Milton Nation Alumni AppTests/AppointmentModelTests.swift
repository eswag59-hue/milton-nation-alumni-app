import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("Appointment Model Tests")
struct AppointmentModelTests {

    /// Build an appointment with a given status + start time. Mirrors the
    /// `scheduleSession` init (the defaulted request-only fields are omitted).
    private func makeAppointment(status: AppointmentStatus,
                                 start: Date?,
                                 durationMinutes: Int = 50,
                                 zoomJoinUrl: String? = nil) -> Appointment {
        Appointment(
            id: UUID(), clientId: UUID(), providerId: UUID(), facility: .ohio,
            appointmentType: .individualTherapy, purpose: nil, status: status,
            requestedBy: UUID(), scheduledStart: start, durationMinutes: durationMinutes,
            zoomMeetingId: nil, zoomJoinUrl: zoomJoinUrl, staffNote: nil,
            createdBy: UUID(), createdAt: Date(), updatedAt: nil,
            clientName: nil, providerName: nil
        )
    }

    // MARK: - isRatable (the previously-dead rating flow)

    @Test("A confirmed session that has ended is ratable")
    func confirmedPastIsRatable() {
        // Started 2h ago, 50 min long → ended ~70 min ago.
        let appt = makeAppointment(status: .confirmed, start: Date().addingTimeInterval(-7200))
        #expect(appt.isRatable == true)
    }

    @Test("A confirmed session in the future is NOT ratable")
    func confirmedFutureNotRatable() {
        let appt = makeAppointment(status: .confirmed, start: Date().addingTimeInterval(7200))
        #expect(appt.isRatable == false)
    }

    @Test("A confirmed session with no time is NOT ratable")
    func confirmedNoTimeNotRatable() {
        let appt = makeAppointment(status: .confirmed, start: nil)
        #expect(appt.isRatable == false)
    }

    @Test("An explicitly completed session is ratable")
    func completedIsRatable() {
        let appt = makeAppointment(status: .completed, start: Date().addingTimeInterval(-7200))
        #expect(appt.isRatable == true)
    }

    @Test("Requested / cancelled / no-show sessions are never ratable")
    func nonRatableStatuses() {
        let past = Date().addingTimeInterval(-7200)
        #expect(makeAppointment(status: .requested, start: nil).isRatable == false)
        #expect(makeAppointment(status: .cancelled, start: past).isRatable == false)
        #expect(makeAppointment(status: .noShow, start: past).isRatable == false)
    }

    // MARK: - canJoin (video button gating)

    @Test("Join is unavailable when there is no video link, even at session time")
    func canJoinRequiresURL() {
        // Starts in 5 min (inside the −15 min open window) but no URL set.
        let appt = makeAppointment(status: .confirmed, start: Date().addingTimeInterval(300))
        #expect(appt.canJoin == false)
    }

    @Test("Join arms within the window when a link exists")
    func canJoinWithinWindow() {
        let appt = makeAppointment(status: .confirmed, start: Date().addingTimeInterval(300),
                                   zoomJoinUrl: "https://example.com/session")
        #expect(appt.canJoin == true)
    }

    @Test("Join is closed long after the session, even with a link")
    func canJoinClosedAfterSession() {
        let appt = makeAppointment(status: .confirmed, start: Date().addingTimeInterval(-7200),
                                   zoomJoinUrl: "https://example.com/session")
        #expect(appt.canJoin == false)
    }

    // MARK: - isUpcoming

    @Test("A requested session with no time still counts as upcoming")
    func requestedIsUpcoming() {
        #expect(makeAppointment(status: .requested, start: nil).isUpcoming == true)
    }

    @Test("A confirmed session that has ended is not upcoming")
    func endedNotUpcoming() {
        #expect(makeAppointment(status: .confirmed, start: Date().addingTimeInterval(-7200)).isUpcoming == false)
    }
}
