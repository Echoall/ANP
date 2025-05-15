import SwiftUI

struct TestRunView: View {
    var body: some View {
        VStack {
            Text("测试运行成功")
                .font(.largeTitle)
                .padding()
            Text("如果您看到此界面，说明应用已成功启动且白屏问题已修复")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview {
    TestRunView()
} 