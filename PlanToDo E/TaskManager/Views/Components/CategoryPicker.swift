import SwiftUI

struct CategoryPicker: View {
    @Binding var selectedCategoryId: UUID?
    let categories: [Category]
    let onAddCategory: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 分类标签
                ForEach(categories) { category in
                    CategoryItem(
                        category: category,
                        isSelected: selectedCategoryId == category.id,
                        onTap: {
                            selectedCategoryId = category.id
                        }
                    )
                }
            }
            .padding(.horizontal, 5)
        }
    }
}

// 单个分类项视图
struct CategoryItem: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: category.color))
                    .frame(width: 10, height: 10)
                
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.taskGroupBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
} 