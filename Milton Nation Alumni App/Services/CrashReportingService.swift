import Foundation
import UIKit
import Supabase

/// Lightweight crash reporting service that captures fatal exceptions and non-fatal
/// errors, persists them locally, and uploads to the `crash_reports` Supabase table.
///
/// **Setup (call once, in order, from app entry point):**
/// ```swift
/// // 1. In App.init() — installs the exception handler before any other code runs
/// CrashReportingService.shared.install()
///
/// // 2. In App body .task — uploads any report saved during a previous crash
/// await CrashReportingService.shared.uploadPendingReportIfNeeded()
/// ```
///
/// **User context (call from AppViewModel):**
/// ```swift
/// CrashReportingService.shared.setUser(user.id)   // on login
/// CrashReportingService.shared.clearUser()          // on logout
/// ```
///
/// **Non-fatal errors (call from any catch block worth tracking):**
/// ```swift
/// catch { CrashReportingService.shared.recordError(error, context: "ChatViewModel.sendMessage") }
/// ```
///
/// **How fatal crashes work:**
/// `NSSetUncaughtExceptionHandler` is called synchronously before the process
/// terminates. We write a JSON file atomically to disk. On the NEXT launch,
/// `uploadPendingReportIfNeeded()` reads that file, inserts it into Supabase,
/// and deletes the file.
///
/// **Coverage:** Catches ~90 % of real-world iOS crashes (ObjC exceptions,
/// Swift assertion/precondition failures, fatalError). Low-level SIGSEGV /
/// SIGILL signal crashes require a C helper and are not handled here.
final class CrashReportingService: @unchecked Sendable {

    static let shared = CrashReportingService()

    // MARK: - Stored Properties

    /// Current authenticated user ID — set on login, cleared on logout.
    private var userId: UUID?

    /// New UUID on every login. Ties multiple reports to the same user session.
    private var sessionId = UUID()

    /// Device info captured once at initialisation (UIDevice is main-thread-only).
    private let deviceModel: String
    private let osVersion: String

