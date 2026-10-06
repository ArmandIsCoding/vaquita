import Foundation
import SwiftData

@main
struct MigrationCheck {
    @MainActor static func main() throws {
        let config = ModelConfiguration(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let container = try ModelContainer(for: Evento.self, Participante.self, configurations: config)
        let contexto = container.mainContext
        try Persistencia.preparar(contexto)
        try Persistencia.preparar(contexto)
        let eventos = try contexto.fetch(FetchDescriptor<Evento>())
        let anteriores = eventos.filter { $0.nombre == "Gastos anteriores" }
        precondition(anteriores.count == 1)
        precondition(anteriores[0].participantes.count == 1)
        precondition(anteriores[0].participantes[0].montoCentavos == 1250)
        let personas = try contexto.fetch(FetchDescriptor<Participante>())
        precondition(personas.allSatisfy { $0.evento != nil })
        if CommandLine.arguments.last == "events" {
            precondition(eventos.count == 2)
            precondition(eventos.first { $0.nombre == "Evento conservado" }?.participantes.first?.montoCentavos == 2575)
        } else { precondition(eventos.count == 1) }
        print("Migration OK:", personas.count, "participants,", eventos.count, "events")
    }
}
