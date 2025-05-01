import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedCategoryId: UUID?
    @Binding var selectedSpecialCategory: SpecialCategory?
    let categories: [Category]
    let onAddCategory: () -> Void
    let onManageCategories: () -> Void
    let onCalendarTap: () -> Void
    let viewModel: MainViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 半透明背景，点击关闭菜单
                if isShowing {
                    Color.black
                        .opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                isShowing = false
                            }
                        }
                }
                
                // 侧边菜单内容
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        // 用户头像和信息区
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                                .padding(.top, 30)
                            
                            Text("PlantoDo")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("管理您的目标和任务")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 16)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        
                        // 分隔线
                        Divider()
                        
                        // 特殊分类区
                        VStack(spacing: 0) {
                            ForEach(SpecialCategory.allCases) { specialCategory in
                                Button(action: {
                                    selectedSpecialCategory = specialCategory
                                    selectedCategoryId = nil
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        isShowing = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: specialCategory.icon)
                                            .foregroundColor(Color(hex: specialCategory.color))
                                            .font(.system(size: 20))
                                            .frame(width: 30)
                                        
                                        Text(specialCategory.name)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedSpecialCategory == specialCategory {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(selectedSpecialCategory == specialCategory ? Color(.systemGray5) : Color.clear)
                                }
                            }
                        }
                        
                        // 分隔线
                        Divider()
                            .padding(.vertical, 8)
                        
                        // 分类标题和管理按钮
                        HStack {
                            Text("分类")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: onManageCategories) {
                                Text("管理")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        
                        // 用户分类列表
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(categories) { category in
                                    Button(action: {
                                        selectedCategoryId = category.id
                                        selectedSpecialCategory = nil
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            isShowing = false
                                        }
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(Color(hex: category.color))
                                                .frame(width: 12, height: 12)
                                                .padding(.trailing, 8)
                                            
                                            Text(category.name)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if selectedCategoryId == category.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 20)
                                        .background(selectedCategoryId == category.id ? Color(.systemGray5) : Color.clear)
                                    }
                                }
                                
                                // 添加分类按钮
                                Button(action: onAddCategory) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.blue)
                                            .padding(.trailing, 8)
                                        
                                        Text("添加分类")
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 底部按钮区域
                        Divider()
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                // 打开设置
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                        .foregroundColor(.primary)
                                        .frame(width: 30)
                                    
                                    Text("设置")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                            }
                            
                            NavigationLink(destination: AnalyticsView()) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                        .foregroundColor(.primary)
                                        .frame(width: 30)
                                    
                                    Text("数据分析")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                            }
                            
                            // 日历按钮
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isShowing = false
                                }
                                onCalendarTap()
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.primary)
                                        .frame(width: 30)
                                    
                                    Text("日历")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.8, 300))
                    .background(Color(.systemBackground))
                    .offset(x: isShowing ? 0 : -min(geometry.size.width * 0.8, 300))
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isShowing)
                    
                    Spacer()
                }
            }
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width < -50 {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isShowing = false
                                }
                            }
                        }
                )
            }
    }
} 