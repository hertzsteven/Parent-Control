import Foundation

@main
enum TeacherProfileLockStatusTests {
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

        let missing = status(#"[{"studentId":190}]"#)
        check("a row with no whitelist is not locked", missing == .notLocked)

        let nullWhitelist = status(#"[{"studentId":190,"appWhitelist":null}]"#)
        check("a null whitelist is not locked", nullWhitelist == .notLocked)

        let empty = status(#"[{"studentId":190,"appWhitelist":[]}]"#)
        check("an empty whitelist is not locked", empty == .notLocked)

        let one = status(#"[{"studentId":190,"appWhitelist":["com.apple.mobilesafari"]}]"#)
        check("one bundle id is locked", one == .locked(bundleIds: ["com.apple.mobilesafari"]))

        let stringified = status(#"[{"studentId":190,"appWhitelist":"[\"com.apple.mobilesafari\"]"}]"#)
        check(
            "a stringified one-app whitelist is locked",
            stringified == .locked(bundleIds: ["com.apple.mobilesafari"])
        )

        let several = status(
            #"[{"studentId":190,"appWhitelist":["com.apple.AppStore","com.apple.camera"]}]"#
        )
        check(
            "several bundle ids stay visible as a lock",
            several == .locked(bundleIds: ["com.apple.AppStore", "com.apple.camera"])
        )

        let otherStudent = status(#"[{"studentId":204,"appWhitelist":["com.apple.mobilesafari"]}]"#)
        check("another student's lock is not this device", otherStudent == .studentMissing)

        if !failures.isEmpty {
            print("\(failures.count) failed")
            exit(1)
        }
        print("All teacher profile lock tests passed")
    }

    private static func status(_ json: String) -> TeacherProfileLockStatus {
        guard let data = json.data(using: .utf8) else {
            print("FAIL fixture is not utf8")
            exit(1)
        }
        do {
            return try TeacherProfileLockStatus.interpret(ownerId: "190", responseBody: data)
        } catch {
            print("FAIL decode \(json): \(error)")
            exit(1)
        }
    }
}
