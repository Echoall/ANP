import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImageName: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImageName: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImageName = systemImageName
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImageName)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.taskText)
            
            Text(message)
                .font(.body)
                .foregroundColor(.taskSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding(30)
    }
} 