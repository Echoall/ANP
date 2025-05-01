import SwiftUI

struct SimpleTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("测试视图")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("如果你能看到这个界面，说明项目已成功配置")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
        }
        .padding()
    }
} 