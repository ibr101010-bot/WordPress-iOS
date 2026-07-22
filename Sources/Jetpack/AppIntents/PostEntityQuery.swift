import AppIntents
import Foundation
import WordPressData

/// Resolves and searches `PostEntity` values from the local Core Data store.
struct PostEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [PostEntity.ID]) async throws -> [PostEntity] {
        let context = ContextManager.shared.mainContext
        return identifiers.compactMap { identifier in
            if let post = AbstractPost.forAppIntent(identifier: identifier, in: context),
                let entity = PostEntity(post: post)
            {
                return entity
            }
            // A well-formed identifier missing from the local store still
            // resolves to a placeholder, so a saved shortcut keeps working
            // after the post is evicted from the cache; opening it falls
            // back to a remote fetch.
            return PostEntity(identifier: identifier)
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [PostEntity] {
        let context = ContextManager.shared.mainContext
        return AbstractPost.searchForAppIntent(matching: string, in: context).compactMap { PostEntity(post: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [PostEntity] {
        let context = ContextManager.shared.mainContext
        return AbstractPost.searchForAppIntent(matching: "", limit: 10, in: context).compactMap { PostEntity(post: $0) }
    }
}
