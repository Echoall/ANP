import Foundation
import Combine

// 云存储服务实现
class CloudStorageService: ObservableObject, StorageServiceProtocol {
    static let shared = CloudStorageService()
    
    // 存储数据
    private var categories: [Category] = []
    private var tasks: [UUID: [Task]] = [:] // categoryId: [Task]
    
    // 存储路径
    private let categoriesFileName = "categories.json"
    private let tasksFileName = "tasks.json"
    
    private init() {
        // 加载本地数据
        loadDataFromLocal()
    }
    
    // MARK: - 基本存储操作
    
    // 保存数据到本地
    private func saveDataToLocal() {
        saveCategories(categories)
        saveTasks(tasks)
    }
    
    // 加载本地数据
    private func loadDataFromLocal() {
        self.categories = loadCategories()
        self.tasks = loadTasks()
    }
    
    // MARK: - 存储服务协议实现
    
    // 加载本地分类
    func loadCategories() -> [Category] {
        let fileURL = getDocumentsDirectory().appendingPathComponent(categoriesFileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let categories = try JSONDecoder().decode([Category].self, from: data)
            print("从本地加载了 \(categories.count) 个分类")
            return categories
        } catch {
            print("加载分类数据失败或文件不存在: \(error.localizedDescription)")
            return []
        }
    }
    
    // 保存分类到本地
    func saveCategories(_ categories: [Category]) {
        do {
            let data = try JSONEncoder().encode(categories)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(categoriesFileName))
            print("分类数据保存成功")
        } catch {
            print("保存分类数据失败: \(error.localizedDescription)")
        }
    }
    
    // 保存任务到本地
    func saveTasks(_ tasks: [UUID: [Task]]) {
        do {
            // 将字典转换为可编码结构
            var encodableTasks: [[String: Any]] = []
            for (categoryId, taskList) in tasks {
                // 先编码任务数组为Data
                let taskData = try JSONEncoder().encode(taskList)
                
                // 再将Data转为Dictionary数组
                guard let taskArray = try JSONSerialization.jsonObject(with: taskData) as? [[String: Any]] else {
                    throw StorageError.encodingError
                }
                
                encodableTasks.append([
                    "categoryId": categoryId.uuidString,
                    "tasks": taskArray
                ])
            }
            
            let data = try JSONSerialization.data(withJSONObject: encodableTasks)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(tasksFileName))
            print("任务数据保存成功")
        } catch {
            print("保存任务数据失败: \(error.localizedDescription)")
        }
    }
    
    // 加载本地任务
    func loadTasks() -> [UUID: [Task]] {
        let fileURL = getDocumentsDirectory().appendingPathComponent(tasksFileName)
        var result: [UUID: [Task]] = [:]
        
        do {
            let data = try Data(contentsOf: fileURL)
            if let decodedArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for item in decodedArray {
                    if let categoryIdString = item["categoryId"] as? String,
                       let categoryId = UUID(uuidString: categoryIdString),
                       let taskData = try? JSONSerialization.data(withJSONObject: item["tasks"] ?? []),
                       let tasks = try? JSONDecoder().decode([Task].self, from: taskData) {
                        result[categoryId] = tasks
                    }
                }
            }
            print("从本地加载了\(result.count)个分类的任务")
            return result
        } catch {
            print("加载任务数据失败或文件不存在: \(error.localizedDescription)")
            return [:]
        }
    }
    
    // 获取文档目录
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - 分类相关方法
    
    func fetchCategories() -> AnyPublisher<[Category], Error> {
        return Future<[Category], Error> { promise in
            promise(.success(self.categories))
        }
        .eraseToAnyPublisher()
    }
    
    func createCategory(_ category: Category) -> AnyPublisher<Category, Error> {
        return Future<Category, Error> { promise in
            self.categories.append(category)
            self.saveCategories(self.categories)
            promise(.success(category))
        }
        .eraseToAnyPublisher()
    }
    
    func updateCategory(_ category: Category) -> AnyPublisher<Category, Error> {
        return Future<Category, Error> { promise in
            if let index = self.categories.firstIndex(where: { $0.id == category.id }) {
                self.categories[index] = category
                self.saveCategories(self.categories)
                promise(.success(category))
            } else {
                promise(.failure(StorageError.dataNotFound))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteCategory(_ categoryId: UUID) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.categories.removeAll { $0.id == categoryId }
            self.tasks[categoryId] = nil
            self.saveCategories(self.categories)
            self.saveTasks(self.tasks)
            promise(.success(true))
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 任务相关方法
    
    func fetchTasks(categoryId: UUID) -> AnyPublisher<[Task], Error> {
        return Future<[Task], Error> { promise in
            let categoryTasks = self.tasks[categoryId] ?? []
            promise(.success(categoryTasks))
        }
        .eraseToAnyPublisher()
    }
    
    func createTask(_ task: Task) -> AnyPublisher<Task, Error> {
        return Future<Task, Error> { promise in
            if self.tasks[task.categoryId] == nil {
                self.tasks[task.categoryId] = []
            }
            self.tasks[task.categoryId]?.append(task)
            self.saveTasks(self.tasks)
            promise(.success(task))
        }
        .eraseToAnyPublisher()
    }
    
    func updateTask(_ task: Task) -> AnyPublisher<Task, Error> {
        return Future<Task, Error> { promise in
            if let index = self.tasks[task.categoryId]?.firstIndex(where: { $0.id == task.id }) {
                self.tasks[task.categoryId]?[index] = task
                self.saveTasks(self.tasks)
                promise(.success(task))
            } else {
                promise(.failure(StorageError.dataNotFound))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteTask(_ taskId: UUID) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            for (categoryId, tasks) in self.tasks {
                if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                    self.tasks[categoryId]?.remove(at: index)
                    self.saveTasks(self.tasks)
                    promise(.success(true))
                    return
                }
            }
            promise(.failure(StorageError.dataNotFound))
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 工具方法
    
    // 清除所有本地数据（用于测试或重置）
    func clearAllLocalData() {
        do {
            try FileManager.default.removeItem(at: getDocumentsDirectory().appendingPathComponent(categoriesFileName))
            try FileManager.default.removeItem(at: getDocumentsDirectory().appendingPathComponent(tasksFileName))
            print("所有本地数据已清除")
            
            // 清空内存中的数据
            self.categories = []
            self.tasks = [:]
        } catch {
            print("清除本地数据失败: \(error.localizedDescription)")
        }
    }
    
    // 兼容StorageService调用
    func clearAllData() {
        clearAllLocalData()
    }
    
    // 获取本地存储数据大小（单位：字节）
    func getLocalStorageSize() -> Int {
        var totalSize = 0
        
        let fileURLs = [getDocumentsDirectory().appendingPathComponent(categoriesFileName),
                        getDocumentsDirectory().appendingPathComponent(tasksFileName)]
        
        for url in fileURLs {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? Int {
                    totalSize += fileSize
                }
            } catch {
                // 文件可能不存在，忽略错误
            }
        }
        
        return totalSize
    }
} 