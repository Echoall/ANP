import SwiftUI

struct CategoryEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MainViewModel
    @State private var name: String = ""
    @State private var selectedColor: String = "#007AFF"
    
    let category: Category?
    let colorOptions = [
        "#007AFF", // 蓝色
        "#5AC8FA", // 浅蓝色
        "#4CD964", // 绿色
        "#FF9500", // 橙色
        "#FF2D55", // 粉色
        "#5856D6", // 紫色
        "#FF3B30", // 红色
        "#FFCC00"  // 黄色
    ]
    
    init(viewModel: MainViewModel, category: Category? = nil) {
        self.viewModel = viewModel
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _selectedColor = State(initialValue: category?.color ?? "#007AFF")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("分类信息")) {
                    TextField("分类名称", text: $name)
                    
                    ColorPickerView(selectedColor: $selectedColor, colorOptions: colorOptions)
                }
            }
            .navigationTitle(category == nil ? "创建分类" : "编辑分类")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(category == nil ? "创建" : "保存") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        if var updatedCategory = category {
            // 更新现有分类
            updatedCategory.name = name
            updatedCategory.color = selectedColor
            updatedCategory.updatedAt = Date()
            viewModel.updateCategory(updatedCategory)
        } else {
            // 创建新分类
            let newCategory = Category(
                name: name,
                color: selectedColor,
                order: viewModel.categories.count
            )
            viewModel.createCategory(newCategory)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct ColorPickerView: View {
    @Binding var selectedColor: String
    let colorOptions: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("颜色")
                .font(.subheadline)
                .foregroundColor(.taskSecondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colorOptions, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.taskSecondaryText, lineWidth: 2)
                                    .opacity(selectedColor == color ? 1 : 0)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
} 