import Foundation

public struct SearchIdentifierGenerator {
    internal static let separator = "|~~~|"

    internal static func composeUniqueIdentifier(
        itemType: SearchItemType,
        domain: String,
        identifier: String
    ) -> String {
        "\(itemType.stringValue())\(separator)\(domain)\(separator)\(identifier)"
    }

    public static func decomposeFromUniqueIdentifier(
        _ combined: String
    ) -> (itemType: SearchItemType, domain: String, identifier: String) {
        let components = combined.components(separatedBy: separator)

        return (SearchItemType(index: components[0]), components[1], components[2])
    }

    /// A failable variant of `decomposeFromUniqueIdentifier(_:)` for identifiers
    /// that come from outside the app (e.g. App Intents entity identifiers
    /// persisted in users' shortcuts), where the composite format cannot be
    /// assumed.
    public static func decomposeIfValid(
        _ combined: String
    ) -> (itemType: SearchItemType, domain: String, identifier: String)? {
        let components = combined.components(separatedBy: separator)
        guard components.count == 3 else {
            return nil
        }
        return (SearchItemType(index: components[0]), components[1], components[2])
    }
}
