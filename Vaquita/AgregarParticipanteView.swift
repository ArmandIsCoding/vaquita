import SwiftUI
import SwiftData

struct AgregarParticipanteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var participanteAEditar: Participante?
    
    @State private var nombre: String = ""
    // Usamos String para el input para evitar que el Formatter nativo se vuelva loco
    @State private var montoTexto: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Datos del Pibe")) {
                    TextField("Nombre", text: $nombre)
                        .autocorrectionDisabled()
                    
                    HStack {
                        Text("$") // El símbolo fijo para que no moleste al escribir
                        TextField("0", text: $montoTexto)
                            .keyboardType(.numberPad) // Solo números
                            .onChange(of: montoTexto) { oldValue, newValue in
                                // Solo permitimos números
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    montoTexto = filtered
                                }
                            }
                    }
                }
            }
            .navigationTitle(participanteAEditar == nil ? "Nuevo Pibe" : "Editar Pibe")
            .onAppear {
                if let p = participanteAEditar {
                    nombre = p.nombre
                    // Convertimos el Double a String sin decimales para editar
                    montoTexto = String(format: "%.0f", p.montoPagado)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let montoFinal = Double(montoTexto) ?? 0.0
                        
                        if let p = participanteAEditar {
                            p.nombre = nombre
                            p.montoPagado = montoFinal
                        } else {
                            let nuevo = Participante(nombre: nombre, montoPagado: montoFinal)
                            modelContext.insert(nuevo)
                        }
                        
                        // IMPORTANTE: Forzamos el guardado en SwiftData
                        try? modelContext.save()
                        
                        dismiss()
                    }
                    .disabled(nombre.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
