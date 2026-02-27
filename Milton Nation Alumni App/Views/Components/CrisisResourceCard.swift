import SwiftUI

struct CrisisResourceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.struggling)
                Text("In a Crisis?")
                    .font(.headline)
                    .foregroundStyle(AppTheme.struggling)
            }

            Text("If you're in immediate danger or having thoughts of self-harm, please reach out now.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(MockData.crisisResources) { resource in
                Button {
                    contactResource(resource)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resource.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            if let desc = resource.description {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        Spacer()
                        Text(resource.contactType == .sms ? "Text \(resource.phoneNumber)" : resource.phoneNumber)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.struggling)
                        Image(systemName: resource.contactType == .sms ? "message.fill" : "phone.fill")
                            .foregroundStyle(AppTheme.struggling)
                    }
                    .padding(12)
                    .background(AppTheme.strugglingLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                }
                .accessibilityLabel(resource.contactType == .sms ? "Text \(resource.name) at \(resource.phoneNumber)" : "Call \(resource.name) at \(resource.phoneNumber)")
                .accessibilityHint(resource.contactType == .sms ? "Double tap to send a text" : "Double tap to call")
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .strokeBorder(AppTheme.struggling.opacity(0.3), lineWidth: 1)
        )
    }

    private func contactResource(_ resource: CrisisResource) {
        if resource.contactType == .sms {
            PhoneService.text(resource.phoneNumber)
        } else {
            PhoneService.call(resource.phoneNumber)
        }
    }
}
