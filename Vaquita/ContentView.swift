import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Participante.nombre) private var participantes: [Participante]
    
    @State private var mostrandoAgregar = false
    @State private var participanteAEditar: Participante?
    @State private var mostrandoConfirmacionLimpiar = false

    // Propiedad computada para evitar cálculos redundantes en el body
    private var transacciones: [Transaccion] {
        CalculadoraVaquita.calcularLiquidacion(participantes: participantes)
    }

    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
        .precision(.fractionLength(0))
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Invitados")) {
                    ForEach(participantes) { invitado in
                        Button {
                            participanteAEditar = invitado
                        } label: {
                            HStack {
                                Text(invitado.nombre)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(invitado.montoPagado, format: currencyFormat)
                                    .foregroundStyle(invitado.montoPagado > 0 ? .green : .secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                    .onDelete(perform: eliminarParticipante)
                }
                
                if !participantes.isEmpty {
                    if !transacciones.isEmpty {
                        Section(header: Text("¿Cómo se paga?")) {
                            ForEach(transacciones) { t in
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("**\(t.de)** paga a **\(t.a)**")
                                    Spacer()
                                    Text(t.monto, format: currencyFormat)
                                        .bold()
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Resumen General")) {
                        let total = participantes.reduce(0) { $0 + $1.montoPagado }
                        let porInvitado = total / Double(max(1, participantes.count))
                        
                        HStack {
                            Text("Total Gastado:")
                            Spacer()
                            Text(total, format: currencyFormat)
                        }
                        HStack {
                            Text("Costo por Invitado:")
                            Spacer()
                            Text(porInvitado, format: currencyFormat)
                                .foregroundStyle(.blue)
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle("Vaquita")
            .overlay {
                if participantes.isEmpty {
                    ContentUnavailableView("No hay nadie", systemImage: "person.3.fill", description: Text("Agregá a los invitados para empezar el asado."))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !participantes.isEmpty {
                        Button(role: .destructive) {
                            mostrandoConfirmacionLimpiar = true
                        } label: {
                            Text("Limpiar")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 20) {
                        if !participantes.isEmpty {
                            let mensaje = CalculadoraVaquita.generarMensajeWhatsApp(participantes: participantes, transacciones: transacciones)
                            
                            ShareLink(item: mensaje) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        
                        Button {
                            participanteAEditar = nil
                            mostrandoAgregar = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .alert("¿Borrar todo?", isPresented: $mostrandoConfirmacionLimpiar) {
                Button("Cancelar", role: .cancel) { }
                Button("Limpiar Todo", role: .destructive) {
                    limpiarBaseDeDatos()
                }
            } message: {
                Text("Se borrarán todos los participantes y gastos. Esta acción no se puede deshacer.")
            }
            .sheet(isPresented: $mostrandoAgregar) {
                AgregarParticipanteView()
            }
            .sheet(item: $participanteAEditar) { invitado in
                AgregarParticipanteView(participanteAEditar: invitado)
            }
        }
    }

    private func limpiarBaseDeDatos() {
        try? modelContext.delete(model: Participante.self)
        try? modelContext.save()
    }

    private func eliminarParticipante(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(participantes[index])
        }
        try? modelContext.save()
    }
}
