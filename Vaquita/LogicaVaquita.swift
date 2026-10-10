import Foundation
import SwiftData

struct Transaccion: Identifiable {
    struct ID: Hashable {
        let de: PersistentIdentifier
        let a: PersistentIdentifier
    }
    let id: ID
    let de: String
    let a: String
    let unidades: Int64
}

struct CuotaParticipante: Identifiable {
    let id: PersistentIdentifier
    let nombre: String
    let aportado: Int64
    let cuota: Int64
}

struct LiquidacionEvento {
    let total: Int64
    let cuotas: [CuotaParticipante]
    let transacciones: [Transaccion]

    func reparto(moneda: String, decimales: Int = 2) -> String {
        guard let minima = cuotas.map(\.cuota).min(), let maxima = cuotas.map(\.cuota).max() else {
            return Dinero.formato(0, moneda: moneda, decimales: decimales)
        }
        if minima == maxima { return Dinero.formato(minima, moneda: moneda, decimales: decimales) }
        return String(localized: "\(Dinero.formato(minima, moneda: moneda, decimales: decimales)) a \(Dinero.formato(maxima, moneda: moneda, decimales: decimales))")
    }
}

enum CalculadoraVaquita {
    static func claveNombre(_ nombre: String) -> String {
        nombre.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }

    static func ordenar(_ participantes: [Participante]) -> [Participante] {
        participantes.sorted {
            let izquierda = claveNombre($0.nombre)
            let derecha = claveNombre($1.nombre)
            if izquierda != derecha { return izquierda < derecha }
            return String(describing: $0.persistentModelID) < String(describing: $1.persistentModelID)
        }
    }

    static func liquidar(participantes: [Participante]) throws -> LiquidacionEvento {
        let ordenados = ordenar(participantes)
        guard !ordenados.isEmpty else { return LiquidacionEvento(total: 0, cuotas: [], transacciones: []) }
        let aportes = try ordenados.map { try $0.unidadesValidadas() }
        var total: Int64 = 0
        for aporte in aportes {
            let suma = total.addingReportingOverflow(aporte)
            guard !suma.overflow else { throw ErrorImporte.fueraDeRango }
            total = suma.partialValue
        }
        let base = total / Int64(ordenados.count)
        let resto = Int(total % Int64(ordenados.count))
        let grupos = Dictionary(grouping: ordenados, by: { claveNombre($0.nombre) })
        var ocurrencias: [String: Int] = [:]
        let cuotas = ordenados.enumerated().map { indice, persona in
            let clave = claveNombre(persona.nombre)
            ocurrencias[clave, default: 0] += 1
            let nombre = (grupos[clave]?.count ?? 0) > 1
                ? "\(persona.nombre) (\(ocurrencias[clave]!))" : persona.nombre
            return CuotaParticipante(id: persona.persistentModelID, nombre: nombre, aportado: aportes[indice],
                                     cuota: base + (indice < resto ? 1 : 0))
        }
        var balances = cuotas.map { $0.aportado - $0.cuota }
        var transacciones: [Transaccion] = []
        // Match creditors and debtors in stable order. All arithmetic is in whole minor units.
        var deudor = 0
        var acreedor = 0
        while deudor < cuotas.count && acreedor < cuotas.count {
            if balances[deudor] >= 0 { deudor += 1; continue }
            if balances[acreedor] <= 0 { acreedor += 1; continue }
            let monto = min(-balances[deudor], balances[acreedor])
            transacciones.append(Transaccion(id: .init(de: cuotas[deudor].id, a: cuotas[acreedor].id),
                                             de: cuotas[deudor].nombre, a: cuotas[acreedor].nombre, unidades: monto))
            balances[deudor] += monto
            balances[acreedor] -= monto
        }
        return LiquidacionEvento(total: total, cuotas: cuotas, transacciones: transacciones)
    }

    static func generarMensajeParaCompartir(evento: Evento, liquidacion: LiquidacionEvento) -> String {
        let moneda = evento.moneda
        let decimales = evento.decimales
        var lineas = ["🐮 \(evento.nombre)", "",
                      String(localized: "Moneda: \(moneda)"),
                      String(localized: "Total gastado: \(Dinero.formato(liquidacion.total, moneda: moneda, decimales: decimales))"),
                      String(localized: "Por persona: \(liquidacion.reparto(moneda: moneda, decimales: decimales))"), ""]
        for cuota in liquidacion.cuotas {
            lineas.append(String(localized: "• \(cuota.nombre): aportó \(Dinero.formato(cuota.aportado, moneda: moneda, decimales: decimales)); le corresponde \(Dinero.formato(cuota.cuota, moneda: moneda, decimales: decimales))."))
        }
        lineas += ["", String(localized: "Liquidación:")]
        if liquidacion.cuotas.isEmpty {
            lineas.append(String(localized: "Todavía no hay participantes."))
        } else if liquidacion.transacciones.isEmpty {
            lineas.append(String(localized: "¡Están todos al día!"))
        } else {
            for t in liquidacion.transacciones {
                lineas.append(String(localized: "• \(t.de) le paga \(Dinero.formato(t.unidades, moneda: moneda, decimales: decimales)) a \(t.a)."))
            }
        }
        lineas += ["", String(localized: "El resto se distribuye en la unidad mínima del evento y en el orden de la lista."), String(localized: "Generado por Vaquita 🐮")]
        return lineas.joined(separator: "\n")
    }
}
