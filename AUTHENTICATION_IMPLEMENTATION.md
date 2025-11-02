# Teacher Authentication Implementation

## Overview
Implemented a secure teacher authentication system with token persistence using Keychain. The app now requires authentication at startup and uses the generated token for all API calls.

## What Was Implemented

### 1. AuthenticationManager (New File)
**Location:** `Parent Control/Services/AuthenticationManager.swift`

- **ObservableObject** that manages authentication state across the app
- **Keychain Storage** for secure token persistence (more secure than UserDefaults)
- **Properties:**
  - `token: String?` - The teacher authentication token
  - `isAuthenticated: Bool` - Authentication state
  - `authenticatedUser: AuthenticatedUser?` - User information

- **Methods:**
  - `authenticate(company:username:password:)` - Authenticates and saves token
  - `logout()` - Clears authentication and removes from Keychain
  - Private Keychain methods for secure storage

### 2. Updated Parent_ControlApp.swift
- Created `@StateObject` for `AuthenticationManager`
- Shows authentication modal sheet at app launch if not authenticated
- Passes `authManager` to all views via `.environmentObject()`
- Created `AuthenticationView` - beautiful login screen with:
  - Username and password fields
  - Error message display
  - Loading state during authentication
  - Cannot be dismissed until authenticated

### 3. Updated DeviceSelectionView.swift (Main App View)
- Added `@EnvironmentObject var authManager: AuthenticationManager`
- Passes authManager to the ParentalControlViewModel on view load
- Main device selection screen now uses authenticated token

### 4. Updated ParentalControlViewModel.swift
- Added optional `authManager: AuthenticationManager?` property
- Updated all API methods to use `authManager?.token` instead of hardcoded token:
  - `lockDeviceToApp()` - Uses dynamic token for app locking
  - `unlockDevice()` - Uses dynamic token for unlocking
  - `loadData()` - Uses dynamic token for fetching devices/classes
- Added token validation guards that show clear error messages

### 5. Updated TestingView.swift
- Added `@EnvironmentObject var authManager: AuthenticationManager`
- Added user info display at top showing:
  - Logged in user name
  - Token preview (first 8 characters)
  - Logout button
- Updated all API calls to use `authManager.token` instead of hardcoded tokens:
  - `testAppLock()` - Uses dynamic token
  - `testUnlock()` - Uses dynamic token
  - `fetchTeacherGroups()` - Uses dynamic token
  - `fetchCombinedGroupsAndClasses()` - Uses dynamic token

## Authentication Flow

```
App Launch
    ↓
Check Keychain for saved token
    ↓
If token exists → Load user data → Go to main app
    ↓
If no token → Show authentication modal
    ↓
User enters credentials
    ↓
Call /teacher/authenticate API
    ↓
Save token & user to Keychain
    ↓
Proceed to main app
```

## Security Features

- **Keychain Storage**: Token stored in iOS Keychain (encrypted)
- **Secure Fields**: Password input uses `SecureField`
- **Automatic Cleanup**: Password cleared after authentication
- **Token Persistence**: Survives app restarts
- **Logout Capability**: Clears all authentication data

## Usage

### For Users:
1. Launch app
2. Enter username and password
3. Click "Sign In"
4. Token is automatically saved
5. Use app normally - all API calls use the saved token
6. Click "Logout" to sign out and clear token

### For Developers:
```swift
// Access authentication manager in any view
@EnvironmentObject var authManager: AuthenticationManager

// Get the current token
if let token = authManager.token {
    // Use token in API calls
}

// Get authenticated user info
if let user = authManager.authenticatedUser {
    print(user.name)
    print(user.username)
}

// Logout
authManager.logout()
```

## Configuration

The company ID is currently hardcoded to "2001128" in:
- `AuthenticationView.swift` (line 142)
- Can be made configurable if needed

## What Changed from Before

**Before:**
- Token was stored in `Config.plist` as static value
- No authentication flow
- Token never changed

**After:**
- Token obtained via API authentication
- Securely stored in Keychain
- Persists across app restarts
- Can logout and re-authenticate
- Single source of truth for token used across app

## Files Modified

1. ✅ **Created:** `Parent Control/Services/AuthenticationManager.swift`
2. ✅ **Modified:** `Parent Control/Parent_ControlApp.swift` (now shows DeviceSelectionView)
3. ✅ **Modified:** `Parent Control/Views/TestingView.swift`
4. ✅ **Modified:** `Parent Control/Views/DeviceSelectionView.swift`
5. ✅ **Modified:** `Parent Control/ViewModels/ParentalControlViewModel.swift`

## Testing

To test the implementation:
1. Run the app
2. You'll see the authentication screen
3. Enter credentials:
   - Username: `gmteacher`
   - Password: `123456`
4. Click "Sign In"
5. You should see the TestingView with user info at top
6. Test any API button - they all use the authenticated token
7. Click "Logout" to test logout flow
8. Close and reopen app - should auto-login (token persisted)

## Next Steps

Optional enhancements:
- Add "Remember Me" toggle
- Add biometric authentication (Face ID/Touch ID)
- Add token refresh logic
- Add session timeout
- Make company ID configurable

