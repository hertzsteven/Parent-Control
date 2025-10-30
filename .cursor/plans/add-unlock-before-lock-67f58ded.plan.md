<!-- 67f58ded-382b-4c2f-8197-200c7a093dec d25a49a7-0b90-49a8-afc6-ef4744cdef8f -->
# Use Dynamic Owner ID from Device Data

## Problem

- Student ID is hardcoded as `"143"` in lock/unlock operations
- Lock process unnecessarily sets device owner (owner already exists in API)
- No validation when device has no owner assigned

## Solution Overview

- Extract owner ID from device data and use it dynamically
- **Remove "Set Device Owner" step** - owner already exists in system
- **No fallbacks** - if device has no owner, operations are blocked
- Add UI prevention and warnings when device has no owner
- Simplify lock process from 3 steps to 2 steps

## Changes Required

### 1. Update Device Model

**File:** `Parent Control/Models/Device.swift`

Add `ownerId` property to store owner from API:

```swift
struct Device {
    let ownerId: String?  // Owner/Student ID from API (nil if not assigned)
}
```

Add helper extension:

```swift
extension Device {
    var hasOwner: Bool {
        return ownerId != nil && !ownerId!.isEmpty
    }
    
    var ownerRequirementMessage: String {
        return "This device has no owner assigned. Please assign an owner in Zuludesk before managing app locks."
    }
}
```

**Note:** `ownerId` is optional - nil means no owner assigned. **NO FALLBACK TO "143"**.

### 2. Update Device Mapper

**File:** `Parent Control/Services/ModelMappers.swift`

Extract owner ID from API (line ~98):

```swift
func toDevice(bundleIdMapping: [String: UUID]) -> Device {
    // Extract owner ID - will be nil if not assigned
    let ownerIdString = owner?.id.map { String($0) }
    return Device(..., ownerId: ownerIdString)
}
```

**Important:** If API returns no owner or `owner.id` is nil, `ownerIdString` will be nil. This is correct - do not provide fallback.

### 3. Update ViewModel Lock Function

**File:** `Parent Control/ViewModels/ParentalControlViewModel.swift`

**NEW 2-step process with strict owner requirement:**

```swift
func lockDeviceToApp(device: Device, app: AppItem) async -> Result<String, Error> {
    // STRICT REQUIREMENT: Must have owner, no fallback
    guard let userId = device.ownerId else {
        let errorMessage = "Device \(device.name) has no owner assigned"
        return .failure(NSError(domain: "ParentalControl", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: errorMessage]))
    }
    
    do {
        // STEP 1: Unlock Device (clear existing locks)
        let unlockResponse = try await networkService.stopAppLock(
            studentId: userId,  // Uses ONLY the device's owner ID
            token: configuration.teacherToken
        )
        
        // STEP 2: Apply App Lock
        let lockResponse = try await networkService.applyAppLock(
            bundleId: bundleId,
            clearAfterSeconds: clearAfter,
            studentIds: [userId],  // Uses ONLY the device's owner ID
            token: configuration.teacherToken
        )
        
        return .success(...)
    }
}
```

**Critical:** Remove any `let userId = "143"` fallback. Only use `device.ownerId`.

### 4. Update ViewModel Unlock Function

**File:** `Parent Control/ViewModels/ParentalControlViewModel.swift`

**Strict owner requirement:**

```swift
func unlockDevice(device: Device) async -> Result<String, Error> {
    // STRICT REQUIREMENT: Must have owner, no fallback
    guard let userId = device.ownerId else {
        let errorMessage = "Device \(device.name) has no owner assigned"
        return .failure(NSError(domain: "ParentalControl", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: errorMessage]))
    }
    
    let response = try await networkService.stopAppLock(
        studentId: userId,  // Uses ONLY the device's owner ID
        token: configuration.teacherToken
    )
}
```

### 5. Update DeviceAppsView - Prevent Actions Without Owner

**File:** `Parent Control/DeviceAppsView.swift`

Add owner validation and UI prevention:

- Check `device.hasOwner` before allowing any actions
- Disable app tiles when `!device.hasOwner`
- Disable unlock button when `!device.hasOwner`
- Show warning alert if actions attempted without owner
- Update instructional text based on owner status
- Show owner info/warning in navigation bar

**Key code:**

```swift
// App tile - only allow lock if device has owner
.disabled(isLocking || !device.hasOwner)

// Unlock button - only allow if device has owner
.disabled(isLocking || isUnlocking || !device.hasOwner)

// Before calling lock/unlock
if !device.hasOwner {
    showOwnerWarning = true
    return
}
```

### 6. Update Mock/Test Data ONLY

**Files:** `Device.swift` and `ParentalControlViewModel.swift`

**Mock data for previews/testing uses "143" for convenience:**

```swift
// In Device.swift samples
static let sample = Device(..., ownerId: "143")  // Test data only

// In ParentalControlViewModel.swift default devices
Device(..., ownerId: "143")  // Test data only
```

**Important:** This is ONLY for testing/preview purposes. Real devices from API will have their actual owner ID or nil.

## Process Flow

**Lock Device to App (2 steps):**

1. Unlock device (clear any existing locks)
2. Lock device to selected app

**Unlock Device (1 step):**

1. Stop app lock for device owner

**Both require:** `device.ownerId` must exist (not nil, not empty)

## Strict Rules

1. ❌ **NO fallback to "143"** in app logic
2. ✅ **Only use device.ownerId** from API
3. ✅ **Block operations** if ownerId is nil
4. ✅ **"143" only in mock/test data** for development

## Benefits

- ✅ Fewer API calls (removed redundant Set Owner)
- ✅ Uses actual owner from device data only
- ✅ No hardcoded fallbacks - fail-safe approach
- ✅ Proactive UI prevention when no owner
- ✅ Clear error messages and guidance

## UI States

**With Owner (ownerId exists):**

- All features enabled
- Shows "Owner ID: [actual-id]"
- Full functionality

**Without Owner (ownerId is nil):**

- All actions disabled and dimmed
- Shows "⚠️ No owner assigned"
- Alert explains requirement
- No operations possible

## Testing

1. Verify with real devices that have owners
2. Test with device that has NO owner (should block all actions)
3. Confirm no "143" fallback occurs in production code
4. Check mock data works for previews