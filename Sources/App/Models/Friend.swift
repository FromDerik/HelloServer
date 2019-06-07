//
//  Friend.swift
//  App
//
//  Created by Derik Malcolm on 6/3/19.
//

import Vapor
import FluentPostgreSQL

struct Friend: PostgreSQLModel {
    var id: Int?
    var name: String
    
}
