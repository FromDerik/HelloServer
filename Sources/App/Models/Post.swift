import Authentication
import FluentPostgreSQL
import Vapor

final class Post: PostgreSQLModel {
    
    var id: Int?
    var userID: User.ID
    var caption: String
    var date: Date
    
    init(id: Int? = nil, caption: String, userID: User.ID) {
        self.id = id
        self.userID = userID
        self.caption = caption
        self.date = Date()
    }
}

extension Post {
    var user: Parent<Post, User> {
        return parent(\.userID)
    }
}

extension Post: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(Post.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.userID)
            builder.field(for: \.caption)
            builder.field(for: \.date)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

extension Post: Content { }

extension Post: Parameter { }
