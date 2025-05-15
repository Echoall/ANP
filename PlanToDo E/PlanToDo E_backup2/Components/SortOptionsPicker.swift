import SwiftUI

struct SortOptionsPicker: View {
    @Binding var selectedOption: SortOption
    
    var body: some View {
        Menu {
            Button(action: {
                selectedOption = .dueDate
            }) {
                HStack {
                    Text("按截止日期")
                    Spacer()
                    if selectedOption == .dueDate {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: {
                selectedOption = .priority
            }) {
                HStack {
                    Text("按优先级")
                    Spacer()
                    if selectedOption == .priority {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: {
                selectedOption = .title
            }) {
                HStack {
                    Text("按标题")
                    Spacer()
                    if selectedOption == .title {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: {
                selectedOption = .created
            }) {
                HStack {
                    Text("按创建时间")
                    Spacer()
                    if selectedOption == .created {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16))
                .padding(10)
                .background(Color.taskGroupBackground)
                .cornerRadius(8)
        }
    }
} 