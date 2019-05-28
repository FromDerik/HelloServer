import Crypto
import Vapor
import FluentPostgreSQL

/// Creates new users and logs them in.
final class UserController {
    
    /// Creates a new user.
    func register(_ req: Request) throws -> Future<UserResponse> {
        // decode request content
        return try req.content.decode(CreateUserRequest.self).flatMap { user in
            return User.query(on: req).filter(\.email == user.email).first().flatMap { fetchedUser in
                if fetchedUser != nil {
                    throw Abort(.badRequest, reason: "Email already in use.")
                }
                // verify that passwords match
                guard user.password == user.verifyPassword else {
                    throw Abort(.badRequest, reason: "Password and verification must match.")
                }
                
                // hash user's password using BCrypt
                let hash = try BCrypt.hash(user.password)
                // save new user
                let newUser = User(id: nil, name: user.name, username: user.username, email: user.email, passwordHash: hash)
                
                return newUser.save(on: req).map { savedUser in
                    return try UserResponse(id: savedUser.requireID(), username: savedUser.name, email: savedUser.email)
                }
            }
        }
    }
    
    /// login a User
    func login(_ req: Request) throws -> Future<UserToken> {
        return try req.content.decode(LoginUserRequest.self).flatMap { user in
            return User.query(on: req).filter(\.email == user.email).first().flatMap { fetchedUser in
                guard let savedUser = fetchedUser else {
                    throw Abort(.badRequest, reason: "User does not exist")
                }
                
                let passwordHash = try BCrypt.hash(user.password)
                
                if try BCrypt.verify(passwordHash, created: savedUser.passwordHash) {
                    return try UserToken
                        .query(on: req)
                        .filter(\UserToken.userID == savedUser.requireID())
                        .delete()
                        .flatMap { _ in
                            let token = try UserToken.create(userID: savedUser.requireID())
                            return token.save(on: req)
                        }
                } else {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
    
    func list(_ req: Request) throws -> Future<[UserResponse]> {
        let _ = try req.requireAuthenticated(User.self)
        
        return User.query(on: req).all().map { users in
            return try users.map { user in
                return try UserResponse(id: user.requireID(), username: user.username, email: user.email)
            }
        }
    }
    
}

// MARK: Content

struct LoginUserRequest: Content {
    var email: String
    
    var password: String
}

/// Data required to create a user.
struct CreateUserRequest: Content {
    /// User's full name.
    var name: String
    
    /// User's username.
    var username: String
    
    /// User's email address.
    var email: String
    
    /// User's desired password.
    var password: String
    
    /// User's password repeated to ensure they typed it correctly.
    var verifyPassword: String
}

/// Public representation of user data.
struct UserResponse: Content {
    /// User's unique identifier.
    /// Not optional since we only return users that exist in the DB.
    var id: Int
    
    /// User's username.
    var username: String
    
    /// User's email address.
    var email: String
}
