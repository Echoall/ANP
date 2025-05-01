import SwiftUI

struct AnalyticsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // 模拟数据
    private let completionRateByCategory = [
        ("工作", 0.75),
        ("学习", 0.60),
        ("个人", 0.85),
        ("健康", 0.45)
    ]
    
    private let taskCompletionByDay = [
        ("周一", 5, 2),
        ("周二", 4, 3),
        ("周三", 6, 6),
        ("周四", 3, 2),
        ("周五", 7, 5),
        ("周六", 2, 2),
        ("周日", 1, 1)
    ]
    
    private let timeDistribution = [
        ("工作", 40),
        ("学习", 25),
        ("个人", 15),
        ("健康", 20)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("数据分析")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    // 未来功能：导出分析报告
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            
            ScrollView {
                VStack(spacing: 25) {
                    // 总体概览
                    VStack(alignment: .leading, spacing: 12) {
                        Text("总体完成情况")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            AnalyticsStat(title: "总任务数", value: "42", iconName: "checklist", color: .blue)
                            AnalyticsStat(title: "已完成", value: "28", iconName: "checkmark.circle.fill", color: .green)
                            AnalyticsStat(title: "完成率", value: "67%", iconName: "chart.pie.fill", color: .orange)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 按类别完成率
                    VStack(alignment: .leading, spacing: 12) {
                        Text("按类别完成率")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            ForEach(completionRateByCategory, id: \.0) { category in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(category.0)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(category.1 * 100))%")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    ProgressBar(value: category.1, color: categoryColor(for: category.0))
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 按天完成情况
                    VStack(alignment: .leading, spacing: 12) {
                        Text("一周任务完成情况")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        BarChart(data: taskCompletionByDay)
                            .frame(height: 220)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 时间分配
                    VStack(alignment: .leading, spacing: 12) {
                        Text("时间分配")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        PieChart(data: timeDistribution)
                            .frame(height: 200)
                            .padding(.horizontal)
                        
                        // 图例
                        HStack {
                            ForEach(timeDistribution, id: \.0) { item in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(categoryColor(for: item.0))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(item.0)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 效率提升建议
                    VStack(alignment: .leading, spacing: 12) {
                        Text("效率提升建议")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            EfficiencyTip(
                                title: "提高健康类任务完成率",
                                description: "健康类任务完成率较低，建议重新审视并调整计划，或考虑设置提醒。",
                                iconName: "heart.fill"
                            )
                            
                            EfficiencyTip(
                                title: "合理分配周中任务",
                                description: "周三任务较多，考虑将部分任务分配到周二和周四，保持均衡负载。",
                                iconName: "calendar"
                            )
                            
                            EfficiencyTip(
                                title: "增加学习时间",
                                description: "根据你的目标，建议增加学习类任务的时间分配，以达到更好的平衡。",
                                iconName: "book.fill"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationBarHidden(true)
    }
    
    // 根据类别返回颜色
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "工作":
            return .blue
        case "学习":
            return .purple
        case "个人":
            return .orange
        case "健康":
            return .green
        default:
            return .gray
        }
    }
}

// 统计指标组件
struct AnalyticsStat: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// 进度条组件
struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 10)
                    .opacity(0.2)
                    .foregroundColor(Color(.systemGray4))
                    .cornerRadius(5)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: 10)
                    .foregroundColor(color)
                    .cornerRadius(5)
            }
        }
        .frame(height: 10)
    }
}

// 柱状图组件
struct BarChart: View {
    let data: [(String, Int, Int)] // (标签, 总任务数, 已完成任务数)
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(data, id: \.0) { item in
                VStack(spacing: 8) {
                    ZStack(alignment: .bottom) {
                        // 总任务柱
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 25, height: CGFloat(item.1) * 20)
                        
                        // 已完成任务柱
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 25, height: CGFloat(item.2) * 20)
                    }
                    .cornerRadius(4)
                    
                    Text(item.0)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

// 饼图组件
struct PieChart: View {
    let data: [(String, Int)]
    
    private var total: Int {
        data.reduce(0) { $0 + $1.1 }
    }
    
    private func angle(for value: Int) -> Double {
        Double(value) / Double(total) * 360
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<data.count, id: \.self) { i in
                    let startAngle = self.startAngle(at: i)
                    let endAngle = startAngle + angle(for: data[i].1)
                    
                    PieSlice(
                        startAngle: Angle(degrees: startAngle),
                        endAngle: Angle(degrees: endAngle),
                        color: categoryColor(for: data[i].0)
                    )
                }
                
                // 中心圆形
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                
                // 中心文字
                VStack {
                    Text("总计")
                        .font(.headline)
                    Text("\(total)小时")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func startAngle(at index: Int) -> Double {
        var sum = 0
        for i in 0..<index {
            sum += data[i].1
        }
        return Double(sum) / Double(total) * 360
    }
    
    // 根据类别返回颜色
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "工作":
            return .blue
        case "学习":
            return .purple
        case "个人":
            return .orange
        case "健康":
            return .green
        default:
            return .gray
        }
    }
}

// 饼图切片
struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle - Angle(degrees: 90),
                    endAngle: endAngle - Angle(degrees: 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// 效率提升建议组件
struct EfficiencyTip: View {
    let title: String
    let description: String
    let iconName: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
} 