import Foundation

@main
enum SingleAppLockStateTests {
    static func main() {
        var failures: [String] = []

        func check(_ name: String, _ condition: Bool) {
            if condition {
                print("PASS \(name)")
            } else {
                print("FAIL \(name)")
                failures.append(name)
            }
        }

        check("empty whitelist is hidden", visibility(for: []) == .hidden)
        check("missing ids are hidden", visibility(for: ["", "  "]) == .hidden)
        check("several bundle ids are hidden", visibility(for: [
            "com.apple.AppStore",
            "com.apple.camera",
            "com.duckduckmoosedesign.cp",
            "com.apple.mobiletimer"
        ]) == .hidden)
        check("one bundle id is shown", visibility(for: ["com.apple.mobilesafari"]) == .shown(bundleId: "com.apple.mobilesafari"))
        check("duplicate of one id is still shown", visibility(for: [
            "com.apple.mobilesafari",
            " com.apple.mobilesafari "
        ]) == .shown(bundleId: "com.apple.mobilesafari"))

        let missing = profiles(#"[{"studentId":203}]"#)
        check("missing appWhitelist decodes as no lock", bundleIds("203", missing).isEmpty)
        check("missing appWhitelist hides the button", visibility(for: bundleIds("203", missing)) == .hidden)

        let empty = profiles(#"[{"studentId":"203","appWhitelist":[]}]"#)
        check("empty appWhitelist hides the button", visibility(for: bundleIds("203", empty)) == .hidden)

        let nullWhitelist = profiles(#"[{"studentId":203,"appWhitelist":null}]"#)
        check("null appWhitelist hides the button", visibility(for: bundleIds("203", nullWhitelist)) == .hidden)

        let many = profiles(#"""
        [{"studentId":204,"appWhitelist":["com.apple.AppStore","com.apple.camera","com.duckduckmoosedesign.cp","com.apple.mobiletimer"]}]
        """#)
        check("multiple appWhitelist entries hide the button", visibility(for: bundleIds("204", many)) == .hidden)

        let one = profiles(#"[{"studentId":204,"appWhitelist":["com.apple.mobilesafari"]}]"#)
        check("one appWhitelist entry shows the button", visibility(for: bundleIds("204", one)) == .shown(bundleId: "com.apple.mobilesafari"))

        let stringified = profiles(#"[{"studentId":204,"appWhitelist":"[\"com.apple.mobilesafari\"]"}]"#)
        check("stringified one-id whitelist shows the button", visibility(for: bundleIds("204", stringified)) == .shown(bundleId: "com.apple.mobilesafari"))

        let documentedString = profiles(
            #"[{"studentId":204,"appWhitelist":"[\"com.apple.AppStore\",\"com.apple.camera\",\"com.duckduckmoosedesign.cp\",\"com.apple.mobiletimer\"]"}]"#
        )
        check("stringified multi-id whitelist hides the button", visibility(for: bundleIds("204", documentedString)) == .hidden)

        let commas = profiles(#"[{"studentId":204,"appWhitelist":"com.apple.mobilesafari, com.apple.camera"}]"#)
        check("comma-separated whitelist hides the button", visibility(for: bundleIds("204", commas)) == .hidden)

        let oneComma = profiles(#"[{"studentId":204,"appWhitelist":"com.apple.mobilesafari"}]"#)
        check("single bundle-id string shows the button", visibility(for: bundleIds("204", oneComma)) == .shown(bundleId: "com.apple.mobilesafari"))

        let objects = profiles(#"[{"studentId":204,"appWhitelist":[{"identifier":"com.apple.mobilesafari"}]}]"#)
        check("identifier object shows the button", visibility(for: bundleIds("204", objects)) == .shown(bundleId: "com.apple.mobilesafari"))

        let bundleObjects = profiles(#"[{"studentId":"204","appWhitelist":[{"bundleId":"com.apple.mobilesafari"},{"bundleId":"com.apple.camera"}]}]"#)
        check("several identifier objects hide the button", visibility(for: bundleIds("204", bundleObjects)) == .hidden)

        let mixedStudents = profiles(#"""
        [{"studentId":203},{"studentId":204,"appWhitelist":["com.apple.mobilesafari"]}]
        """#)
        check("another student's lock is ignored", bundleIds("203", mixedStudents).isEmpty)
        check("matching student id is used", visibility(for: bundleIds("204", mixedStudents)) == .shown(bundleId: "com.apple.mobilesafari"))

        let safari = AppItem(
            title: "Safari",
            description: "Browser",
            iconName: "safari",
            bundleId: "com.apple.mobilesafari",
            additionalInfo: "Browser"
        )
        check(
            "known bundle id uses the app name",
            AppNameMatcher.name(forBundleId: "com.apple.mobilesafari", apps: [safari]) == "Safari"
        )
        check(
            "unknown bundle id stays visible as the id",
            AppNameMatcher.name(forBundleId: "com.example.missing", apps: [safari]) == "com.example.missing"
        )

        var store = SingleAppLockStore()
        store.noteAppLockApplied(ownerId: "143", bundleId: "com.apple.mobilesafari", appName: "Safari")
        check("successful applock shows the button without a profile read", store.lock(forOwnerId: "143") == SingleAppLock(bundleId: "com.apple.mobilesafari", appName: "Safari"))

        store.noteLessonsStopped(ownerId: "143")
        check("successful lessons/stop hides the button without a profile read", store.lock(forOwnerId: "143") == nil)

        store.noteAppLockApplied(ownerId: "143", bundleId: "com.apple.mobilesafari", appName: "Safari")
        store.noteLessonsStopped(ownerId: "143")
        check("stop before a failed applock leaves the button hidden", store.lock(forOwnerId: "143") == nil)

        store.noteLessonsStopped(ownerId: "143")
        store.noteAppLockApplied(ownerId: "143", bundleId: "com.apple.Music", appName: "Music")
        check("stop then successful applock shows the new app", store.lock(forOwnerId: "143")?.appName == "Music")

        let generation = store.beginProfileFetch(ownerId: "143")
        store.noteAppLockApplied(ownerId: "143", bundleId: "com.apple.mobilesafari", appName: "Safari")
        let staleApply = store.replaceFromProfile(
            ownerId: "143",
            bundleIds: [],
            generation: generation,
            appName: { AppNameMatcher.name(forBundleId: $0, apps: [safari]) }
        )
        check("an older profile read does not clear a newer applock", staleApply == false)
        check("button stays on the applied app", store.lock(forOwnerId: "143")?.bundleId == "com.apple.mobilesafari")

        let unlockGeneration = store.beginProfileFetch(ownerId: "143")
        store.noteLessonsStopped(ownerId: "143")
        let staleUnlock = store.replaceFromProfile(
            ownerId: "143",
            bundleIds: ["com.apple.mobilesafari"],
            generation: unlockGeneration,
            appName: { $0 }
        )
        check("an older profile read does not restore a lock after stop", staleUnlock == false)
        check("button stays hidden after stop", store.lock(forOwnerId: "143") == nil)

        let fresh = store.beginProfileFetch(ownerId: "143")
        let applied = store.replaceFromProfile(
            ownerId: "143",
            bundleIds: ["com.apple.mobilesafari"],
            generation: fresh,
            appName: { AppNameMatcher.name(forBundleId: $0, apps: [safari]) }
        )
        check("the open-screen profile read can show one app", applied && store.lock(forOwnerId: "143") == SingleAppLock(bundleId: "com.apple.mobilesafari", appName: "Safari"))

        let farmLock = SingleAppLock(bundleId: "com.example.onthefarm", appName: "On The Farm")
        check("blue unlock button title is Unlock", SingleAppLock.unlockButtonTitle == "Unlock")
        check("blue unlock button title does not include the app name", !SingleAppLock.unlockButtonTitle.contains(farmLock.appName))
        check("lock icon shows on the locked app card", farmLock.showsLockIcon(on: "com.example.onthefarm"))
        check("lock icon stays off other app cards", !farmLock.showsLockIcon(on: "com.apple.mobilesafari"))
        check("lock icon stays off an app with no bundle id", !farmLock.showsLockIcon(on: nil))
        check("a finished profile read is settled", store.query(forOwnerId: "143") == .settled)

        let firstLaunch = store.beginProfileFetch(ownerId: "190")
        let secondLaunch = store.beginProfileFetch(ownerId: "190")
        let droppedLaunch = store.replaceFromProfile(
            ownerId: "190",
            bundleIds: ["com.example.onthefarm"],
            generation: firstLaunch,
            appName: { _ in "On The Farm" }
        )
        check("an older launch read is not applied", droppedLaunch == false)
        check("a dropped launch read stays loading", store.query(forOwnerId: "190") == .loading)
        check("a dropped launch read does not settle as unlocked", store.lock(forOwnerId: "190") == nil)
        let newerLaunch = store.replaceFromProfile(
            ownerId: "190",
            bundleIds: ["com.example.onthefarm"],
            generation: secondLaunch,
            appName: { _ in "On The Farm" }
        )
        check(
            "the newer launch read settles the lock",
            newerLaunch
                && store.lock(forOwnerId: "190") == SingleAppLock(bundleId: "com.example.onthefarm", appName: "On The Farm")
                && store.query(forOwnerId: "190") == .settled
        )

        let failedGeneration = store.beginProfileFetch(ownerId: "203")
        store.noteProfileFetchFailed(ownerId: "203", generation: failedGeneration)
        check("a failed profile read is not settled unlocked", store.query(forOwnerId: "203") == .failed)
        check("a failed profile read leaves no lock", store.lock(forOwnerId: "203") == nil)
        let staleFailure = store.beginProfileFetch(ownerId: "190")
        store.noteAppLockApplied(ownerId: "190", bundleId: "com.example.onthefarm", appName: "On The Farm")
        store.noteProfileFetchFailed(ownerId: "190", generation: staleFailure)
        check("a stale failure does not clear a newer lock", store.query(forOwnerId: "190") == .settled)
        check("a stale failure keeps the newer lock", store.lock(forOwnerId: "190")?.bundleId == "com.example.onthefarm")

        store.noteProfileFetchUnavailable(ownerId: "204")
        check("a missing token is failed, not unlocked", store.query(forOwnerId: "204") == .failed)
        check("a missing token does not settle an empty lock", store.lock(forOwnerId: "204") == nil)
        store.noteProfileFetchUnavailable(ownerId: "190")
        check("a missing token does not unset a settled lock", store.query(forOwnerId: "190") == .settled)

        check("a blank token waits", SingleAppLockTokenReadiness.decide(token: nil, attempt: 0, maxAttempts: 2) == .wait)
        check("an empty token waits", SingleAppLockTokenReadiness.decide(token: "  ", attempt: 0, maxAttempts: 2) == .wait)
        check("a present token is ready immediately", SingleAppLockTokenReadiness.decide(token: "abc", attempt: 0, maxAttempts: 2) == .ready("abc"))
        check("a token that arrives later is ready", SingleAppLockTokenReadiness.decide(token: "abc", attempt: 2, maxAttempts: 2) == .ready("abc"))
        check("a token that never arrives is unavailable", SingleAppLockTokenReadiness.decide(token: nil, attempt: 2, maxAttempts: 2) == .unavailable)

        var startup = SingleAppLockStore()
        let startupGeneration = startup.beginProfileFetch(ownerId: "190")
        let startupApplied = startup.replaceFromProfile(
            ownerId: "190",
            bundleIds: ["com.example.onthefarm"],
            generation: startupGeneration,
            appName: { _ in "On The Farm" }
        )
        let startupLock = startup.lock(forOwnerId: "190")
        check(
            "a launch read of one app puts the lock icon on that card",
            startupApplied
                && startup.query(forOwnerId: "190") == .settled
                && startupLock?.showsLockIcon(on: "com.example.onthefarm") == true
        )
        check(
            "a launch read does not put the lock icon on other cards",
            startupLock?.showsLockIcon(on: "com.apple.mobilesafari") != true
        )

        let unlockedGeneration = startup.beginProfileFetch(ownerId: "191")
        let unlockedApplied = startup.replaceFromProfile(
            ownerId: "191",
            bundleIds: [],
            generation: unlockedGeneration,
            appName: { $0 }
        )
        check(
            "an unlocked device does not show a lock at launch",
            unlockedApplied
                && startup.query(forOwnerId: "191") == .settled
                && startup.lock(forOwnerId: "191") == nil
        )

        let pairingGeneration = startup.beginProfileFetch(ownerId: "192")
        let pairingApplied = startup.replaceFromProfile(
            ownerId: "192",
            bundleIds: ["com.apple.AppStore", "com.apple.camera"],
            generation: pairingGeneration,
            appName: { $0 }
        )
        check(
            "a device that is not locked to one app does not show a lock",
            pairingApplied
                && startup.query(forOwnerId: "192") == .settled
                && startup.lock(forOwnerId: "192") == nil
        )

        if !failures.isEmpty {
            print("\(failures.count) failed")
            exit(1)
        }
        print("All single-app lock tests passed")
    }

    private static func visibility(for bundleIds: [String]) -> SingleAppLockVisibility {
        SingleAppLockVisibility.decide(bundleIds: bundleIds)
    }

    private static func profiles(_ json: String) -> [TeacherStudentProfile] {
        guard let data = json.data(using: .utf8) else {
            print("FAIL fixture is not utf8")
            exit(1)
        }
        do {
            return try TeacherStudentProfile.decodeList(from: data)
        } catch {
            print("FAIL decode \(json): \(error)")
            exit(1)
        }
    }

    private static func bundleIds(_ ownerId: String, _ profiles: [TeacherStudentProfile]) -> [String] {
        TeacherStudentProfile.bundleIds(forOwnerId: ownerId, in: profiles)
    }
}
