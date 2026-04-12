//
//  EntitlementChecker.swift
//  MeloNX
//
//  Created by Stossy11 on 15/02/2025.
//

import Foundation
import Security

typealias SecTaskRef = OpaquePointer

@_silgen_name("SecTaskCopyValueForEntitlement")
func SecTaskCopyValueForEntitlement(
    _ task: SecTaskRef,
    _ entitlement: NSString,
    _ error: NSErrorPointer
) -> CFTypeRef?

@_silgen_name("SecTaskCopyTeamIdentifier")
func SecTaskCopyTeamIdentifier(
    _ task: SecTaskRef,
    _ error: NSErrorPointer
) -> NSString?

@_silgen_name("SecTaskCreateFromSelf")
func SecTaskCreateFromSelf(
    _ allocator: CFAllocator?
) -> SecTaskRef?

@_silgen_name("CFRelease")
func CFRelease(_ cf: CFTypeRef)

@_silgen_name("SecTaskCopyValuesForEntitlements")
func SecTaskCopyValuesForEntitlements(
    _ task: SecTaskRef,
    _ entitlements: CFArray,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFDictionary?

func releaseSecTask(_ task: SecTaskRef) {
    let cf = unsafeBitCast(task, to: CFTypeRef.self)
    CFRelease(cf)
}

func checkAppEntitlements(_ ents: [String]) -> [String: Any] {
    guard let task = SecTaskCreateFromSelf(nil) else {
        return [:]
    }
    defer {
        releaseSecTask(task)
    }

    guard let entitlements = SecTaskCopyValuesForEntitlements(task, ents as CFArray, nil) else {
        return [:]
    }

    return (entitlements as NSDictionary) as? [String: Any] ?? [:]
}

func checkAppEntitlement(_ ent: String) -> Bool {
    guard let task = SecTaskCreateFromSelf(nil) else {
        return false
    }
    defer {
        releaseSecTask(task)
    }

    guard let entitlement = SecTaskCopyValueForEntitlement(task, ent as NSString, nil) else {
        return false
    }

    if let number = entitlement as? NSNumber {
        return number.boolValue
    } else if let bool = entitlement as? Bool {
        return bool
    }

    return false
}

private let increasedMemoryEntitlementKey = "com.apple.developer.kernel.increased-memory-limit"

// NOTE:
// - Untuk stabilitas launch, runtime flag tetap bisa pakai checkAppEntitlement() langsung.
// - Fungsi ini dipakai untuk UX/gating agar tidak false-negative di beberapa signer/environment.
func hasUsableIncreasedMemoryLimit() -> Bool {
    if checkAppEntitlement(increasedMemoryEntitlementKey) {
        return true
    }

    // Fallback UX: treat as enabled by default unless user explicitly disables override.
    let key = "ForceIncreasedMemoryLimitFallback"
    if UserDefaults.standard.object(forKey: key) == nil {
        return true
    }

    return UserDefaults.standard.bool(forKey: key)
}
