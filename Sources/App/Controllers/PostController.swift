//
//  PostController.swift
//  App
//
//  Created by Derik Malcolm on 6/1/19.
//

import Vapor
import FluentPostgreSQL

final class PostController {
    
    func create(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CreatePostRequest.self).flatMap { postRequest in
            let post = try Post(caption: postRequest.post, userID: user.requireID())
            return post.save(on: req).transform(to: HTTPResponse(status: .ok))
        }
    }
    
    func list(_ req: Request) throws -> Future<[PostResponse]> {
        let authedUser = try req.requireAuthenticated(User.self)
        return try authedUser.posts.query(on: req).all().map { posts in
            return try posts.map { post -> PostResponse in
                let user = try UserResponse(id: authedUser.requireID(), name: authedUser.name, username: authedUser.username, email: authedUser.email)
                return PostResponse(post: post, user: user)
            }
        }
    }
    
}

struct CreatePostRequest: Content {
    var post: String
    var imageData: Data
}

struct PostResponse: Encodable {
    var post: Post
    var user: UserResponse
}
