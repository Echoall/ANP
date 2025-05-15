import SwiftUI

struct SimpleCalendarView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    let onDateSelected: ((Date) -> Void)?
    
    init(selectedDate: Binding<Date>, viewModel: CalendarViewModel, onDateSelected: ((Date) -> Void)? = nil) {
        self._selectedDate = selectedDate
        self.viewModel = viewModel
        self.onDateSelected = onDateSelected
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 月份选择器
            HStack {
                Button {
                    if let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                        selectedDate = prevMonth
                        viewModel.selectedDate = selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(viewModel.monthYearFormatter.string(from: selectedDate))
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = nextMonth
                        viewModel.selectedDate = selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // 星期几标签
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 日历网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(viewModel.daysInMonth(), id: \.self) { date in
                    if let date = date {
                        // 日期单元格
                        VStack(spacing: 4) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 14))
                                .fontWeight(viewModel.isSameDay(date1: date, date2: Date()) ? .bold : .regular)
                                .foregroundColor(viewModel.isSameDay(date1: date, date2: selectedDate) ? .white : .primary)
                                .frame(width: 26, height: 26)
                                .background(
                                    Circle()
                                        .fill(viewModel.isSameDay(date1: date, date2: selectedDate) ? Color.blue : Color.clear)
                                )
                            
                            // 如果有任务，显示指示点
                            if viewModel.hasTasks(for: date) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = date
                            viewModel.selectedDate = date
                            onDateSelected?(date)
                        }
                    } else {
                        // 空白格子
                        Text("")
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding()
    }
    
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
}

struct SimpleCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleCalendarView(
            selectedDate: .constant(Date()),
            viewModel: CalendarViewModel()
        )
        .previewLayout(.sizeThatFits)
    }
} 