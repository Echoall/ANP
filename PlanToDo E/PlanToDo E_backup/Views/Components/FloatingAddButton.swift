import SwiftUI

struct FloatingAddButton: View {
    var action: () -> Void
    
    // 动画状态
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            ZStack {
                // 外部阴影圆圈
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
                
                // 内部渐变背景
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                
                // 加号图标
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            #if os(macOS)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            #endif
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 60, height: 60)
        .padding(20)
    }
}

// 预览
struct FloatingAddButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            FloatingAddButton {
                print("添加按钮被点击")
            }
            .position(x: 50, y: 300) // 使用固定值，避免平台特定API
        }
    }
} 