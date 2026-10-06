import SwiftUI
import SwiftData

struct AgregarParticipanteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Participante.nombre) private var historial: [Participante]

    let evento: Evento
    let participanteAEditar: Participante?

    @State private var nombre: String
    @State private var montoTexto: String
    @State private var errorMensaje: String?
    private enum Campo { case nombre, monto }
    @FocusState private var campoEnfocado: Campo?

    init(evento: Evento, participanteAEditar: Participante? = nil) {
        self.evento = evento
        self.participanteAEditar = participanteAEditar
        _nombre = State(initialValue: participanteAEditar?.nombre ?? "")
        _montoTexto = State(initialValue: participanteAEditar.map { persona in
            (try? persona.centavosValidados()).map { Dinero.textoEditable($0) } ?? String(persona.montoPagado)
        } ?? "")
    }

    private var nombreLimpio: String {
        nombre.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sugerencias: [String] {
        guard participanteAEditar == nil, !nombreLimpio.isEmpty else { return [] }

        var nombresVistos = Set<String>()
        let busqueda = nombreLimpio.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return historial.compactMap { participante in
            let nombreHistorico = participante.nombre.trimmingCharacters(in: .whitespacesAndNewlines)
            let clave = nombreHistorico.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            guard clave.contains(busqueda), clave != busqueda,
                  nombresVistos.insert(clave).inserted else { return nil }
            return nombreHistorico
        }
        .prefix(5)
        .map { $0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del participante") {
                    TextField("Nombre", text: $nombre)
                        .accessibilityIdentifier("nombreParticipante")
                        .focused($campoEnfocado, equals: .nombre)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    TextField("Monto aportado", text: $montoTexto)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("importe")
                        .focused($campoEnfocado, equals: .monto)
                    Text("Moneda: \(evento.moneda). Sin separadores de miles; hasta dos decimales. Dejá vacío si no aportó.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !sugerencias.isEmpty {
                    Section("Personas conocidas") {
                        ForEach(sugerencias, id: \.self) { sugerencia in
                            Button {
                                nombre = sugerencia
                            } label: {
                                Label(sugerencia, systemImage: "person.crop.circle")
                            }
                        }
                    }
                }
            }
            .alert("No se pudo guardar", isPresented: Binding(get: { errorMensaje != nil }, set: { if !$0 { errorMensaje = nil } })) {
                Button("Aceptar", role: .cancel) { }
            } message: { Text(errorMensaje ?? "") }
            .navigationTitle(participanteAEditar == nil ? "Nuevo participante" : "Editar participante")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: guardar)
                        .accessibilityIdentifier("guardarParticipante")
                        .disabled(nombreLimpio.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if campoEnfocado != nil {
                    HStack {
                        Spacer()
                        Button("Listo") { campoEnfocado = nil }
                            .accessibilityIdentifier("ocultarTeclado")
                            .frame(minHeight: 44)
                    }
                    .padding(.horizontal)
                    .background(.bar)
                }
            }
        }
    }

    private func guardar() {
        campoEnfocado = nil
        do {
            let centavos = try Dinero.centavos(desde: montoTexto)
            guard !evento.participantes.contains(where: {
                $0.persistentModelID != participanteAEditar?.persistentModelID &&
                CalculadoraVaquita.claveNombre($0.nombre) == CalculadoraVaquita.claveNombre(nombreLimpio)
            }) else {
                errorMensaje = "Ya hay una persona con ese nombre en este evento. Agregá un apellido o apodo para distinguirlas."
                return
            }
            try Persistencia.guardar(en: modelContext) {
                if let participanteAEditar {
                    participanteAEditar.nombre = nombreLimpio
                    participanteAEditar.asignar(centavos: centavos)
                } else {
                    let participante = Participante(nombre: nombreLimpio, evento: evento)
                    participante.asignar(centavos: centavos)
                    modelContext.insert(participante)
                }
            }
            dismiss()
        } catch let error as ErrorImporte {
            errorMensaje = error.localizedDescription
        } catch {
            errorMensaje = "No se guardaron los cambios. Comprobá que haya espacio disponible y volvé a tocar Guardar."
        }
    }
}
