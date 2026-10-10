import Foundation

enum ErrorImporte: LocalizedError {
    case formato, fueraDeRango

    var errorDescription: String? {
        switch self {
        case .formato:
            return String(localized: "Revisá el importe y los decimales de esta moneda. Usá un número positivo o cero, sin separadores de miles. Podés usar coma o punto decimal.")
        case .fueraDeRango:
            return String(localized: "El importe es demasiado grande. Debe ser menor a mil millones por persona.")
        }
    }
}

enum Dinero {
    static let maximoCentavos: Int64 = 99_999_999_999

    static func factor(decimales: Int) -> Int64 {
        precondition((0...4).contains(decimales))
        return (0..<decimales).reduce(Int64(1)) { valor, _ in valor * 10 }
    }

    static func maximo(decimales: Int) -> Int64 { 1_000_000_000 * factor(decimales: decimales) - 1 }

    // Parse the whole input; never strip signs, grouping, or excess decimal places.
    static func unidades(desde texto: String, decimales: Int, locale: Locale = .current) throws -> Int64 {
        let entrada = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        // Decimal keyboards may use local digits and a non-Latin decimal separator.
        let normalizado = entrada.replacingOccurrences(of: locale.decimalSeparator ?? ".", with: ".")
        let limpio = normalizado.map { caracter -> String in
            if caracter.unicodeScalars.count == 1,
               caracter.unicodeScalars.first?.properties.generalCategory == .decimalNumber,
               let digito = caracter.wholeNumberValue { return String(digito) }
            return String(caracter)
        }.joined()
        if limpio.isEmpty { return 0 }
        let patron = decimales == 0 ? #"^[0-9]+$"# : "^[0-9]+([.,][0-9]{1,\(decimales)})?$"
        guard limpio.range(of: patron, options: .regularExpression) != nil else { throw ErrorImporte.formato }
        let partes = limpio.replacingOccurrences(of: ",", with: ".").split(separator: ".")
        guard let enteros = Int64(partes[0]), enteros < 1_000_000_000 else { throw ErrorImporte.fueraDeRango }
        let fraccion = partes.count == 2 ? String(partes[1]) : ""
        return enteros * factor(decimales: decimales) + (Int64(fraccion.padding(toLength: decimales, withPad: "0", startingAt: 0)) ?? 0)
    }

    static func centavos(desde texto: String) throws -> Int64 { try unidades(desde: texto, decimales: 2) }

    static func centavosLegados(_ monto: Double) throws -> Int64 { try unidadesLegadas(monto, decimales: 2) }

    static func unidadesLegadas(_ monto: Double, decimales: Int) throws -> Int64 {
        let escala = factor(decimales: decimales)
        guard monto.isFinite, monto >= 0, monto <= Double(maximo(decimales: decimales)) / Double(escala),
              let importe = Decimal(string: String(monto), locale: Locale(identifier: "en_US_POSIX")) else {
            throw ErrorImporte.fueraDeRango
        }
        var decimal = importe * Decimal(escala)
        var redondeado = Decimal()
        NSDecimalRound(&redondeado, &decimal, 0, .plain)
        return NSDecimalNumber(decimal: redondeado).int64Value
    }

    static func textoEditable(_ unidades: Int64, decimales: Int = 2, locale: Locale = .current) -> String {
        let escala = factor(decimales: decimales)
        guard decimales > 0 else { return String(unidades) }
        let fraccion = String(format: "%0*lld", decimales, unidades % escala)
        return "\(unidades / escala)\(locale.decimalSeparator ?? ".")\(fraccion)"
    }

    static func formato(_ unidades: Int64, moneda: String, decimales: Int? = nil, locale: Locale = .current) -> String {
        let precision = decimales ?? Moneda.decimales(moneda)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = moneda
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        let numero = NSDecimalNumber(value: unidades).dividing(by: NSDecimalNumber(value: factor(decimales: precision)))
        return formatter.string(from: numero) ?? "\(textoEditable(unidades, decimales: precision, locale: locale)) \(moneda)"
    }
}
