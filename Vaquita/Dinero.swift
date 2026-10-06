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
