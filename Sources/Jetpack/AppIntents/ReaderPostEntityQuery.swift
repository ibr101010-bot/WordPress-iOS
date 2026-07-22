import AppIntents
import Foundation
import WordPressData

/// Resolves and searches `ReaderPostEntity` values from the local Core Data store.
struct ReaderPostEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [ReaderPostEntity.ID]) async throws -> [ReaderPostEntity] {
        let context = ContextManager.shared.mainContext
        return identifiers.compactMap { identifier in
            if let post = ReaderPost.forAppIntent(identifier: identifier, in: context),
                let entity = ReaderPostEntity(post: post)
            {
                return entity
            }
            // A well-formed identifier missing from the local store still
            // resolves to a placeholder, so a saved shortcut keeps working
            // after the Reader cache purges the post; opening it navigates
            // by the IDs alone.
            return ReaderPostEntity(identifier: identifier)
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [ReaderPostEntity] {
        let context = ContextManager.shared.mainContext
        return ReaderPost.searchForAppIntent(matching: string, in: context).compactMap { ReaderPostEntity(post: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ReaderPostEntity] {
        let context = ContextManager.shared.mainContext
        return ReaderPost.searchForAppIntent(matching: "", limit: 10, in: context)
            .compactMap {
                ReaderPostEntity(post: $0)
            }
    }
}