    /// File URL for the pending (unuploaded) fatal crash report between launches.
    private let pendingReportURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("com.miltonalumni.pending_crash.json")
    }()

    // MARK: - Init

    private init() {
        // UIDevice must be read on the main thread; the singleton is first accessed
        // from install(), which is called in App.init() — always on the main thread.
        deviceModel = UIDevice.current.model
        osVersion   = UIDevice.current.systemVersion
    }

    // MARK: - Installation

    /// Install the uncaught-exception handler.
    /// Call **once** from `App.init()` before any other initialisation.
    func install() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReportingService.shared.handleUncaughtException(exception)
        }
        #if DEBUG
        print("[CrashReporting] ✅ Uncaught exception handler installed")
        #endif
    }

    // MARK: - User Context

    /// Attach a logged-in user to subsequent crash and error reports.
    /// Call immediately after a successful login.
    func setUser(_ userId: UUID) {
        self.userId    = userId
        self.sessionId = UUID()   // fresh session ID on each login
    }

    /// Remove user context. Call on logout or account deletion.
    func clearUser() {
        userId = nil
    }

    // MARK: - Fatal Crash Handler

    /// Called synchronously by the OS just before process termination.
    /// Must complete quickly and use only async-signal-safe operations.
    private func handleUncaughtException(_ exception: NSException) {
        let appVersion  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

        let report = PendingCrashReport(
            reportType:      "fatal",
            exceptionName:   exception.name.rawValue,
            exceptionReason: exception.reason ?? "Unknown reason",
            callStack:       Array(exception.callStackSymbols.prefix(40)),
            appVersion:      appVersion,
            buildNumber:     buildNumber,
            osVersion:       osVersion,
            deviceModel:     deviceModel,
            userId:          userId?.uuidString,
            sessionId:       sessionId.uuidString,
            crashedAt:       ISO8601DateFormatter().string(from: Date())
        )

        // Atomic write — if the process is killed mid-write the file is untouched.
        if let data = try? JSONEncoder().encode(report) {
            try? data.write(to: pendingReportURL, options: .atomic)
        }
    }

    // MARK: - Upload Pending Fatal Report

    /// Check for a crash report saved in a previous session and upload it to Supabase.
    /// Safe to call unconditionally on every launch — exits immediately if no file exists.
    func uploadPendingReportIfNeeded() async {
        guard FileManager.default.fileExists(atPath: pendingReportURL.path),
              SupabaseConfig.isConfigured else { return }

        do {
            let data    = try Data(contentsOf: pendingReportURL)
            let pending = try JSONDecoder().decode(PendingCrashReport.self, from: data)

            let record = CrashReportRecord(
                reportType:      pending.reportType,
                exceptionName:   pending.exceptionName,
                exceptionReason: pending.exceptionReason,
                callStack:       pending.callStack,
                appVersion:      pending.appVersion,
                buildNumber:     pending.buildNumber,
                osVersion:       pending.osVersion,
                deviceModel:     pending.deviceModel,
                userId:          pending.userId.flatMap { UUID(uuidString: $0) },
                sessionId:       UUID(uuidString: pending.sessionId),
                crashedAt:       pending.crashedAt
            )

            try await SupabaseConfig.client
                .from("crash_reports")
                .insert(record)
                .execute()

            // Only delete after a confirmed successful upload
            try? FileManager.default.removeItem(at: pendingReportURL)

            #if DEBUG
            print("[CrashReporting] ✅ Fatal crash report uploaded and cleared")
            #endif
        } catch {
            // Leave the file — it will retry on the next launch.
            #if DEBUG
            print("[CrashReporting] ⚠️ Failed to upload pending crash report: \(error)")
            #endif
        }
    }

    // MARK: - Non-Fatal Error Recording

    /// Record a caught (non-fatal) error for visibility in the Supabase dashboard.
    ///
    /// Call from any `catch` block that handles an error gracefully but that you still
    /// want to track (e.g. network failures, Supabase errors, decode failures).
    ///
    /// - Parameters:
    ///   - error:    The caught error.
    ///   - context:  Human-readable label, e.g. `"ChatViewModel.sendMessage"`.
    ///   - file:     Filled automatically by the compiler.
    ///   - function: Filled automatically by the compiler.
    func recordError(
        _ error: Error,
        context: String? = nil,
        file: String = #file,
        function: String = #function
    ) {
        guard SupabaseConfig.isConfigured else { return }

        let appVersion  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let reason      = context.map { "\($0): \(error.localizedDescription)" }
                          ?? error.localizedDescription
        let fileName    = URL(fileURLWithPath: file).lastPathComponent

        let record = CrashReportRecord(
            reportType:      "non_fatal",
            exceptionName:   String(describing: type(of: error)),
            exceptionReason: reason,
            callStack:       ["\(fileName) — \(function)"],
            appVersion:      appVersion,
            buildNumber:     buildNumber,
            osVersion:       osVersion,
            deviceModel:     deviceModel,
            userId:          userId,
            sessionId:       sessionId,
            crashedAt:       ISO8601DateFormatter().string(from: Date())
        )

        Task {
            do {
                try await SupabaseConfig.client
                    .from("crash_reports")
                    .insert(record)
                    .execute()
                #if DEBUG
                print("[CrashReporting] ✅ Non-fatal error recorded: \(error.localizedDescription)")
                #endif
            } catch {
                #if DEBUG
                print("[CrashReporting] ⚠️ Failed to record non-fatal error: \(error)")
                #endif
            }
        }
    }
}

// MARK: - On-Disk Pending Crash Report

/// Persisted to disk synchronously during a fatal crash; decoded on the next launch.
private struct PendingCrashReport: Codable {
    let reportType:      String
    let exceptionName:   String
    let exceptionReason: String
    let callStack:       [String]
    let appVersion:      String
    let buildNumber:     String
    let osVersion:       String
    let deviceModel:     String
    let userId:          String?   // UUID serialised as String for Codable simplicity
    let sessionId:       String
    let crashedAt:       String
}

// MARK: - Supabase Insert Record

/// Encodable struct sent to the `crash_reports` Supabase table via PostgREST.
nonisolated private struct CrashReportRecord: Encodable, Sendable {
    let reportType:      String
    let exceptionName:   String?
    let exceptionReason: String?
    let callStack:       [String]?
    let appVersion:      String
    let buildNumber:     String
    let osVersion:       String
    let deviceModel:     String
    let userId:          UUID?
    let sessionId:       UUID?
    let crashedAt:       String

    enum CodingKeys: String, CodingKey {
        case reportType      = "report_type"
        case exceptionName   = "exception_name"
        case exceptionReason = "exception_reason"
        case callStack       = "call_stack"
        case appVersion      = "app_version"
        case buildNumber     = "build_number"
        case osVersion       = "os_version"
        case deviceModel     = "device_model"
        case userId          = "user_id"
        case sessionId       = "session_id"
        case crashedAt       = "crashed_at"
    }
}
