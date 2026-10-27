import Foundation

@main
enum TeacherProfileLockStartupTests {
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

        check(
            "a missing token keeps startup waiting",
            TeacherProfileLockStartup.shouldRetry(token: nil, result: nil)
        )
        check(
            "a blank token keeps startup waiting",
            TeacherProfileLockStartup.shouldRetry(token: "  ", result: nil)
        )
        check(
            "a failed read is retried",
            TeacherProfileLockStartup.shouldRetry(
                token: "token",
                result: .failure(TeacherProfileLockError.unexpectedBody)
            )
        )
        check(
            "not locked is an answer, so startup can continue",
            !TeacherProfileLockStartup.shouldRetry(token: "token", result: .success(.notLocked))
        )
        check(
            "locked is an answer, so startup can show it",
            !TeacherProfileLockStartup.shouldRetry(
                token: "token",
                result: .success(.locked(bundleIds: ["com.example.onthefarm"]))
            )
        )

        if !failures.isEmpty {
            print("\(failures.count) failed")
            exit(1)
        }
        print("All startup lock tests passed")
    }
}
