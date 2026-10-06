import SwiftUI
import SwiftData

struct EventoDetalleView: View {
    @Environment(\.modelContext) private var modelContext
    let evento: Evento
    @State private var mostrandoAgregar = false
    @State private var participanteAEditar: Participante?
    @State private var mostrandoConfirmacionLimpiar = false
    @State private var errorGuardado = false

    private var participantes: [Participante] { CalculadoraVaquita.ordenar(evento.participantes) }

    var body: some View {
        let liquidacion = try? CalculadoraVaquita.liquidar(participantes: participantes)
        List {
            Section {
                ForEach(participantes) { participante in
                    let cuota = liquidacion?.cuotas.first { $0.id == participante.persistentModelID }
                    Button { participanteAEditar = participante } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(cuota?.nombre ?? participante.nombre).font(.headline)
                            if let importe = try? participante.centavosValidados() {
                                Text("Aportó \(Dinero.formato(importe, moneda: evento.moneda))")
                                if let cuota {
                                    Text("Le corresponde \(Dinero.formato(cuota.cuota, moneda: evento.moneda))")
                                        .font(.subheadline).foregroundStyle(.primary)
                                }
                            } else {
                                Label("Revisá este importe", systemImage: "exclamationmark.triangle")
                            }
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Editar nombre o aporte")
                }
                .onDelete(perform: eliminarParticipante)
            } header: { Text("Participantes · \(evento.moneda)").foregroundStyle(Color(uiColor: .label)) }
            if let liquidacion, !participantes.isEmpty {
                if !liquidacion.transacciones.isEmpty {
                    Section {
                        ForEach(liquidacion.transacciones) { transaccion in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(transaccion.de) paga a \(transaccion.a)")
                                Text(Dinero.formato(transaccion.centavos, moneda: evento.moneda))
                                    .font(.headline)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityElement(children: .combine)
                        }
                    } header: { Text("¿Cómo se paga?").foregroundStyle(Color(uiColor: .label)) }
                } else {
                    Section { Label("¡Están todos al día!", systemImage: "checkmark.circle") }
                }
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total gastado").font(.subheadline)
                        Text(Dinero.formato(liquidacion.total, moneda: evento.moneda)).font(.headline)
                    }.accessibilityElement(children: .combine)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Costo por persona").font(.subheadline)
                        Text(liquidacion.reparto(moneda: evento.moneda)).font(.headline)
                    }.accessibilityElement(children: .combine)
                } header: { Text("Resumen general").foregroundStyle(Color(uiColor: .label)) } footer: {
                    Text("Los centavos sobrantes se distribuyen en el orden de la lista. Cada persona tiene su importe exacto indicado arriba.").foregroundStyle(Color(uiColor: .label))
                }
            } else if !participantes.isEmpty {
                Section {
                    Label("Hay importes que necesitan revisión. Tocá cada participante señalado para corregirlos.", systemImage: "exclamationmark.triangle")
                }
            }
        }
        .navigationTitle(evento.nombre)
        .overlay {
            if participantes.isEmpty {
                ContentUnavailableView("No hay participantes", systemImage: "person.3.fill",
                                       description: Text("Agregá personas para empezar a dividir los gastos."))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let liquidacion, !participantes.isEmpty {
                    ShareLink(item: CalculadoraVaquita.generarMensajeParaCompartir(evento: evento, liquidacion: liquidacion)) {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                    }
                }
                Button { mostrandoAgregar = true } label: {
                    Label("Agregar participante", systemImage: "person.badge.plus")
                }
                if !participantes.isEmpty {
                    Menu {
                        Button("Limpiar participantes", systemImage: "trash", role: .destructive) {
                            mostrandoConfirmacionLimpiar = true
                        }
                    } label: { Label("Más opciones", systemImage: "ellipsis.circle") }
                }
            }
        }
        .alert("¿Borrar los participantes?", isPresented: $mostrandoConfirmacionLimpiar) {
            Button("Cancelar", role: .cancel) { }
            Button("Limpiar", role: .destructive) { eliminar(participantes) }
        } message: { Text("Se eliminarán todos los participantes de este evento.") }
        .alert("No se pudo eliminar", isPresented: $errorGuardado) {
            Button("Aceptar", role: .cancel) { }
        } message: { Text("Los participantes se conservaron. Comprobá el espacio disponible y volvé a intentar.") }
        .sheet(isPresented: $mostrandoAgregar) { AgregarParticipanteView(evento: evento) }
        .sheet(item: $participanteAEditar) { AgregarParticipanteView(evento: evento, participanteAEditar: $0) }
    }

    private func eliminarParticipante(offsets: IndexSet) {
        let seleccionados = offsets.map { participantes[$0] }
        eliminar(seleccionados)
    }

    private func eliminar(_ seleccionados: [Participante]) {
        do {
            try Persistencia.guardar(en: modelContext) { seleccionados.forEach(modelContext.delete) }
        } catch { errorGuardado = true }
    }
}
