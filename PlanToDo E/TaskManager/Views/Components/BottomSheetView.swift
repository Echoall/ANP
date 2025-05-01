import SwiftUI

struct BottomSheetView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.8
    private let minHeight: CGFloat = 100
    private let threshold: CGFloat = 100
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 背景遮罩，点击时关闭底部抽屉
            if isPresented {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }
            }
            
            // 底部抽屉内容
            VStack {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 10)
                    
                    content
                }
                .frame(maxHeight: maxHeight)
                .offset(y: isPresented ? 0 : offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                offset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > threshold {
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            } else {
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                            }
                        }
                )
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: isPresented) { newValue in
            withAnimation(.spring()) {
                offset = newValue ? 0 : UIScreen.main.bounds.height
            }
        }
    }
}

// 移除重复定义的键盘相关视图和修饰器 