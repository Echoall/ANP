import Foundation
import Combine
import SwiftUI

// 通义千问API测试类
class QwenApiTest {
    static let shared = QwenApiTest()
    
    // API 相关常量
    private let apiKey = "sk-cda43bbf67a2488884c46b9c2161c56b"
    private let baseURL = "https://dashscope.aliyuncs.com/v1/services/aigc/text-generation/generation"
    private let model = "qwen-max" // 使用通义千问3.5模型
    
    private var cancellables = Set<AnyCancellable>()
    
    // 测试API连接
    func testConnection() {
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": model,
            "input": [
                "messages": [
                    ["role": "user", "content": "你好，这是一个测试消息。请简单回复\"你好，我是通义千问\"。"]
                ]
            ],
            "parameters": [
                "temperature": 0.7,
                "top_p": 0.8,
                "result_format": "message"
            ]
        ]
        
        // 将请求体转换为JSON数据
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("无法序列化请求数据")
            return
        }
        
        // 创建请求
        guard let url = URL(string: baseURL) else {
            print("无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // 打印请求信息用于调试
        print("API请求URL: \(url.absoluteString)")
        print("API请求头: \(request.allHTTPHeaderFields ?? [:])")
        print("API请求体: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        // 发送请求并处理响应
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "QwenApiTest", code: 500, userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
                }
                
                // 打印响应信息用于调试
                print("API响应状态码: \(httpResponse.statusCode)")
                print("API响应数据: \(String(data: data, encoding: .utf8) ?? "")")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "QwenApiTest", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "服务器错误: \(httpResponse.statusCode)"])
                }
                
                return data
            }
            .decode(type: QwenResponse.self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    print("请求完成")
                case .failure(let error):
                    print("请求失败: \(error)")
                }
            } receiveValue: { response in
                if let message = response.output?.choices?.first?.message {
                    print("收到回复: 角色=\(message.role), 内容=\(message.content)")
                } else {
                    print("无法解析响应消息")
                }
            }
            .store(in: &cancellables)
    }
}

// 用于在SwiftUI中显示测试结果的视图
struct QwenApiTestView: View {
    @State private var isLoading = false
    @State private var testResults = "点击按钮测试通义千问API连接"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("通义千问API测试")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ScrollView {
                Text(testResults)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 300)
            
            Button(action: {
                isLoading = true
                testResults = "测试中..."
                
                // 创建一个自定义控制台来捕获打印输出
                let originalOut = Console.shared.out
                Console.shared.out = { message in
                    DispatchQueue.main.async {
                        testResults += message + "\n"
                    }
                    originalOut(message)
                }
                
                // 测试API连接
                QwenApiTest.shared.testConnection()
                
                // 5秒后恢复原始控制台
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    Console.shared.out = originalOut
                    isLoading = false
                }
            }) {
                Text("测试API连接")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLoading ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding()
    }
}

// 自定义控制台类
class Console {
    static let shared = Console()
    
    // 使用同步锁和主线程执行来避免内存访问问题
    private let lock = NSLock()
    
    var out: (String) -> Void = { message in
        // 这里使用系统原生print而非重定义的print
        Swift.print(message)
    }
    
    // 线程安全的输出方法
    func safeOutput(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        
        // 如果当前不是主线程，切换到主线程执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.out(message)
            }
        } else {
            out(message)
        }
    }
}

// 辅助函数，用于将print输出重定向到我们的控制台
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // 安全处理，防止将nil转为字符串时的潜在崩溃
    let output = items.map { item -> String in
        if item is NSNull {
            return "null"
        }
        return "\(item)"
    }.joined(separator: separator)
    
    // 使用Console的线程安全方法
    Console.shared.safeOutput(output)
} 