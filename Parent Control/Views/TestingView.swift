//
//  TestingView.swift
//  Parent Control
//
//  Temporary testing screen for API exploration
//

import SwiftUI

struct TestingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var viewModel = ParentalControlViewModel()
    @State private var showResults = false
    @State private var firstDeviceApps: [(name: String, bundleId: String, vendor: String, version: String, iconURL: String)] = []
    @State private var appLockResult: String?
    @State private var isTestingAppLock = false
    @State private var unlockResult: String?
    @State private var isTestingUnlock = false
    @State private var classesResult: String?
    @State private var isLoadingClasses = false
    @State private var classList: [ClassListItem] = []
    @State private var teacherGroupsResult: String?
    @State private var isLoadingTeacherGroups = false
    @State private var teacherGroupsList: [TeacherGroup] = []
    @State private var combinedResult: String?
    @State private var isLoadingCombined = false
    @State private var matchedGroupsAndClasses: [(group: TeacherGroup, class: ClassListItem?)] = []
    @State private var authResult: String?
    @State private var isAuthenticating = false
    @State private var showAuthPrompt = false
    @State private var teacherUsername: String = ""
    @State private var teacherPassword: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("API Testing Screen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Temporary screen for exploring Zuludesk API")
                    .foregroundColor(.secondary)
                
                // User info and logout
                if let user = authManager.authenticatedUser {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Logged in as: \(user.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let token = authManager.token {
                                Text("Token: \(token.prefix(8))...")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            authManager.logout()
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding()
                
                // Loading indicator
                if viewModel.isLoading {
                    ProgressView("Fetching from Zuludesk API...")
                        .padding()
                }
                
                // Fetch button
                Button {
                    showResults = false
                    firstDeviceApps = []
                    Task {
                        await viewModel.loadData()
                        showResults = true
                        
                        // Extract first device apps for display
                        if let firstDevice = viewModel.deviceDTOs.first,
                           let apps = firstDevice.apps {
                            firstDeviceApps = apps.map { app in
                                (
                                    name: app.name ?? "Unknown",
                                    bundleId: app.identifier ?? "no bundle ID",
                                    vendor: app.vendor ?? "Unknown",
                                    version: app.version ?? "N/A",
                                    iconURL: app.icon ?? ""
                                )
                            }
                        }
                        
                        printResults()
                    }
                } label: {
                    Label("Fetch Devices & Apps", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                
                // Test App Lock button
                Button {
                    Task {
                        isTestingAppLock = true
                        appLockResult = nil
                        await testAppLock()
                        isTestingAppLock = false
                    }
                } label: {
                    Label("Test App Lock", systemImage: "lock.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isTestingAppLock)
                .padding(.horizontal)
                
                // Test Unlock button
                Button {
                    Task {
                        isTestingUnlock = true
                        unlockResult = nil
                        await testUnlock()
                        isTestingUnlock = false
                    }
                } label: {
                    Label("Test Unlock", systemImage: "lock.open.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isTestingUnlock)
                .padding(.horizontal)
                
                // Fetch Classes button
                Button {
                    Task {
                        isLoadingClasses = true
                        classesResult = nil
                        classList = []
                        await fetchClassesList()
                        isLoadingClasses = false
                    }
                } label: {
                    Label("Fetch Classes List", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isLoadingClasses)
                .padding(.horizontal)
                
                // Fetch Teacher Groups button
                Button {
                    Task {
                        isLoadingTeacherGroups = true
                        teacherGroupsResult = nil
                        teacherGroupsList = []
                        await fetchTeacherGroups()
                        isLoadingTeacherGroups = false
                    }
                } label: {
                    Label("Fetch Teacher Groups", systemImage: "person.3.sequence")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isLoadingTeacherGroups)
                .padding(.horizontal)
                
                // Fetch Combined Groups & Classes button
                Button {
                    Task {
                        isLoadingCombined = true
                        combinedResult = nil
                        matchedGroupsAndClasses = []
                        await fetchCombinedGroupsAndClasses()
                        isLoadingCombined = false
                    }
                } label: {
                    Label("Fetch Groups + Classes", systemImage: "link.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isLoadingCombined)
                .padding(.horizontal)
                
                // Teacher Authentication button
                Button {
                    showAuthPrompt = true
                } label: {
                    Label("Authenticate Teacher", systemImage: "person.badge.key.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isAuthenticating)
                .padding(.horizontal)
                .sheet(isPresented: $showAuthPrompt) {
                    NavigationStack {
                        VStack(spacing: 20) {
                            Text("Enter Teacher Credentials")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top)
                            
                            VStack(spacing: 16) {
                                // Username field
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                        .frame(width: 30)
                                    TextField("Username", text: $teacherUsername)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                }
                                .padding(.horizontal)
                                
                                // Password field
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                        .frame(width: 30)
                                    SecureField("Password", text: $teacherPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                            
                            Spacer()
                            
                            // Authenticate button
                            Button {
                                showAuthPrompt = false
                                Task {
                                    isAuthenticating = true
                                    authResult = nil
                                    await testTeacherAuth()
                                    isAuthenticating = false
                                }
                            } label: {
                                Text("Authenticate")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(teacherUsername.isEmpty || teacherPassword.isEmpty ? Color.gray : Color.pink)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(teacherUsername.isEmpty || teacherPassword.isEmpty)
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    showAuthPrompt = false
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
                
                // App Lock result display
                if let appLockResult = appLockResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appLockResult.contains("✅") ? "Success" : "Result", 
                              systemImage: appLockResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(appLockResult.contains("✅") ? .green : .blue)
                        Text(appLockResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((appLockResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for app lock
                if isTestingAppLock {
                    ProgressView("Testing App Lock...")
                        .padding()
                }
                
                // Unlock result display
                if let unlockResult = unlockResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(unlockResult.contains("✅") ? "Success" : "Result", 
                              systemImage: unlockResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(unlockResult.contains("✅") ? .green : .blue)
                        Text(unlockResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((unlockResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for unlock
                if isTestingUnlock {
                    ProgressView("Testing Unlock...")
                        .padding()
                }
                
                // Classes result display
                if let classesResult = classesResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(classesResult.contains("✅") ? "Success" : "Result", 
                              systemImage: classesResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(classesResult.contains("✅") ? .green : .blue)
                        Text(classesResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((classesResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for classes
                if isLoadingClasses {
                    ProgressView("Fetching Classes...")
                        .padding()
                }
                
                // Classes list display
                if !classList.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📚 Classes (\(classList.count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(classList, id: \.uuid) { classItem in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "person.3.fill")
                                                .foregroundColor(.green)
                                            Text(classItem.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        if let description = classItem.description {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        HStack(spacing: 16) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "person.fill")
                                                    .font(.caption2)
                                                Text("\(classItem.studentCount) students")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.blue)
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "person.badge.key.fill")
                                                    .font(.caption2)
                                                Text("\(classItem.teacherCount) teachers")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.purple)
                                        }
                                        
                                        Text("UUID: \(classItem.uuid)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 400)
                    }
                }
                
                // Teacher Groups result display
                if let teacherGroupsResult = teacherGroupsResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(teacherGroupsResult.contains("✅") ? "Success" : "Result", 
                              systemImage: teacherGroupsResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(teacherGroupsResult.contains("✅") ? .green : .blue)
                        Text(teacherGroupsResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((teacherGroupsResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for teacher groups
                if isLoadingTeacherGroups {
                    ProgressView("Fetching Teacher Groups...")
                        .padding()
                }
                
                // Teacher groups list display
                if !teacherGroupsList.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("👥 Teacher Groups (\(teacherGroupsList.count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(teacherGroupsList, id: \.id) { group in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "person.3.sequence.fill")
                                                .foregroundColor(.teal)
                                            Text(group.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            
                                            Spacer()
                                            
                                            // Color indicator
                                            if let colorId = group.colorId, colorId > 0 {
                                                Circle()
                                                    .fill(Color.teal)
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                        
                                        if let description = group.description, !description.isEmpty {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let classNumber = group.classNumber, !classNumber.isEmpty {
                                            HStack(spacing: 4) {
                                                Image(systemName: "number")
                                                    .font(.caption2)
                                                Text("Class: \(classNumber)")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.blue)
                                        }
                                        
                                        HStack(spacing: 12) {
                                            if let isShared = group.isShared {
                                                HStack(spacing: 4) {
                                                    Image(systemName: isShared ? "person.2.fill" : "person.fill")
                                                        .font(.caption2)
                                                    Text(isShared ? "Shared" : "Private")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(isShared ? .green : .gray)
                                            }
                                            
                                            if let isEditable = group.isEditable {
                                                HStack(spacing: 4) {
                                                    Image(systemName: isEditable ? "pencil" : "lock.fill")
                                                        .font(.caption2)
                                                    Text(isEditable ? "Editable" : "Read-only")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(isEditable ? .purple : .orange)
                                            }
                                        }
                                        
                                        Text("ID: \(group.id)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 400)
                    }
                }
                
                // Combined result display
                if let combinedResult = combinedResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(combinedResult.contains("✅") ? "Success" : "Result", 
                              systemImage: combinedResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(combinedResult.contains("✅") ? .green : .blue)
                        Text(combinedResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((combinedResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for combined
                if isLoadingCombined {
                    ProgressView("Fetching and Matching Data...")
                        .padding()
                }
                
                // Teacher Authentication result display
                if let authResult = authResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(authResult.contains("✅") ? "Success" : "Result", 
                              systemImage: authResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(authResult.contains("✅") ? .green : .blue)
                        Text(authResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((authResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for authentication
                if isAuthenticating {
                    ProgressView("Authenticating Teacher...")
                        .padding()
                }
                
                // Matched groups and classes display
                if !matchedGroupsAndClasses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔗 Matched Groups & Classes (\(matchedGroupsAndClasses.count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(matchedGroupsAndClasses.indices, id: \.self) { index in
                                    let item = matchedGroupsAndClasses[index]
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Group information
                                        HStack {
                                            Image(systemName: "person.3.sequence.fill")
                                                .foregroundColor(.indigo)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Group: \(item.group.name)")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                Text("ID: \(item.group.id)")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        // Matched class information
                                        if let matchedClass = item.class {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Matched Class: \(matchedClass.name)")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.green)
                                                    Text("UUID: \(matchedClass.uuid)")
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                        .lineLimit(1)
                                                }
                                            }
                                            
                                            HStack(spacing: 16) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "person.fill")
                                                        .font(.caption2)
                                                    Text("\(matchedClass.studentCount) students")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(.blue)
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "person.badge.key.fill")
                                                        .font(.caption2)
                                                    Text("\(matchedClass.teacherCount) teachers")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(.purple)
                                            }
                                            .padding(.top, 4)
                                        } else {
                                            HStack {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.orange)
                                                Text("No matching class found")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.indigo.opacity(0.05))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.indigo.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 500)
                    }
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Error", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Results display
                if showResults {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Results", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        HStack {
                            Text("Apps:")
                                .fontWeight(.semibold)
                            Text("\(viewModel.appItems.count)")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Devices:")
                                .fontWeight(.semibold)
                            Text("\(viewModel.devices.count)")
                                .foregroundColor(.blue)
                        }
                        
                        Text("Check console for detailed output ↓")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // First Device Apps Display
                if !firstDeviceApps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📱 \(viewModel.deviceDTOs.first?.name ?? "Device") Apps (\(firstDeviceApps.count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(firstDeviceApps, id: \.bundleId) { app in
                                    HStack(spacing: 12) {
                                        // App icon from URL
                                        AsyncImage(url: URL(string: app.iconURL)) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } placeholder: {
                                            Image(systemName: "app.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(10)
                                        
                                        // App info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(app.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(app.vendor)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(app.bundleId)
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(app.version)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 600)
                    }
                }
                
                Spacer()
                
                // Detailed results section
                if showResults {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Devices section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Devices:")
                                    .font(.headline)
                                
                                ForEach(viewModel.devices) { device in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: device.iconName)
                                                .foregroundColor(device.color)
                                            Text(device.name)
                                                .fontWeight(.medium)
                                        }
                                        Text("\(device.appIds.count) apps")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                            
                            Divider()
                            
                            // Apps section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Apps:")
                                    .font(.headline)
                                
                                ForEach(viewModel.appItems) { app in
                                    HStack {
                                        Image(systemName: app.iconName)
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text(app.title)
                                                .fontWeight(.medium)
                                            Text(app.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.05))
                }
            }
            .navigationTitle("🧪 Testing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Print detailed results to console
    private func printResults() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 ZULUDESK API TEST RESULTS")
        print(String(repeating: "=", count: 60))
        
        print("\n📱 DEVICES (\(viewModel.devices.count)):")
        print(String(repeating: "-", count: 60))
        for (index, device) in viewModel.devices.enumerated() {
            print("\n[\(index + 1)] \(device.name)")
            print("    ID: \(device.id)")
            print("    Icon: \(device.iconName)")
            print("    Color: \(device.ringColor)")
            print("    Apps on device: \(device.appIds.count)")
            print("    App IDs: \(device.appIds.map { $0.uuidString.prefix(8) }.joined(separator: ", "))")
        }
        
        print("\n\n📲 APPS (\(viewModel.appItems.count)):")
        print(String(repeating: "-", count: 60))
        for (index, app) in viewModel.appItems.enumerated() {
            print("\n[\(index + 1)] \(app.title)")
            print("    ID: \(app.id.uuidString.prefix(8))...")
            print("    Description: \(app.description)")
            print("    Icon: \(app.iconName)")
            print("    Info: \(app.additionalInfo.components(separatedBy: "\n").first ?? "")")
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("✅ Test completed!")
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    // Test app lock API call (with device owner setup first)
    private func testAppLock() async {
        print("\n" + String(repeating: "=", count: 80))
        print("🔒 TESTING TWO-STEP APP LOCK PROCESS")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            // Test parameters
            let deviceUDID = "00008120-0012391420214032"
            let userId = "143"
            let bundleId = "com.thup.MonkeyMath"
            let clearAfter = 86400 // seconds
            guard let token = authManager.token else {
                appLockResult = "❌ No authentication token available"
                return
            }
            
            // STEP 1: Set Device Owner
            print("\n📍 STEP 1: Setting Device Owner")
            print(String(repeating: "-", count: 80))
            print("🔧 Device UDID: \(deviceUDID)")
            print("👤 User ID: \(userId)")
            
            let ownerResponse = try await networkService.setDeviceOwner(
                deviceUDID: deviceUDID,
                userId: userId
            )
            
            print("✅ Device Owner Set Successfully!")
            if let message = ownerResponse.message {
                print("📄 Response: \(message)")
            }
            
            // STEP 2: Apply App Lock (only if step 1 succeeded)
            print("\n📍 STEP 2: Applying App Lock")
            print(String(repeating: "-", count: 80))
            print("📱 Bundle ID: \(bundleId)")
            print("⏱️ Clear After: \(clearAfter) seconds")
            print("👨‍🎓 Student IDs: \(userId)")
            print("🔑 Token: \(token)")
            
            let lockResponse = try await networkService.applyAppLock(
                bundleId: bundleId,
                clearAfterSeconds: clearAfter,
                studentIds: [userId],
                token: token
            )
            
            print("\n✅ App Lock Applied Successfully!")
            if let message = lockResponse.message {
                print("📄 Response: \(message)")
            }
            print(String(repeating: "=", count: 80) + "\n")
            
            appLockResult = "✅ SUCCESS!\n\nStep 1: Device owner set to user \(userId)\nStep 2: App lock applied\n\nApp: \(bundleId)\nDuration: \(clearAfter) seconds\nStudent: \(userId)"
            
        } catch let error as NetworkError {
            print("\n❌ Process Failed!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            
            appLockResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Process Failed!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            
            appLockResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
    
    // Test unlock API call
    private func testUnlock() async {
        print("\n" + String(repeating: "=", count: 80))
        print("🔓 TESTING UNLOCK/STOP APP LOCK")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            let studentId = "143"
            guard let token = authManager.token else {
                unlockResult = "❌ No authentication token available"
                return
            }
            
            print("👤 Student ID: \(studentId)")
            print("🔑 Token: \(token)")
            
            let response = try await networkService.stopAppLock(
                studentId: studentId,
                token: token
            )
            
            print("\n✅ Unlock Successful!")
            print("Success: \(response.success ?? false)")
            if let tasks = response.tasks {
                print("Tasks: \(tasks.count)")
                for task in tasks {
                    print("  - Student: \(task.student)")
                    print("    UUID: \(task.UUID)")
                    print("    Status: \(task.status)")
                }
            }
            print(String(repeating: "=", count: 80) + "\n")
            
            let taskInfo = response.tasks?.first.map { 
                "\nStudent: \($0.student)\nStatus: \($0.status)" 
            } ?? ""
            unlockResult = "✅ SUCCESS!\n\nApp lock removed for student \(studentId)\(taskInfo)"
            
        } catch let error as NetworkError {
            print("\n❌ Unlock Failed!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            unlockResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Unlock Failed!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            unlockResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
    
    // Fetch classes list API call
    private func fetchClassesList() async {
        print("\n" + String(repeating: "=", count: 80))
        print("📚 FETCHING CLASSES LIST")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            let response = try await networkService.fetchClasses()
            
            print("\n✅ Classes Fetched Successfully!")
            print("Total Classes: \(response.classes.count)")
            print(String(repeating: "-", count: 80))
            
            for (index, classItem) in response.classes.enumerated() {
                print("\n[\(index + 1)] \(classItem.name)")
                print("    UUID: \(classItem.uuid)")
                if let description = classItem.description {
                    print("    Description: \(description)")
                }
                print("    Students: \(classItem.studentCount)")
                print("    Teachers: \(classItem.teacherCount)")
            }
            
            print("\n" + String(repeating: "=", count: 80) + "\n")
            
            // Update UI state
            classList = response.classes
            classesResult = "✅ SUCCESS!\n\nFetched \(response.classes.count) classes from the API"
            
        } catch let error as NetworkError {
            print("\n❌ Failed to Fetch Classes!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            classesResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Failed to Fetch Classes!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            classesResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
    
    // Fetch teacher groups API call
    private func fetchTeacherGroups() async {
        print("\n" + String(repeating: "=", count: 80))
        print("👥 FETCHING TEACHER GROUPS")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            guard let token = authManager.token else {
                teacherGroupsResult = "❌ No authentication token available"
                return
            }
            print("🔑 Token: \(token)")
            
            let response = try await networkService.fetchTeacherGroups(token: token)
            
            print("\n✅ Teacher Groups Fetched Successfully!")
            print("Response Code: \(response.code)")
            print("Total Groups: \(response.results.count)")
            print(String(repeating: "-", count: 80))
            
            for (index, group) in response.results.enumerated() {
                print("\n[\(index + 1)] \(group.name)")
                print("    ID: \(group.id)")
                if let description = group.description, !description.isEmpty {
                    print("    Description: \(description)")
                }
                if let classNumber = group.classNumber, !classNumber.isEmpty {
                    print("    Class Number: \(classNumber)")
                }
                if let colorId = group.colorId {
                    print("    Color ID: \(colorId)")
                }
                if let isShared = group.isShared {
                    print("    Shared: \(isShared)")
                }
                if let isEditable = group.isEditable {
                    print("    Editable: \(isEditable)")
                }
            }
            
            print("\n" + String(repeating: "=", count: 80) + "\n")
            
            // Update UI state
            teacherGroupsList = response.results
            teacherGroupsResult = "✅ SUCCESS!\n\nFetched \(response.results.count) teacher groups from the API"
            
        } catch let error as NetworkError {
            print("\n❌ Failed to Fetch Teacher Groups!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            teacherGroupsResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Failed to Fetch Teacher Groups!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            teacherGroupsResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
    
    // Fetch combined groups and classes with matching
    private func fetchCombinedGroupsAndClasses() async {
        print("\n" + String(repeating: "=", count: 80))
        print("🔗 FETCHING COMBINED GROUPS & CLASSES")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            guard let token = authManager.token else {
                combinedResult = "❌ No authentication token available"
                return
            }
            
            // Step 1: Fetch teacher groups
            print("\n📍 Step 1: Fetching Teacher Groups...")
            let groupsResponse = try await networkService.fetchTeacherGroups(token: token)
            print("✅ Fetched \(groupsResponse.results.count) teacher groups")
            
            // Step 2: Fetch classes
            print("\n📍 Step 2: Fetching Classes...")
            let classesResponse = try await networkService.fetchClasses()
            print("✅ Fetched \(classesResponse.classes.count) classes")
            
            // Step 3: Match groups with classes
            print("\n📍 Step 3: Matching Groups with Classes...")
            print(String(repeating: "-", count: 80))
            
            var matched: [(group: TeacherGroup, class: ClassListItem?)] = []
            var matchCount = 0
            
            for group in groupsResponse.results {
                // Try to find a matching class by name (case-insensitive)
                let matchedClass = classesResponse.classes.first { classItem in
                    classItem.name.lowercased() == group.name.lowercased()
                }
                
                matched.append((group: group, class: matchedClass))
                
                if let matchedClass = matchedClass {
                    matchCount += 1
                    print("\n✓ MATCH FOUND:")
                    print("  Group: \(group.name) (ID: \(group.id))")
                    print("  Class: \(matchedClass.name) (UUID: \(matchedClass.uuid))")
                    print("  Students: \(matchedClass.studentCount), Teachers: \(matchedClass.teacherCount)")
                } else {
                    print("\n✗ NO MATCH:")
                    print("  Group: \(group.name) (ID: \(group.id))")
                }
            }
            
            print("\n" + String(repeating: "=", count: 80))
            print("📊 SUMMARY:")
            print("   Total Groups: \(groupsResponse.results.count)")
            print("   Total Classes: \(classesResponse.classes.count)")
            print("   Matches Found: \(matchCount)")
            print("   Unmatched: \(groupsResponse.results.count - matchCount)")
            print(String(repeating: "=", count: 80) + "\n")
            
            // Update UI state
            matchedGroupsAndClasses = matched
            combinedResult = """
            ✅ SUCCESS!
            
            Fetched \(groupsResponse.results.count) groups
            Fetched \(classesResponse.classes.count) classes
            Found \(matchCount) matches
            """
            
        } catch let error as NetworkError {
            print("\n❌ Failed to Fetch Combined Data!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            combinedResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Failed to Fetch Combined Data!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            combinedResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
    
    // Test teacher authentication API call
    private func testTeacherAuth() async {
        print("\n" + String(repeating: "=", count: 80))
        print("👨‍🏫 TESTING TEACHER AUTHENTICATION")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            // Use hardcoded company ID and values from input fields
            let company = "2001128"
            let username = teacherUsername
            let password = teacherPassword
            
            print("\n🔧 Company: \(company)")
            print("👤 Username: \(username)")
            
            let response = try await networkService.authenticateTeacher(
                company: company,
                username: username,
                password: password
            )
            
            print("\n✅ Authentication Successful!")
            print(String(repeating: "-", count: 80))
            print("📊 Response Code: \(response.code)")
            print("🔑 Token: \(response.token)")
            print("🎯 Feature: \(response.feature)")
            print("\n👤 Authenticated User:")
            print("   ID: \(response.authenticatedAs.id)")
            print("   Company ID: \(response.authenticatedAs.companyId)")
            print("   Username: \(response.authenticatedAs.username)")
            print("   Name: \(response.authenticatedAs.name)")
            print("   First Name: \(response.authenticatedAs.firstName)")
            print("   Last Name: \(response.authenticatedAs.lastName)")
            print(String(repeating: "=", count: 80) + "\n")
            
            authResult = """
            ✅ SUCCESS!
            
            Token: \(response.token)
            
            Authenticated as: \(response.authenticatedAs.name)
            Username: \(response.authenticatedAs.username)
            User ID: \(response.authenticatedAs.id)
            Feature: \(response.feature)
            """
            
        } catch let error as NetworkError {
            print("\n❌ Authentication Failed!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            authResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Authentication Failed!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            authResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    TestingView()
        .environmentObject(AuthenticationManager())
}

