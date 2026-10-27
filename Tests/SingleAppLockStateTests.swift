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
