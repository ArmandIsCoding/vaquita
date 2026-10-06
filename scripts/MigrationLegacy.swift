import Foundation
import SwiftData

// Frozen copies of the two schemas that existed before the cents migration.
@Model
final class Participante {
    var nombre: String
    var montoPagado: Double
    init(nombre: String, montoPagado: Double) {
        self.nombre = nombre
        self.montoPagado = montoPagado
    }
}

@main
struct LegacyFixture {
    @MainActor static func main() throws {
        let config = ModelConfiguration(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let container = try ModelContainer(for: Participante.self, configurations: config)
        let contexto = container.mainContext
        contexto.insert(Participante(nombre: "Anterior", montoPagado: 12.50))
        try contexto.save()
    }
}
