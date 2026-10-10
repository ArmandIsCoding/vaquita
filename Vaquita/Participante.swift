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
    var montoUnidades: Int64?
    var evento: Evento?
    
    init(nombre: String, montoPagado: Double = 0.0, evento: Evento? = nil) {
        self.nombre = nombre
        self.montoPagado = montoPagado
        self.evento = evento
        self.montoCentavos = nil
        self.montoUnidades = nil
    }
    func unidadesValidadas() throws -> Int64 {
        let decimales = evento?.decimales ?? 2
        if let unidades = montoUnidades ?? montoCentavos {
            guard (0...Dinero.maximo(decimales: decimales)).contains(unidades) else { throw ErrorImporte.fueraDeRango }
            return unidades
        }
        return try Dinero.unidadesLegadas(montoPagado, decimales: decimales)
    }

    func asignar(unidades: Int64) {
        let decimales = evento?.decimales ?? 2
        montoUnidades = unidades
        montoCentavos = decimales == 2 ? unidades : nil
        montoPagado = Double(unidades) / Double(Dinero.factor(decimales: decimales))
    }
}
