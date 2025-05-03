import SwiftUI
import Combine

/* 删除重复定义，移至单独文件中 */

struct KeyboardAwareView<Content: View>: View {
    #if os(iOS)
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    #endif
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        #if os(iOS)
        content
            .padding(.bottom, isKeyboardVisible ? keyboardHeight : 0)
            .animation(.easeOut(duration: 0.16), value: isKeyboardVisible)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    keyboardHeight = keyboardFrame.height
                    isKeyboardVisible = true
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = false
                    keyboardHeight = 0
                }
            }
        #else
        content
        #endif
    }
}

// 这些扩展和结构已移至KeyboardUtils.swift，此处移除
/* 
// 扩展View添加键盘自动消失功能
extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

// 点击背景隐藏键盘的修饰器
struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}
*/ 