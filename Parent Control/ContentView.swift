import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @State private var viewModel = ParentalControlViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gray background
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // White navigation bar
                    HStack {
                        Text("Parental Controls")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Spacer()
                        
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding()
                    .background(Color.white)
                    
                    // Profile section on gray background (not scrollable)
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.childData.childImage)
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.childData.name)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(viewModel.childData.deviceInfo)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .padding(.bottom, 8)
                    
                    // Scrollable apps
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.appItems) { item in
                                NavigationLink(value: item) {
                                    TileView(
                                        item: item,
                                        onIncrease: { viewModel.increaseAccess(for: item) },
                                        onDecrease: { viewModel.decreaseAccess(for: item) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationDestination(for: AppItem.self) { item in
                DetailView(item: item)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
