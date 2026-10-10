import Foundation
import SwiftData

@Model
final class Evento {
    var nombre: String
    var fechaCreacion: Date
    var codigoMoneda: String?
    // Nil identifies historical events whose amounts were stored in hundredths.
    var decimalesMoneda: Int?

    var moneda: String { codigoMoneda ?? "ARS" }
    var decimales: Int { decimalesMoneda ?? 2 }

    @Relationship(deleteRule: .cascade, inverse: \Participante.evento)
    var participantes: [Participante]

    init(nombre: String, fechaCreacion: Date = .now, moneda: String? = nil, locale: Locale = .current) {
        self.nombre = nombre
        self.fechaCreacion = fechaCreacion
        let codigo = moneda ?? Moneda.predeterminada(locale: locale)
        self.codigoMoneda = codigo
        self.decimalesMoneda = Moneda.decimales(codigo)
        self.participantes = []
    }
}
