import Authentication
import FluentPostgreSQL
import Vapor

/// A registered user, capable of owning todo items.
final class User: PostgreSQLModel {
    /// User's unique identifier.
    /// Can be `nil` if the user has not been saved yet.
    var id: Int?
    
    /// User's full name.
    var name: String
    
    /// User's username
    var username: String
    
    /// User's email address.
    var email: String
    
    /// BCrypt hash of the user's password.
    var passwordHash: String
    
    /// Creates a new `User`.
    init(id: Int? = nil, name: String, username: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
    }
}

/// Allows users to be verified by basic / password auth middleware.
extension User: PasswordAuthenticatable {
    /// See `PasswordAuthenticatable`.
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }
    
    /// See `PasswordAuthenticatable`.
    static var passwordKey: WritableKeyPath<User, String> {
        return \.passwordHash
    }
}

/// Allows users to be verified by bearer / token auth middleware.
extension User: TokenAuthenticatable {
    /// See `TokenAuthenticatable`.
    typealias TokenType = UserToken
}

/// Allows `User` to be used as a Fluent migration.
extension User: Migration {
    /// See `Migration`.
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(User.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.name)
            builder.field(for: \.username)
            builder.field(for: \.email)
            builder.field(for: \.passwordHash)
            builder.unique(on: \.email)
            builder.unique(on: \.username)
        }
    }
}

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }
