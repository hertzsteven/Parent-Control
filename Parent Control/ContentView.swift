import SwiftUI

// MARK: - Main Content View
/// Main parental control view displaying child profile and controlled apps
struct ContentView: View {
    @State private var viewModel = ParentalControlViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    navigationBar
                    ChildProfileHeaderView(childData: viewModel.childData)
                    appListSection
                }
            }
            .navigationDestination(for: AppItem.self) { item in
                DetailView(item: item)
            }
        }
    }
    
    // MARK: - View Components
    
    /// Top navigation bar with title and menu button
    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            Text("Parental Controls")
                .font(AppTheme.Typography.navigationTitle)
            
            Spacer()
            
            Button(action: { /* TODO: Add menu functionality */ }) {
                Image(systemName: "ellipsis")
                    .font(AppTheme.Typography.navigationTitle)
            }
        }
        .navigationBarStyle()
    }
    
    /// Scrollable list of controlled apps with access controls
    @ViewBuilder
    private var appListSection: some View {
        if viewModel.appItems.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(viewModel.appItems) { item in
                        appItemRow(for: item)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
    }
    
    /// Individual app row with navigation and access controls
    @ViewBuilder
    private func appItemRow(for item: AppItem) -> some View {
        NavigationLink(value: item) {
            TileView(
                item: item,
                onIncrease: { viewModel.increaseAccess(for: item) },
                onDecrease: { viewModel.decreaseAccess(for: item) }
            )
        }
        .buttonStyle(.navigationLink)
    }
    
    /// Empty state view when no apps are being controlled
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "apps.iphone")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Apps to Display")
                .font(AppTheme.Typography.childName)
            
            Text("Add apps to start managing access controls")
                .font(AppTheme.Typography.deviceInfo)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
    }
}

// MARK: - Previews
#Preview("Default") {
    ContentView()
}

#Preview("Empty State") {
    let viewModel = ParentalControlViewModel()
    viewModel.appItems = []
    
    return ContentView()
}

#Preview("Single App") {
    let viewModel = ParentalControlViewModel()
    viewModel.appItems = [
        AppItem(
            title: "YouTube",
            description: "Video streaming",
            iconName: "play.rectangle.fill",
            additionalInfo: "Allowed with restrictions"
        )
    ]
    
    return ContentView()
}
