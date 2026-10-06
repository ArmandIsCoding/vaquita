import Foundation
import SwiftData

@Model
final class Evento {
    var nombre: String
    var fechaCreacion: Date
    var codigoMoneda: String?

    var moneda: String { codigoMoneda ?? "ARS" }

    @Relationship(deleteRule: .cascade, inverse: \Participante.evento)
    var participantes: [Participante]

    init(nombre: String, fechaCreacion: Date = .now) {
        self.nombre = nombre
        self.fechaCreacion = fechaCreacion
        self.codigoMoneda = Locale.current.currency?.identifier ?? "ARS"
        self.participantes = []
    }
}
