import Crypto
import Vapor
import FluentPostgreSQL

/// Creates new users and logs them in.
final class UserController {
    
    func register(_ req: Request) throws -> Future<UserResponse> {
        return try req.content.decode(CreateUserRequest.self).flatMap { registerRequest in
            return User.query(on: req).group(.or, closure: { (query) in
                query.filter(\.email == registerRequest.email)
                query.filter(\.username == registerRequest.username)
            }).first().flatMap { fetchedUser in
                if let u = fetchedUser {
                    if u.email == registerRequest.email && u.username == registerRequest.username {
                        throw Abort(.badRequest, reason: "Email and username already in use.")
                    } else if u.email == registerRequest.email {
                        throw Abort(.badRequest, reason: "Email already in use.")
                    } else if u.username == registerRequest.username {
                        throw Abort(.badRequest, reason: "Username already in use.")
                    }
                }
                
                guard registerRequest.password == registerRequest.verifyPassword else {
                    throw Abort(.badRequest, reason: "Password and verification must match.")
                }
                
                let hash = try BCrypt.hash(registerRequest.password)
                
                let newUser = User(id: nil, name: registerRequest.name, username: registerRequest.username, email: registerRequest.email, passwordHash: hash)
                
                return newUser.save(on: req).map { savedUser in
                    return try UserResponse(id: savedUser.requireID(), username: savedUser.name, email: savedUser.email)
                }
            }
        }
    }
    
    /// logs in a User
    func login(_ req: Request) throws -> Future<UserToken> {
        return try req.content.decode(LoginUserRequest.self).flatMap { loginRequest in
            return User.query(on: req).group(.or, closure: { (query) in
                if let email = loginRequest.email {
                    query.filter(\.email == email)
                }
                if let username = loginRequest.username {
                    query.filter(\.username == username)
                }
            }).first().flatMap { fetchedUser in
                guard let user = fetchedUser else {
                    throw Abort(.badRequest, reason: "User does not exist")
                }
                
                let hasher = try req.make(BCryptDigest.self)
                
                if try hasher.verify(loginRequest.password, created: user.passwordHash) {
                    return try UserToken.query(on: req).filter(\UserToken.userID == user.requireID()).delete().flatMap { _ in
                        let token = try UserToken.create(userID: user.requireID())
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
            return try req.content.decode(UpdateUserRequest.self).flatMap { updateRequest in
                user.username = updateRequest.username ?? user.username
                user.email = updateRequest.email ?? user.email
                user.name = updateRequest.name ?? user.name
                
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
