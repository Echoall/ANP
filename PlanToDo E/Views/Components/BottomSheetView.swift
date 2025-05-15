import SwiftUI

struct BottomSheetView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    #if os(iOS)
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.8
    #else
    @State private var offset: CGFloat = 1000 // 使用一个足够大的值代替屏幕高度
    private let maxHeight: CGFloat = 600 // macOS固定高度
    #endif
    private let minHeight: CGFloat = 100
    private let threshold: CGFloat = 100
    @Environment(\.colorScheme) private var colorScheme
    
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
                        #if os(iOS)
                        .fill(Color(.systemBackground))
                        #else
                        .fill(colorScheme == .dark ? Color(.darkGray) : Color.white)
                        #endif
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
        .onChange(of: isPresented) { _, newValue in
            withAnimation(.spring()) {
                #if os(iOS)
                offset = newValue ? 0 : UIScreen.main.bounds.height
                #else
                offset = newValue ? 0 : 1000
                #endif
            }
        }
    }
}

// 移除重复定义的键盘相关视图和修饰器 