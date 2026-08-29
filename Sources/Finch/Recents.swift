import Foundation

// The last few routes, in memory only — enough to answer "where did the link I
// just clicked go?". Deliberately not persisted: no file, no rotation, no
// toggle. It dies with the process.

struct RouteEntry {
    let opener: String      // bundle id of the app the link came from, or the
                            // sender's executable name; "" if unresolvable
    let original: String    // URL as received
    let final: String       // URL after rewrites
    let bundleId: String    // browser it was sent to ("" = suppressed by `open: null`)

    var suppressed: Bool { bundleId.isEmpty }
    var rewritten: Bool { original != final }
}

final class RouteHistory {
    static let shared = RouteHistory()

    /// How many routes the menu bar remembers.
    private static let capacity = 10

    private var entries: [RouteEntry] = []

    /// Most recent first.
    var recent: [RouteEntry] { entries.reversed() }

    func record(opener: String, original: String, final: String, bundleId: String) {
        entries.append(RouteEntry(opener: opener, original: original,
                                  final: final, bundleId: bundleId))
        if entries.count > Self.capacity { entries.removeFirst(entries.count - Self.capacity) }
    }
}
