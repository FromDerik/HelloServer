import Crypto
import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // public routes
    let userController = UserController()
    router.post("users", "register", use: userController.register)
    router.post("users", "login", use: userController.login)
    
    let authedRoutes = router.grouped(User.tokenAuthMiddleware())
    authedRoutes.get("users", "logout", use: userController.logout)
    authedRoutes.patch("users", User.parameter, use: userController.update)
    authedRoutes.delete("users", User.parameter, use: userController.delete)
    authedRoutes.get("users", use: userController.list)
    
    let postController = PostController()
    authedRoutes.post("posts", "create", use: postController.create)
    authedRoutes.get("posts", use: postController.list)
}
