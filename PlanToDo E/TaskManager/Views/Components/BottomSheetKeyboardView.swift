import SwiftUI

struct BottomSheetKeyboardView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        BottomSheetView(isPresented: $isPresented) {
            KeyboardAwareView {
                content
                    .dismissKeyboardOnTap()
            }
        }
    }
} 