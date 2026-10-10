// Frozen cent-based schema: do not update with the current model.
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

//
//  Participante.swift
//  Vaquita
//
//  Created by Armando Meabe on 23/03/2026.
//

import Foundation
import SwiftData

@Model
final class Participante: Identifiable {
    var nombre: String
    var montoPagado: Double
    // Keep the original Double column so existing stores can migrate without losing data.
    var montoCentavos: Int64?
    var evento: Evento?

    init(nombre: String, montoPagado: Double = 0.0, evento: Evento? = nil) {
        self.nombre = nombre
        self.montoPagado = montoPagado
        self.evento = evento
        self.montoCentavos = nil
    }
    func centavosValidados() throws -> Int64 {
        if let montoCentavos {
            guard (0...Dinero.maximoCentavos).contains(montoCentavos) else { throw ErrorImporte.fueraDeRango }
            return montoCentavos
        }
        return try Dinero.centavosLegados(montoPagado)
    }

    func asignar(centavos: Int64) {
        montoCentavos = centavos
        montoPagado = Double(centavos) / 100
    }
}

import Foundation

enum ErrorImporte: LocalizedError {
    case formato, fueraDeRango

    var errorDescription: String? {
        switch self {
        case .formato:
            return "Ingresá un importe positivo o cero, sin separadores de miles y con hasta dos decimales. Podés usar coma o punto."
        case .fueraDeRango:
            return "El importe es demasiado grande. El máximo por persona es 999.999.999,99."
        }
    }
}

enum Dinero {
    static let maximoCentavos: Int64 = 99_999_999_999

    // Parse the entire input. Never strip signs or silently reinterpret grouping separators.
    static func centavos(desde texto: String) throws -> Int64 {
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        if limpio.isEmpty { return 0 }
        guard limpio.range(of: #"^[0-9]+([.,][0-9]{1,2})?$"#, options: .regularExpression) != nil else {
            throw ErrorImporte.formato
        }
        let partes = limpio.replacingOccurrences(of: ",", with: ".").split(separator: ".")
        guard let enteros = Int64(partes[0]), enteros <= maximoCentavos / 100 else {
            throw ErrorImporte.fueraDeRango
        }
        let fraccion = partes.count == 2 ? String(partes[1]) : ""
        let centavos = enteros * 100 + (Int64(fraccion.padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0)
        guard centavos <= maximoCentavos else { throw ErrorImporte.fueraDeRango }
        return centavos
    }

    static func centavosLegados(_ monto: Double) throws -> Int64 {
        guard monto.isFinite, monto >= 0, monto <= Double(maximoCentavos) / 100 else {
            throw ErrorImporte.fueraDeRango
        }
        guard let importe = Decimal(string: String(monto), locale: Locale(identifier: "en_US_POSIX")) else {
            throw ErrorImporte.fueraDeRango
        }
        var decimal = importe * 100
        var redondeado = Decimal()
        NSDecimalRound(&redondeado, &decimal, 0, .plain)
        return NSDecimalNumber(decimal: redondeado).int64Value
    }

    static func textoEditable(_ centavos: Int64, locale: Locale = .current) -> String {
        let fraccion = String(format: "%02lld", centavos % 100)
        return "\(centavos / 100)\(locale.decimalSeparator ?? ",")\(fraccion)"
    }

    static func formato(_ centavos: Int64, moneda: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = moneda
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(value: centavos).dividing(by: 100)) ?? textoEditable(centavos)
    }
}

@main
struct CentBasedFixture {
    @MainActor static func main() throws {
        let config = ModelConfiguration(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let container = try ModelContainer(for: Evento.self, Participante.self, configurations: config)
        for codigo in ["CLP", "KWD"] {
            let evento = Evento(nombre: codigo)
            evento.codigoMoneda = codigo
            container.mainContext.insert(evento)
            let persona = Participante(nombre: "Anterior", evento: evento)
            persona.asignar(centavos: 1234)
            container.mainContext.insert(persona)
        }
        try container.mainContext.save()
    }
}
