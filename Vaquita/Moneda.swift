import Foundation

enum Moneda {
    static let codigos = Locale.commonISOCurrencyCodes.filter { $0 != "XXX" && $0 != "XTS" }.sorted()

    static func predeterminada(locale: Locale = .current) -> String {
        guard let codigo = locale.currency?.identifier, codigos.contains(codigo) else { return "USD" }
        return codigo
    }

    static func decimales(_ codigo: String) -> Int {
        let formato = NumberFormatter()
        formato.locale = Locale(identifier: "en_US_POSIX")
        formato.numberStyle = .currency
        formato.currencyCode = codigo
        return min(4, max(0, formato.maximumFractionDigits))
    }

    static func nombre(_ codigo: String, locale: Locale = .current) -> String {
        locale.localizedString(forCurrencyCode: codigo)?.localizedCapitalized ?? codigo
    }
}
