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
