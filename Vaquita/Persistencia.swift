import SwiftData
import Foundation

@MainActor
enum Persistencia {
    static func guardar(en contexto: ModelContext, cambios: () throws -> Void) throws {
        do {
            try cambios()
            try contexto.save()
        } catch {
            contexto.rollback()
            throw error
        }
    }

    static func preparar(_ contexto: ModelContext) throws {
        contexto.autosaveEnabled = false
        try guardar(en: contexto) {
            let participantes = try contexto.fetch(FetchDescriptor<Participante>())
            let huerfanos = participantes.filter { $0.evento == nil }
            if !huerfanos.isEmpty {
                let recuperado = Evento(nombre: "Gastos anteriores")
                contexto.insert(recuperado)
                for participante in huerfanos { participante.evento = recuperado }
            }
            for participante in participantes where participante.montoCentavos == nil {
                // Invalid legacy amounts stay editable, instead of preventing the app from opening.
                if let centavos = try? Dinero.centavosLegados(participante.montoPagado) {
                    participante.asignar(centavos: centavos)
                }
            }
            for evento in try contexto.fetch(FetchDescriptor<Evento>()) where evento.codigoMoneda == nil {
                evento.codigoMoneda = Locale.current.currency?.identifier ?? "ARS"
            }
        }
    }
}
