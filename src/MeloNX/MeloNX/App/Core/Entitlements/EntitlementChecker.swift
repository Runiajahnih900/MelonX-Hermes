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

private let forcedEnabledEntitlements: Set<String> = [
    "com.apple.developer.kernel.increased-memory-limit"
]

func checkAppEntitlement(_ ent: String) -> Bool {
    // Force-enable increased memory limit across UI/runtime checks.
    // This keeps behavior consistent even on environments where SecTask
    // entitlement introspection reports false.
    if forcedEnabledEntitlements.contains(ent) {
        return true
    }

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
