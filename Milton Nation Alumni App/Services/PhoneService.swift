import UIKit

/// Centralized utility for making phone calls and sending SMS messages.
/// All `tel:` and `sms:` URL opens should route through this service
/// so that `canOpenURL` is checked first (graceful no-op on simulators).
enum PhoneService {

    /// Opens the native Phone app for the given number.
    /// Cleans non-numeric characters, validates with `canOpenURL`, then opens.
    static func call(_ number: String) {
        let cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        guard let url = URL(string: "tel:\(cleaned)") else { return }
        guard UIApplication.shared.canOpenURL(url) else {
            #if DEBUG
            print("[PhoneService] Cannot open tel: URL — likely running on simulator")
            #endif
            return
        }
        UIApplication.shared.open(url)
    }

    /// Opens the native Messages app for the given number.
    /// Cleans non-numeric characters, validates with `canOpenURL`, then opens.
    static func text(_ number: String) {
        let cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        guard let url = URL(string: "sms:\(cleaned)") else { return }
        guard UIApplication.shared.canOpenURL(url) else {
            #if DEBUG
            print("[PhoneService] Cannot open sms: URL — likely running on simulator")
            #endif
            return
        }
        UIApplication.shared.open(url)
    }
}
