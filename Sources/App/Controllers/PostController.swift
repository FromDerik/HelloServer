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
            let post = try Post(post: postRequest.post, userID: user.requireID())
            return post.save(on: req).transform(to: HTTPResponse(status: .ok))
        }
    }
    
    func list(_ req: Request) throws -> Future<[Post]> {
        let user = try req.requireAuthenticated(User.self)
        return try Post.query(on: req).filter(\.userID == user.requireID()).all()
    }
    
}

struct CreatePostRequest: Content {
    var post: String
}
