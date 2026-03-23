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
    
    init(nombre: String, montoPagado: Double = 0.0) {
        self.nombre = nombre
        self.montoPagado = montoPagado
    }
}
