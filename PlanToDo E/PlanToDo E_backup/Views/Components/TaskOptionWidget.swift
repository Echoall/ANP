import SwiftUI

struct TaskOptionWidget<Content: View>: View {
    let title: String
    let iconName: String
    let content: Content
    
    init(title: String, iconName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content
                .padding(.leading, 4)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 