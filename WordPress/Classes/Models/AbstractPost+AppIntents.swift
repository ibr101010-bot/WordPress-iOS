import Foundation
import WordPressData

extension AbstractPost {
    /// The parsed components of a post App Intent entity identifier
    /// (`abstractPost|~~~|<dotComID or xmlrpc>|~~~|<postID>`), shared by the
    /// Core Data resolver and the placeholder entities that represent posts
    /// missing from the local store.
    struct AppIntentIdentifier {
        /// A WP.com site ID when numeric, the site's xmlrpc URL otherwise,
        /// matching the Spotlight identifier convention.
        let domain: String
        let postID: Int

        init?(identifier: String) {
            guard let (itemType, domain, postIDString) = SearchIdentifierGenerator.decomposeIfValid(identifier),
                itemType == .abstractPost,
                let postID = Int(postIDString)
            else {
                return nil
            }
            self.domain = domain
            self.postID = postID
        }
    }

    /// Resolves the post an App Intent entity identifier refers to.
    ///
    /// The identifier is the same composite string the Spotlight index uses
    /// (`abstractPost|~~~|<dotComID or xmlrpc>|~~~|<postID>`), so a Spotlight
    /// item and its associated app entity always name the same post. An
    /// identifier that cannot be resolved returns `nil` rather than falling
    /// back to another post. Trashed posts resolve to `nil` because their
    /// Spotlight items are deleted on trashing and the editor must not open
    /// them from a stale shortcut.
    static func forAppIntent(identifier: String, in context: NSManagedObjectContext) -> AbstractPost? {
        guard let identifier = AppIntentIdentifier(identifier: identifier) else {
            return nil
        }

        let blog: Blog?
        if let siteID = Int(identifier.domain) {
            blog = try? Blog.lookup(withID: siteID, in: context)
        } else {
            blog = try? BlogQuery().hostedByWPCom(false).xmlrpc(matching: identifier.domain).blog(in: context)
        }

        guard let blog,
            let post = blog.lookupPost(withID: identifier.postID, in: context),
            post.status != .trash
        else {
            return nil
        }
        return post
    }

    /// Returns posts and pages an App Intent entity query can offer, newest
    /// first. An empty query returns the most recently modified posts. Only
    /// posts that can be identified by `forAppIntent(identifier:in:)` are
    /// returned.
    static func searchForAppIntent(
        matching query: String,
        limit: Int = 20,
        in context: NSManagedObjectContext
    ) -> [AbstractPost] {
        let request = NSFetchRequest<AbstractPost>(entityName: AbstractPost.entityName())
        var predicates = [
            NSPredicate(format: "original = NULL AND postID > 0"),
            NSPredicate(format: "status != %@", BasePost.Status.trash.rawValue)
        ]
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "postTitle CONTAINS[cd] %@", query))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(AbstractPost.dateModified), ascending: false)]
        request.fetchLimit = limit
        return (try? context.fetch(request)) ?? []
    }
}
