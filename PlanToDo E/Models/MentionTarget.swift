import Foundation

/// 提及目标模型，用于@功能
struct MentionTarget: Identifiable {
    let id: String
    let label: String
    let icon: String
    
    static let defaultTargets: [MentionTarget] = [
        MentionTarget(id: "task", label: "任务", icon: "checklist"),
        MentionTarget(id: "plan", label: "计划", icon: "calendar"),
        MentionTarget(id: "today", label: "今天", icon: "clock"),
        MentionTarget(id: "tomorrow", label: "明天", icon: "calendar.day.timeline.leading"),
        MentionTarget(id: "deadline", label: "截止日期", icon: "alarm")
    ]
} 