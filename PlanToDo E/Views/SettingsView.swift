import SwiftUI

struct SettingsView: View {
    @ObservedObject private var storageStatus = StorageStatusService.shared
    @State private var showClearDataAlert = false
    @State private var showingClearConfirmation = false
    @State private var showClearSuccess = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("存储状态")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("本地存储")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("iCloud")
                            Spacer()
                            if storageStatus.isCloudAvailable {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        HStack {
                            Text("同步状态")
                            Spacer()
                            switch storageStatus.syncStatus {
                            case .syncing:
                                ProgressView()
                                    .padding(.trailing, 5)
                                Text("正在同步")
                                    .foregroundColor(.blue)
                            case .synced:
                                Text("已同步")
                                    .foregroundColor(.green)
                            case .failed:
                                Text("同步失败")
                                    .foregroundColor(.red)
                            case .offline:
                                Text("离线")
                                    .foregroundColor(.gray)
                            case .unknown:
                                Text("未知")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if let lastLocalSave = storageStatus.lastLocalSaveTime {
                            Text("最后本地保存: \(lastLocalSave.formatted(date: .abbreviated, time: .standard))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let lastCloudSync = storageStatus.lastCloudSyncTime {
                            Text("最后云同步: \(lastCloudSync.formatted(date: .abbreviated, time: .standard))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(storageStatus.storageInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("数据管理")) {
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Text("清除所有数据")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showingClearConfirmation) {
                        Alert(
                            title: Text("确认清除"),
                            message: Text("此操作将删除所有本地数据，且无法恢复。确定要继续吗？"),
                            primaryButton: .destructive(Text("清除")) {
                                StorageService.shared.clearAllLocalData()
                                withAnimation {
                                    showClearSuccess = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showClearSuccess = false
                                    }
                                }
                            },
                            secondaryButton: .cancel(Text("取消"))
                        )
                    }
                }
                
                Section(header: Text("关于")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PlanToDo")
                            .font(.headline)
                        Text("版本 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("这是一个使用SwiftUI构建的任务管理应用，支持本地存储和iCloud同步")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("设置")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 