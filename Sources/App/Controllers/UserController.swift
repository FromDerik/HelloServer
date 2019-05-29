import Crypto
import Vapor
import FluentPostgreSQL

/// Creates new users and logs them in.
final class UserController {
    
    /// Creates a new user.
    func register(_ req: Request) throws -> Future<UserResponse> {
        return try req.content.decode(CreateUserRequest.self).flatMap { user in
            return User.query(on: req).group(.or, closure: { (query) in
                query.filter(\.email == user.email)
                query.filter(\.username == user.username)
            }).first().flatMap { fetchedUser in
                if let u = fetchedUser {
                    if u.email == user.email && u.username == user.username {
                        throw Abort(.badRequest, reason: "Email and username already in use.")
                    } else if u.email == user.email {
                        throw Abort(.badRequest, reason: "Email already in use.")
                    } else if u.username == user.username {
                        throw Abort(.badRequest, reason: "Username already in use.")
                    }
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
    
    /// logs in a User
    func login(_ req: Request) throws -> Future<UserToken> {
        return try req.content.decode(LoginUserRequest.self).flatMap { user in
            return User.query(on: req).group(.or, closure: { (query) in
                if let email = user.email {
                    query.filter(\.email == email)
                }
                if let username = user.username {
                    query.filter(\.username == username)
                }
            }).first().flatMap { fetchedUser in
                guard let savedUser = fetchedUser else {
                    throw Abort(.badRequest, reason: "User does not exist")
                }
                
                let hasher = try req.make(BCryptDigest.self)
                
                if try hasher.verify(user.password, created: savedUser.passwordHash) {
                    return try UserToken.query(on: req).filter(\UserToken.userID == savedUser.requireID()).delete().flatMap { _ in
                        let token = try UserToken.create(userID: savedUser.requireID())
                        return token.save(on: req)
                    }
                } else {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
    
    func logout(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(User.self)
        
        return try UserToken.query(on: req).filter(\.userID, .equal, user.requireID()).delete().transform(to: HTTPResponse(status: .ok))
    }
    
    func update(_ req: Request) throws -> Future<UserResponse> {
        let _ = try req.requireAuthenticated(User.self)
        
        return try req.parameters.next(User.self).flatMap { user in
            return try req.content.decode(UpdateUserRequest.self).flatMap { newUser in
                user.username = newUser.username ?? user.username
                user.email = newUser.email ?? user.email
                user.name = newUser.name ?? user.name
                
                return user.save(on: req).map { savedUser in
                    return try UserResponse(id: savedUser.requireID(), username: savedUser.username, email: savedUser.email)
                }
            }
        }
    }
    
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let _ = try req.requireAuthenticated(User.self)
        
        return try req.parameters.next(User.self).flatMap { user in
            try UserToken.query(on: req).filter(\.userID == user.requireID()).delete().flatMap { _ in
                return user.delete(on: req)
            }
        }.transform(to: .ok)
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

// Data required to update a user.
struct UpdateUserRequest: Content {
    var email: String?
    var username: String?
    var name: String?
}

// Data required to login a user.
struct LoginUserRequest: Content {
    var email: String?
    var username: String?
    var password: String
}

/// Data required to create a user.
struct CreateUserRequest: Content {
    var name: String
    var username: String
    var email: String
    var password: String
    var verifyPassword: String
}

/// Public representation of user data.
struct UserResponse: Content {
    var id: Int
    var username: String
    var email: String
}
