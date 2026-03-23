import Foundation

struct Transaccion: Identifiable {
    let id = UUID()
    let de: String
    let a: String
    let monto: Double
}

struct CalculadoraVaquita {
    static func calcularLiquidacion(participantes: [Participante]) -> [Transaccion] {
        guard !participantes.isEmpty else { return [] }
        
        let totalGastado = participantes.reduce(0) { $0 + $1.montoPagado }
        let cuotaPorPersona = totalGastado / Double(participantes.count)
        
        var balances = participantes.map { (nombre: $0.nombre, balance: $0.montoPagado - cuotaPorPersona) }
        var transacciones: [Transaccion] = []
        
        while true {
            balances.sort { $0.balance < $1.balance }
            
            guard let deudor = balances.first, let acreedor = balances.last,
                  deudor.balance < -0.01, acreedor.balance > 0.01 else { break }
            
            let montoATransferir = min(abs(deudor.balance), acreedor.balance)
            transacciones.append(Transaccion(de: deudor.nombre, a: acreedor.nombre, monto: montoATransferir))
            
            balances[0].balance += montoATransferir
            balances[balances.count - 1].balance -= montoATransferir
        }
        
        return transacciones
    }

    static func generarMensajeWhatsApp(participantes: [Participante], transacciones: [Transaccion]) -> String {
        let total = participantes.reduce(0) { $0 + $1.montoPagado }
        let porPibe = total / Double(max(1, participantes.count))
        
        var mensaje = "🥩 *Vaquita: Resumen del Asado* 🥩\n\n"
        mensaje += "💰 Total gastado: $\(String(format: "%.0f", total))\n"
        mensaje += "👤 Por pibe: $\(String(format: "%.0f", porPibe))\n\n"
        mensaje += "📝 *Liquidación:* \n"
        
        if transacciones.isEmpty {
            mensaje += "✅ ¡Están todos al día!"
        } else {
            for t in transacciones {
                mensaje += "• *\(t.de)* le paga $\(String(format: "%.0f", t.monto)) a *\(t.a)*\n"
            }
        }
        
        mensaje += "\n_Generado por Vaquita App_ 🐮"
        return mensaje
    }
}
