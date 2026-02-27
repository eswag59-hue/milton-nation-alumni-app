import SwiftUI

struct CategoryFilterBar: View {
    @Binding var selectedCategory: PostCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", category: nil)
                ForEach(PostCategory.allCases, id: \.self) { category in
                    filterChip(label: "\(category.emoji) \(category.displayName)", category: category)
                }
            }
            .padding(.horizontal)
        }
    }

    private func filterChip(label: String, category: PostCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                .background(isSelected ? AppTheme.accent : AppTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : AppTheme.divider, lineWidth: 1)
                )
        }
    }
}
