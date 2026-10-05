import Foundation

/// Attend qu'une condition devienne vraie, en la vérifiant toutes les 10 ms.
/// Renvoie `false` si elle ne l'est toujours pas au bout de `timeout`.
@MainActor
func waitUntil(timeout: Duration = .seconds(2), _ condition: @MainActor () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}
