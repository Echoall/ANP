import SwiftUI

/// 增强型网络错误提示视图
struct EnhancedNetworkErrorView: View {
    /// 网络监控器
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    /// 显示诊断信息
    @State private var showDiagnostics = false
    /// 正在修复
    @State private var isRepairing = false
    /// 显示修复提示
    @State private var showRepairTips = false
    /// 修复提示内容
    @State private var repairTip = ""
    /// 重试回调
    var onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            errorIcon
            
            errorTitle
            
            errorDescription
            
            actionButtons
            
            if showDiagnostics {
                diagnosticsPanel
            }
            
            if showRepairTips {
                repairTipView
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
    
    // MARK: - 视图组件
    
    /// 错误图标
    private var errorIcon: some View {
        Image(systemName: getErrorIcon())
            .font(.system(size: 60))
            .foregroundColor(.red)
    }
    
    /// 错误标题
    private var errorTitle: some View {
        Text(getErrorTitle())
            .font(.title2)
            .fontWeight(.bold)
    }
    
    /// 错误描述
    private var errorDescription: some View {
        Text(getErrorDescription())
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
    
    /// 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 重试按钮
            Button(action: onRetry) {
                Text("重试连接")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // 修复按钮
            Button(action: attemptRepair) {
                HStack {
                    Text(isRepairing ? "修复中..." : "尝试修复")
                    
                    if isRepairing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
                .fontWeight(.semibold)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isRepairing)
            
            // 诊断信息按钮
            Button(action: {
                withAnimation {
                    showDiagnostics.toggle()
                    showRepairTips = false
                }
            }) {
                Text(showDiagnostics ? "隐藏诊断信息" : "显示诊断信息")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
        .padding(.top, 10)
    }
    
    /// 诊断信息面板
    private var diagnosticsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("网络诊断信息")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text(networkMonitor.getNetworkStatusDescription())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 修复提示视图
    private var repairTipView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("修复建议")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text(repairTip)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 辅助方法
    
    /// 获取错误图标
    /// - Returns: 图标名称
    private func getErrorIcon() -> String {
        switch networkMonitor.detailedNetworkStatus {
        case .wifiDenied:
            return "wifi.exclamationmark"
        case .cellularDenied:
            return "antenna.radiowaves.left.and.right.slash"
        default:
            return "wifi.slash"
        }
    }
    
    /// 获取错误标题
    /// - Returns: 错误标题
    private func getErrorTitle() -> String {
        switch networkMonitor.detailedNetworkStatus {
        case .wifiDenied:
            return "WiFi访问被拒绝"
        case .cellularDenied:
            return "蜂窝数据访问被拒绝"
        case .disconnected:
            return "网络连接断开"
        default:
            return "网络连接不可用"
        }
    }
    
    /// 获取错误描述
    /// - Returns: 错误描述
    private func getErrorDescription() -> String {
        switch networkMonitor.detailedNetworkStatus {
        case .wifiDenied:
            return "应用无法访问WiFi网络，可能是权限问题或网络策略限制。请检查您的网络设置或尝试重启应用。"
        case .cellularDenied:
            return "应用无法访问蜂窝数据网络，请检查是否需要更新蜂窝数据设置或应用权限。"
        case .disconnected:
            return "无法连接到网络，请检查您的WiFi或蜂窝数据连接是否正常。"
        default:
            return "无法连接到网络，请检查您的网络设置并重试。"
        }
    }
    
    /// 尝试修复网络问题
    private func attemptRepair() {
        isRepairing = true
        
        // 显示特定修复提示
        showRepairTips = true
        switch networkMonitor.detailedNetworkStatus {
        case .wifiDenied:
            repairTip = "1. 请尝试开启并关闭飞行模式来重置网络\n2. 确认应用有网络访问权限\n3. 重启设备后再次尝试"
        case .cellularDenied:
            repairTip = "1. 前往设置>蜂窝网络，确认应用有蜂窝数据访问权限\n2. 检查是否需要更新蜂窝数据设置\n3. 重启设备后再次尝试"
        default:
            repairTip = "1. 检查WiFi或蜂窝数据连接是否开启\n2. 开启并关闭飞行模式\n3. 重启设备\n4. 重置网络设置（设置>通用>还原>还原网络设置）"
        }
        
        // 尝试自动修复
        NetworkFixUtility.shared.attemptNetworkFix { success in
            DispatchQueue.main.async {
                isRepairing = false
                if success {
                    repairTip += "\n\n✅ 自动修复成功，请重试连接"
                } else {
                    repairTip += "\n\n❌ 自动修复未能解决问题，请尝试手动修复步骤"
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
        EnhancedNetworkErrorView {
            print("重试连接")
        }
    }
} 