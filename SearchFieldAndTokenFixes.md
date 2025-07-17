# Advanced Search Field Behavior & Token Management Fixes

## Issues Fixed ✅

### 1. **Advanced Search Field Behavior**
**Problem**: When selecting one advanced search field, other fields should grey out (become disabled), but this wasn't happening.

**Solution**: Restored the original field enabling logic:
```swift
func isFieldEnabled(_ field: SearchFieldType) -> Bool {
    if isSearching {
        return false
    }
    
    let anySelected = searchModel || searchSerial || searchUser || searchComputerName
    
    if !anySelected {
        return true // All fields enabled when none selected
    }
    
    // Only the selected field is enabled
    switch field {
    case .model: return searchModel
    case .serial: return searchSerial
    case .user: return searchUser
    case .computerName: return searchComputerName
    }
}
```

**Behavior Now**:
- ✅ No fields selected → All fields enabled
- ✅ One field selected → Only that field enabled, others greyed out
- ✅ During search → All fields disabled

### 2. **Token Expiration During Concurrent Processing**
**Problem**: Multiple concurrent tasks were trying to refresh expired tokens simultaneously, causing failures:
```
Token validation - Now: 2025-06-25 15:51:10 +0000, Expires: 2025-06-25 15:50:57 +0000, Buffer: 2.551745s, Valid: false
Token is invalid or expired
No valid token available for advanced search
```

**Root Cause**: Concurrent tasks were each trying to handle their own token refresh, leading to race conditions and expired token usage.

**Solution**: Centralized token management at the batch level:

#### Before (Problematic):
```swift
// Each concurrent task tried to refresh tokens individually
private func processComputerForAdvancedSearch() async -> SearchResult? {
    var currentToken = authManager.getActionFramework().getCurrentToken()
    if currentToken == nil {
        _ = await authManager.ensureAuthenticated() // Race condition!
        currentToken = authManager.getActionFramework().getCurrentToken()
    }
    // Use potentially stale token
}
```

#### After (Fixed):
```swift
// Fresh token obtained once per batch, shared across concurrent tasks
for batchIndex in 0..<totalBatches {
    // Ensure we have a fresh token before each batch
    _ = await authManager.ensureAuthenticated()
    guard let freshToken = authManager.getActionFramework().getCurrentToken() else {
        print("Failed to get fresh token for batch \(batchIndex)")
        return
    }
    
    await withTaskGroup(of: SearchResult?.self) { group in
        for computer in batch {
            group.addTask {
                await self.processComputerForAdvancedSearch(
                    computer: computer,
                    authManager: authManager,
                    token: freshToken // Use shared fresh token
                )
            }
        }
    }
}
```

### 3. **Additional Performance Optimizations**
Added small delays between batches to reduce API pressure:
```swift
// Small delay between batches to prevent API overload
if batchIndex < totalBatches - 1 {
    try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
}
```

## Technical Improvements

### Token Management Strategy:
1. **Batch-Level Refresh**: Get fresh token once per batch (every 20 computers)
2. **Shared Token**: All concurrent tasks in a batch use the same fresh token
3. **No Race Conditions**: Only one token refresh per batch, not per task
4. **Validation**: Ensure token exists before starting batch processing

### Field Enabling Logic:
1. **Mutual Exclusion**: Only one advanced search field can be active at a time
2. **Visual Feedback**: Disabled fields are greyed out to show they're inactive
3. **Search State**: All fields disabled during active search
4. **Reset State**: All fields enabled when none are selected

### API Rate Management:
1. **Controlled Concurrency**: Max 5 simultaneous API calls
2. **Batch Processing**: 20 computers per batch
3. **Inter-Batch Delays**: 0.25 second pause between batches
4. **Early Termination**: Stop at 50 results to prevent overload

## Expected Results

### Advanced Search Fields:
- ✅ Selecting "Model" → Serial/User/Computer Name fields become greyed out
- ✅ Deselecting all → All fields become available again
- ✅ During search → All fields disabled until search completes

### Token Management:
- ✅ No more "Token is invalid or expired" errors
- ✅ Smooth search progression without interruption
- ✅ Automatic token refresh every batch (every 20 computers)
- ✅ No concurrent token refresh race conditions

### Performance:
- ✅ Faster search completion due to proper token management
- ✅ Reduced API server load from rate limiting
- ✅ More reliable search results