import SwiftUI

// MARK: - Data Models
struct ProfileData {
    let profileImage: String
    let name: String
    let deviceInfo: String
}

struct TileItem: Hashable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let additionalInfo: String
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var selectedItem: TileItem?
    
    let profileData = ProfileData(
        profileImage: "person.crop.circle.fill",
        name: "David Grossman",
        deviceInfo: "iPad (A16) Wi-Fi"
    )
    
    let tileItems = [
        TileItem(
            title: "YouTube",
            description: "https://youtu.be/mm8cn53_pdU",
            iconName: "play.rectangle.fill",
            additionalInfo: "Allowed video streaming platform. User has access to YouTube content with parental controls enabled."
        ),
        TileItem(
            title: "Safari",
            description: "Web browser application",
            iconName: "safari",
            additionalInfo: "Default web browser. Configured with content filtering and restricted access to certain websites."
        ),
        TileItem(
            title: "Music",
            description: "Audio streaming service",
            iconName: "music.note",
            additionalInfo: "Music app with curated playlists. Explicit content is blocked by parental controls."
        ),
        TileItem(
            title: "App Store",
            description: "Application marketplace",
            iconName: "square.stack.fill",
            additionalInfo: "Limited access to App Store. Only approved apps can be downloaded and installed."
        ),
        TileItem(
            title: "Books",
            description: "Digital reading platform",
            iconName: "book.fill",
            additionalInfo: "Access to age-appropriate books and educational content. Restricted from mature publications."
        ),
        TileItem(
            title: "Photos",
            description: "Photo and video library",
            iconName: "photo.fill",
            additionalInfo: "Full access to photo library. Can view, organize, and edit photos taken on device."
        )
    ]
    
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
                        Image(systemName: profileData.profileImage)
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileData.name)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(profileData.deviceInfo)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .padding(.bottom, 8)
                    
                    // Scrollable tiles
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(tileItems, id: \.id) { item in
                                NavigationLink(value: item) {
                                    TileView(item: item)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationDestination(for: TileItem.self) { item in
                DetailView(item: item)
            }
        }
    }
}

// MARK: - Tile View
struct TileView: View {
    let item: TileItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Image(systemName: "minus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Detail View
struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    let item: TileItem
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // White top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .foregroundColor(.blue)
                .background(Color.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with icon and title
                        HStack(spacing: 16) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                                .frame(width: 60, height: 60)
                                .background(Color.white)
                                .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 24, weight: .bold))
                                
                                Text(item.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Information section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal)
                            
                            Text(item.additionalInfo)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(nil)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
