import SwiftUI
import SwiftData

struct AgregarParticipanteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var participanteAEditar: Participante?
    
    @State private var nombre: String = ""
    @State private var montoTexto: String = ""
    
    // Símbolo de moneda dinámico corregido
    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.currencySymbol ?? "$"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Datos del Invitado")) {
                    TextField("Nombre", text: $nombre)
                        .autocorrectionDisabled()
                    
                    HStack {
                        Text(currencySymbol)
                        TextField("0", text: $montoTexto)
                            .keyboardType(.numberPad)
                            .onChange(of: montoTexto) { oldValue, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    montoTexto = filtered
                                }
                            }
                    }
                }
            }
            .navigationTitle(participanteAEditar == nil ? "Nuevo Invitado" : "Editar Invitado")
            .onAppear {
                if let p = participanteAEditar {
                    nombre = p.nombre
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
