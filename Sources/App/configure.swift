import Authentication
import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(SessionsMiddleware.self) // Enables sessions.
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    
    #if Xcode
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: Environment.get("DB_HOSTNAME")!,
        username: Environment.get("DB_USER")!,
        database: Environment.get("DB_DATABASE")!
    )
    #else
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: Environment.get("DB_HOSTNAME")!,
        username: Environment.get("DB_USER")!,
        database: Environment.get("DB_DATABASE")!,
        password: Environment.get("DB_PASSWORD")!
    )
    #endif
    let postgresql = PostgreSQLDatabase(config: postgresqlConfig)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: postgresql, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserToken.self, database: .psql)
    migrations.add(model: Post.self, database: .psql)
    services.register(migrations)
}
