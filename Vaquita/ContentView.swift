import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Participante.nombre) private var participantes: [Participante]
    
    @State private var mostrandoAgregar = false
    @State private var participanteAEditar: Participante?
    @State private var mostrandoConfirmacionLimpiar = false

    // Formateador automático que detecta la moneda del iPhone del usuario
    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
        .precision(.fractionLength(0)) // En asados no usamos centavos
    }

    var body: some View {
        NavigationStack {
            List {
                // --- SECCIÓN: LISTADO ---
                Section(header: Text("Pibes del Asado")) {
                    ForEach(participantes) { pibe in
                        Button {
                            participanteAEditar = pibe
                        } label: {
                            HStack {
                                Text(pibe.nombre)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                // Formato dinámico según el país del usuario
                                Text(pibe.montoPagado, format: currencyFormat)
                                    .foregroundStyle(pibe.montoPagado > 0 ? .green : .secondary)
                                    .monospacedDigit() // Evita que los números "salten" al cambiar
                            }
                        }
                    }
                    .onDelete(perform: eliminarParticipante)
                }
                
                // --- SECCIÓN: RESULTADOS ---
                let transacciones = CalculadoraVaquita.calcularLiquidacion(participantes: participantes)
                
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
                        let porPibe = total / Double(max(1, participantes.count))
                        
                        HStack {
                            Text("Total Gastado:")
                            Spacer()
                            Text(total, format: currencyFormat)
                        }
                        HStack {
                            Text("Costo por Pibe:")
                            Spacer()
                            Text(porPibe, format: currencyFormat)
                                .foregroundStyle(.blue)
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle("Vaquita")
            .overlay {
                if participantes.isEmpty {
                    ContentUnavailableView("No hay nadie", systemImage: "person.3.fill", description: Text("Agregá a los pibes para empezar el asado."))
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
                            let transacciones = CalculadoraVaquita.calcularLiquidacion(participantes: participantes)
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
            .sheet(item: $participanteAEditar) { pibe in
                AgregarParticipanteView(participanteAEditar: pibe)
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
