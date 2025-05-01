import Foundation

// 存储服务相关的错误类型
enum StorageError: Error {
    case dataNotFound      // 数据未找到
    case encodingError     // 编码错误
    case decodingError     // 解码错误
    case saveFailed        // 保存失败
    case deleteFailed      // 删除失败
    case invalidData       // 无效数据
    case networkError      // 网络错误
    case authError         // 认证错误
    case unknownError      // 未知错误
    
    var localizedDescription: String {
        switch self {
        case .dataNotFound:
            return "请求的数据未找到"
        case .encodingError:
            return "数据编码失败"
        case .decodingError:
            return "数据解码失败"
        case .saveFailed:
            return "数据保存失败"
        case .deleteFailed:
            return "数据删除失败"
        case .invalidData:
            return "数据格式无效"
        case .networkError:
            return "网络连接错误"
        case .authError:
            return "认证失败"
        case .unknownError:
            return "发生未知错误"
        }
    }
} 