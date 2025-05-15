import Foundation
import Combine

// 定义存储服务协议
protocol StorageServiceProtocol {
    // 分类相关
    func fetchCategories() -> AnyPublisher<[Category], Error>
    func createCategory(_ category: Category) -> AnyPublisher<Category, Error>
    func updateCategory(_ category: Category) -> AnyPublisher<Category, Error>
    func deleteCategory(_ categoryId: UUID) -> AnyPublisher<Bool, Error>
    
    // 任务相关
    func fetchTasks(categoryId: UUID) -> AnyPublisher<[Task], Error>
    func createTask(_ task: Task) -> AnyPublisher<Task, Error>
    func updateTask(_ task: Task) -> AnyPublisher<Task, Error>
    func deleteTask(_ taskId: UUID) -> AnyPublisher<Bool, Error>
    
    // 本地数据加载和保存
    func loadCategories() -> [Category]
    func saveCategories(_ categories: [Category])
    func loadTasks() -> [UUID: [Task]]
    func saveTasks(_ tasks: [UUID: [Task]])
} 