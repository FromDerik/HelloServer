//
//  Friend.swift
//  App
//
//  Created by Derik Malcolm on 6/3/19.
//

import Vapor
import FluentPostgreSQL

struct UserFriend: PostgreSQLPivot, ModifiablePivot {
    typealias Left = User
    typealias Right = User
    
    static let leftIDKey: LeftIDKey = \.userID
    static let rightIDKey: RightIDKey = \.friendID
    
    var id: Int?
    var userID: Int
    var friendID: Int
    
    init(_ left: User, _ right: User) throws {
        self.userID = try left.requireID()
        self.friendID = try right.requireID()
    }
}
