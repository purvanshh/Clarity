import Foundation
import SwiftData

enum ClarityPersistence {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([ClarityTask.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
