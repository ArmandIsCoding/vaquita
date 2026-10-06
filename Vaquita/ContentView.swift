import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Evento.fechaCreacion, order: .reverse) private var eventos: [Evento]

    @State private var mostrandoInformacion = false
    @State private var errorGuardado = false
    @State private var ruta: [Evento] = []
    @State private var mostrandoNuevoEvento = false
    @State private var eventoRecienCreado: Evento?
    @State private var eventoAEditar: Evento?
    @State private var eventoAEliminar: Evento?

    var body: some View {
        NavigationStack(path: $ruta) {
            List {
                ForEach(eventos) { evento in
                    EventoRow(evento: evento) {
                        eventoAEditar = evento
                    } onDelete: {
                        eventoAEliminar = evento
                    }
                }
            }
            .navigationTitle("Eventos")
            .overlay {
                if eventos.isEmpty {
                    ContentUnavailableView(
                        "Todavía no hay eventos",
                        systemImage: "calendar.badge.plus",
                        description: Text("Creá una juntada para empezar a dividir gastos.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { mostrandoInformacion = true } label: {
                        Label("Ayuda y privacidad", systemImage: "info.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrandoNuevoEvento = true
                    } label: {
                        Label("Nuevo evento", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrandoInformacion) { InformacionView() }
            .alert("No se pudo eliminar", isPresented: $errorGuardado) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                Text("El evento se conservó. Comprobá el espacio disponible y volvé a intentar.")
            }
            .navigationDestination(for: Evento.self) { evento in
                EventoDetalleView(evento: evento)
            }
            .sheet(isPresented: $mostrandoNuevoEvento, onDismiss: {
                if let eventoRecienCreado {
                    ruta.append(eventoRecienCreado)
                    self.eventoRecienCreado = nil
                }
            }) {
                EditarEventoView { eventoRecienCreado = $0 }
            }
            .sheet(item: $eventoAEditar) { evento in
                EditarEventoView(evento: evento)
            }
            .alert(
                "¿Eliminar este evento?",
                isPresented: Binding(
                    get: { eventoAEliminar != nil },
                    set: { if !$0 { eventoAEliminar = nil } }
                ),
                presenting: eventoAEliminar
            ) { evento in
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    do {
                        try Persistencia.guardar(en: modelContext) { modelContext.delete(evento) }
                    } catch { errorGuardado = true }
                }
            } message: { evento in
                Text("Se eliminarán “\(evento.nombre)” y todos sus participantes.")
            }
        }
    }
}

private struct EventoRow: View {
    let evento: Evento
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var mensaje: String? {
        guard let liquidacion = try? CalculadoraVaquita.liquidar(participantes: evento.participantes) else { return nil }
        return CalculadoraVaquita.generarMensajeParaCompartir(evento: evento, liquidacion: liquidacion)
    }

    var body: some View {
        NavigationLink(value: evento) {
            VStack(alignment: .leading, spacing: 4) {
                Text(evento.nombre)
                    .font(.headline)
                Text(evento.participantes.count == 1 ? "1 participante" : "\(evento.participantes.count) participantes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .leading) {
            Button("Editar", systemImage: "pencil", action: onEdit)
                .tint(.blue)
            if let mensaje {
                ShareLink(item: mensaje) { Label("Compartir", systemImage: "square.and.arrow.up") }
                    .tint(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button("Eliminar", systemImage: "trash", role: .destructive, action: onDelete)
        }
        .contextMenu {
            Button("Editar", systemImage: "pencil", action: onEdit)
            if let mensaje {
                ShareLink(item: mensaje) { Label("Compartir", systemImage: "square.and.arrow.up") }
            }
            Button("Eliminar", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}

private struct EditarEventoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let evento: Evento?
    let onCreated: ((Evento) -> Void)?
    @State private var nombre: String
    @State private var errorGuardado = false

    init(evento: Evento? = nil, onCreated: ((Evento) -> Void)? = nil) {
        self.evento = evento
        self.onCreated = onCreated
        _nombre = State(initialValue: evento?.nombre ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nombre del evento", text: $nombre)
                    .accessibilityIdentifier("nombreEvento")
                    .textInputAutocapitalization(.sentences)
            }
            .alert("No se pudo guardar", isPresented: $errorGuardado) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                Text("No se guardaron los cambios. Comprobá el espacio disponible y volvé a tocar Guardar.")
            }
            .navigationTitle(evento == nil ? "Nuevo evento" : "Editar evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: guardar)
                        .disabled(nombreLimpio.isEmpty)
                }
            }
        }
    }

    private var nombreLimpio: String {
        nombre.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func guardar() {
        do {
            var eventoCreado: Evento?
            try Persistencia.guardar(en: modelContext) {
                if let evento {
                    evento.nombre = nombreLimpio
                } else {
                    let nuevoEvento = Evento(nombre: nombreLimpio)
                    modelContext.insert(nuevoEvento)
                    eventoCreado = nuevoEvento
                }
            }
            if let eventoCreado { onCreated?(eventoCreado) }
            dismiss()
        } catch { errorGuardado = true }
    }
}
