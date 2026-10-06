import Foundation
import SwiftData

// Frozen copies of the two schemas that existed before the cents migration.
@Model
final class Participante {
    var nombre: String
    var montoPagado: Double
    var evento: Evento?
    init(nombre: String, montoPagado: Double) {
        self.nombre = nombre
        self.montoPagado = montoPagado
    }
}
@Model
final class Evento {
    var nombre: String
    var fechaCreacion: Date
    @Relationship(deleteRule: .cascade, inverse: \Participante.evento)
    var participantes: [Participante]
    init(nombre: String) {
        self.nombre = nombre
        self.fechaCreacion = .now
        self.participantes = []
    }
}

@main
struct LegacyFixture {
    @MainActor static func main() throws {
        let config = ModelConfiguration(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let container = try ModelContainer(for: Evento.self, Participante.self, configurations: config)
        let contexto = container.mainContext
        contexto.insert(Participante(nombre: "Anterior", montoPagado: 12.50))
        let evento = Evento(nombre: "Evento conservado")
        contexto.insert(evento)
        let persona = Participante(nombre: "Con evento", montoPagado: 25.75)
        persona.evento = evento
        contexto.insert(persona)
        try contexto.save()
    }
}
