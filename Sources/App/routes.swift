import Crypto
import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // public routes
    let userController = UserController()
    router.post("users", "create", use: userController.create)
    
    // bearer / token auth protected routes
//    let bearer = router.grouped(User.tokenAuthMiddleware())
//    let todoController = TodoController()
//    bearer.get("todos", use: todoController.index)
//    bearer.post("todos", use: todoController.create)
//    bearer.delete("todos", Todo.parameter, use: todoController.delete)
}
