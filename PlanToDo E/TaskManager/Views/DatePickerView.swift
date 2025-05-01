import SwiftUI

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @StateObject private var viewModel = CalendarViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("取消")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("选择日期")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("确定")
                        .bold()
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            
            // 日历组件
            SimpleCalendarView(
                selectedDate: $selectedDate,
                viewModel: viewModel
            )
            
            // 时间选择器
            VStack(spacing: 12) {
                Text("选择时间")
                    .font(.headline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .padding()
            
            Spacer()
        }
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // 确保视图模型的日期与选定日期同步
            viewModel.selectedDate = selectedDate
        }
    }
}

struct DatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerView(selectedDate: .constant(Date()))
    }
} 