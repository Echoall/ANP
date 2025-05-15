import SwiftUI

#if os(iOS)
// 扩展View提供点击隐藏键盘的功能
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
#else
// macOS版本 - 提供空实现以支持编译
extension View {
    func dismissKeyboardOnTap() -> some View {
        // macOS不需要手动关闭键盘
        return self
    }
}
#endif 