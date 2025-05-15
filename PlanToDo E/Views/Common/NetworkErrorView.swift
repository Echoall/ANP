import SwiftUI

/// 网络错误提示视图
struct NetworkErrorView: View {
    /// 重试回调
    var onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("网络连接不可用")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("无法连接到网络，请检查您的网络设置")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("重试")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
        NetworkErrorView {
            print("重试连接")
        }
    }
} 