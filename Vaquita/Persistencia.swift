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
                let recuperado = Evento(nombre: String(localized: "Gastos anteriores"))
                recuperado.decimalesMoneda = 2
                contexto.insert(recuperado)
                for participante in huerfanos { participante.evento = recuperado }
            }
            let eventos = try contexto.fetch(FetchDescriptor<Evento>())
            for evento in eventos {
                if evento.codigoMoneda == nil { evento.codigoMoneda = Moneda.predeterminada() }
                // Preserve every historical cent, including in JPY/CLP events.
                if evento.decimalesMoneda == nil { evento.decimalesMoneda = 2 }
            }
            for participante in participantes where participante.montoUnidades == nil {
                // Invalid legacy amounts stay editable instead of blocking startup.
                if let unidades = try? participante.unidadesValidadas() {
                    participante.asignar(unidades: unidades)
                }
            }
        }
    }
}
