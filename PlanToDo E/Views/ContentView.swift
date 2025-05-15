import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            Text("主内容区域")
                .navigationTitle("PlantoDo")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: APITestView()) {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            NavigationLink(destination: APITestView()) {
                                Label("API测试", systemImage: "network")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 