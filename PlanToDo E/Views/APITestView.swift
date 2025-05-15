import SwiftUI
import Combine

/// API测试视图
struct APITestView: View {
    /// 用户输入
    @State private var inputText = ""
    /// API响应
    @State private var responseText = ""
    /// 是否正在载入
    @State private var isLoading = false
    /// 是否显示JSON视图
    @State private var showJson = false
    /// 连接测试结果
    @State private var connectionTestResult = ""
    /// API密钥
    @State private var apiKey = ConfigurationManager.shared.qwenAPIKey ?? ""
    /// 连接测试状态
    @State private var connectionTestStatus: ConnectionTestStatus = .notTested
    /// 网络监视器
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    /// Qwen客户端
    private let qwenClient = QwenClient.shared
    /// 取消标记
    @State private var cancellables = Set<AnyCancellable>()
    
    /// 连接测试状态枚举
    enum ConnectionTestStatus: Equatable {
        case notTested, testing, success, failed(String)
        
        static func == (lhs: APITestView.ConnectionTestStatus, rhs: APITestView.ConnectionTestStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notTested, .notTested): return true
            case (.testing, .testing): return true
            case (.success, .success): return true
            case (.failed(let lhsReason), .failed(let rhsReason)): return lhsReason == rhsReason
            default: return false
            }
        }
        
        var color: Color {
            switch self {
            case .notTested: return .gray
            case .testing: return .orange
            case .success: return .green
            case .failed: return .red
            }
        }
        
        var description: String {
            switch self {
            case .notTested: return "尚未测试"
            case .testing: return "测试中..."
            case .success: return "连接成功! ✅"
            case .failed(let reason): return "连接失败: \(reason)"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("API测试工具")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                // 网络状态显示
                NetworkStatusView(networkMonitor: networkMonitor)
                
                // API密钥状态
                ApiKeyView(
                    apiKey: $apiKey,
                    connectionTestStatus: $connectionTestStatus,
                    refreshApiKey: refreshApiKey
                )
                
                // 连接测试部分
                ConnectionTestView(
                    connectionTestStatus: $connectionTestStatus,
                    apiKey: apiKey,
                    networkMonitor: networkMonitor,
                    testConnection: testConnection
                )
                
                // 消息测试部分
                MessageTestView(
                    inputText: $inputText,
                    responseText: $responseText,
                    isLoading: $isLoading,
                    showJson: $showJson,
                    apiKey: apiKey,
                    networkMonitor: networkMonitor,
                    sendMessage: sendMessage
                )
            }
            .padding()
            .onAppear {
                refreshApiKey()
            }
        }
        .navigationTitle("API测试")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 刷新API密钥
    private func refreshApiKey() {
        apiKey = ConfigurationManager.shared.qwenAPIKey ?? ""
        // 如果密钥变更，重置测试状态
        connectionTestStatus = .notTested
    }
    
    /// 测试API连接
    private func testConnection() {
        connectionTestStatus = .testing
        
        qwenClient.testConnection()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        connectionTestStatus = .failed(error.localizedDescription)
                    }
                },
                receiveValue: { _ in
                    connectionTestStatus = .success
                }
            )
            .store(in: &cancellables)
    }
    
    /// 发送消息
    private func sendMessage() {
        isLoading = true
        responseText = ""
        
        // 先刷新API密钥，确保使用最新的密钥
        refreshApiKey()
        
        let message = QwenMessage(role: "user", content: inputText)
        
        qwenClient.sendChatMessage([message])
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        responseText = "错误: \(error.localizedDescription)"
                    }
                },
                receiveValue: { response in
                    if showJson {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        if let data = try? encoder.encode(response),
                           let jsonString = String(data: data, encoding: .utf8) {
                            responseText = jsonString
                        } else {
                            responseText = "无法解析为JSON"
                        }
                    } else {
                        responseText = response.output.text
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - 子视图

/// 网络状态视图
struct NetworkStatusView: View {
    let networkMonitor: NetworkMonitor
    
    var body: some View {
        GroupBox(label: Text("网络状态").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("网络状态:")
                    Spacer()
                    Text(networkMonitor.isConnected ? "已连接" : "未连接")
                        .foregroundColor(networkMonitor.isConnected ? .green : .red)
                }
                
                HStack {
                    Text("网络类型:")
                    Spacer()
                    Text(getConnectionTypeString(networkMonitor.connectionType))
                }
                
                // 简化复杂表达式
                HStack {
                    Text("详细状态:")
                    Spacer()
                    let firstLine = networkMonitor.getNetworkStatusDescription()
                        .components(separatedBy: "\n").first ?? ""
                    Text(firstLine)
                        .foregroundColor(networkMonitor.detailedNetworkStatus == .connected ? .green : .orange)
                }
                
                if let reason = networkMonitor.lastConnectionFailureReason, !reason.isEmpty {
                    Text("连接失败原因: \(reason)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(8)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // 获取连接类型字符串
    private func getConnectionTypeString(_ type: NetworkMonitor.ConnectionType) -> String {
        switch type {
        case .wifi: return "Wi-Fi"
        case .cellular: return "蜂窝数据"
        case .ethernet: return "有线网络"
        case .unknown: return "未知"
        }
    }
}

/// API密钥视图
struct ApiKeyView: View {
    @Binding var apiKey: String
    @Binding var connectionTestStatus: APITestView.ConnectionTestStatus
    let refreshApiKey: () -> Void
    
    var body: some View {
        GroupBox(label: Text("API密钥").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("当前API密钥:")
                    Spacer()
                    if apiKey.isEmpty {
                        Text("未设置")
                            .foregroundColor(.red)
                    } else {
                        Text("已设置")
                            .foregroundColor(.green)
                    }
                }
                
                if !apiKey.isEmpty {
                    Text("密钥前缀: \(apiKey.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if apiKey.isEmpty {
                    Text("请在设置中配置API密钥")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.top, 4)
                    
                    NavigationLink(destination: SettingsView()) {
                        Text("前往设置")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                } else {
                    Button("刷新API密钥") {
                        refreshApiKey()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(8)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

/// 连接测试视图
struct ConnectionTestView: View {
    @Binding var connectionTestStatus: APITestView.ConnectionTestStatus
    let apiKey: String
    let networkMonitor: NetworkMonitor
    let testConnection: () -> Void
    
    var body: some View {
        GroupBox(label: Text("连接测试").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Button("测试API连接") {
                    testConnection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!networkMonitor.isConnected || apiKey.isEmpty || connectionTestStatus == .testing)
                
                HStack {
                    Text("测试状态:")
                    Spacer()
                    Text(connectionTestStatus.description)
                        .foregroundColor(connectionTestStatus.color)
                }
                .padding(.top, 4)
            }
            .padding(8)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

/// 消息测试视图
struct MessageTestView: View {
    @Binding var inputText: String
    @Binding var responseText: String
    @Binding var isLoading: Bool
    @Binding var showJson: Bool
    let apiKey: String
    let networkMonitor: NetworkMonitor
    let sendMessage: () -> Void
    
    var body: some View {
        GroupBox(label: Text("消息测试").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("输入消息...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading || !networkMonitor.isConnected || apiKey.isEmpty)
                
                HStack {
                    Button("发送") {
                        sendMessage()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty || isLoading || !networkMonitor.isConnected || apiKey.isEmpty)
                    
                    Toggle("显示JSON", isOn: $showJson)
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                if !responseText.isEmpty {
                    Text("响应:")
                        .font(.headline)
                    
                    Text(responseText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(8)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    APITestView()
} 