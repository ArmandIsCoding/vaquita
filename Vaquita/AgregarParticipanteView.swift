import SwiftUI
import SwiftData

struct AgregarParticipanteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var tamanoTexto
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
            (try? persona.unidadesValidadas()).map { Dinero.textoEditable($0, decimales: evento.decimales) } ?? String(persona.montoPagado)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !tamanoTexto.isAccessibilitySize {
                        HStack(spacing: 16) {
                            AvatarPersona(nombre: nombre.isEmpty ? "?" : nombre, dimension: 62)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(participanteAEditar == nil ? String(localized: "Uno más en el plan.") : String(localized: "Cada aporte cuenta."))
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                    .foregroundStyle(EstiloVaquita.tinta)
                                Text(evento.nombre)
                                    .font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text(evento.nombre)
                            .font(.headline).foregroundStyle(EstiloVaquita.tinta)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("¿QUIÉN SE SUMA?")
                            .font(.caption.weight(.bold)).foregroundStyle(EstiloVaquita.secundario)
                        TextField("Nombre o apodo", text: $nombre,
                                  prompt: Text("Nombre o apodo").foregroundStyle(EstiloVaquita.secundario))
                            .font(.title3.weight(.medium))
                            .accessibilityLabel("Nombre")
                            .accessibilityIdentifier("nombreParticipante")
                            .focused($campoEnfocado, equals: .nombre)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .onSubmit { campoEnfocado = .monto }
                            .padding(.vertical, 8)
                    }
                    .tarjetaVaquita()

                    if !sugerencias.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PERSONAS CONOCIDAS")
                                .font(.caption.weight(.bold)).foregroundStyle(EstiloVaquita.secundario)
                            ForEach(sugerencias, id: \.self) { sugerencia in
                                Button {
                                    nombre = sugerencia
                                    campoEnfocado = .monto
                                } label: {
                                    HStack(spacing: 12) {
                                        AvatarPersona(nombre: sugerencia, dimension: 30)
                                        Text(sugerencia).font(.subheadline.weight(.medium))
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                    }
                                    .frame(minHeight: 44)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("¿CUÁNTO APORTÓ?")
                                .font(.caption.weight(.bold)).foregroundStyle(EstiloVaquita.secundario)
                            Spacer()
                            EtiquetaCapsula(texto: evento.moneda)
                        }
                        TextField(Dinero.textoEditable(0, decimales: evento.decimales), text: $montoTexto,
                                  prompt: Text(Dinero.textoEditable(0, decimales: evento.decimales)).foregroundStyle(EstiloVaquita.secundario))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(EstiloVaquita.acento)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Monto aportado")
                            .accessibilityIdentifier("importe")
                            .focused($campoEnfocado, equals: .monto)
                            .padding(.vertical, 4)
                        Text("Dejalo en cero si todavía no pagó.")
                            .font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
                    }
                    .tarjetaVaquita()

                    Label("Sumá también a quienes no aportaron: el gasto se reparte entre todos.", systemImage: "person.2")
                        .font(.footnote).foregroundStyle(EstiloVaquita.secundario)
                    Text(evento.decimales == 0
                         ? String(localized: "Importes en \(evento.moneda), sin decimales ni separadores de miles.")
                         : String(localized: "Importes en \(evento.moneda), con hasta \(evento.decimales) decimales y sin separadores de miles."))
                        .font(.footnote).foregroundStyle(EstiloVaquita.secundario)
                }
                .foregroundStyle(EstiloVaquita.tinta)
                .padding(24)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(EstiloVaquita.fondo)
            .alert("No se pudo guardar", isPresented: Binding(get: { errorMensaje != nil }, set: { if !$0 { errorMensaje = nil } })) {
                Button("Aceptar", role: .cancel) { }
            } message: { Text(errorMensaje ?? "") }
            .navigationTitle(participanteAEditar == nil ? String(localized: "Sumar persona") : String(localized: "Editar aporte"))
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
                    .background(EstiloVaquita.fondo)
                }
            }
        }
        .tint(EstiloVaquita.acento)
    }

    private func guardar() {
        guard !nombreLimpio.isEmpty else { return }
        campoEnfocado = nil
        do {
            let unidades = try Dinero.unidades(desde: montoTexto, decimales: evento.decimales)
            guard !evento.participantes.contains(where: {
                $0.persistentModelID != participanteAEditar?.persistentModelID &&
                CalculadoraVaquita.claveNombre($0.nombre) == CalculadoraVaquita.claveNombre(nombreLimpio)
            }) else {
                errorMensaje = String(localized: "Ya hay una persona con ese nombre en este evento. Agregá un apellido o apodo para distinguirlas.")
                return
            }
            try Persistencia.guardar(en: modelContext) {
                if let participanteAEditar {
                    participanteAEditar.nombre = nombreLimpio
                    participanteAEditar.asignar(unidades: unidades)
                } else {
                    let participante = Participante(nombre: nombreLimpio, evento: evento)
                    participante.asignar(unidades: unidades)
                    modelContext.insert(participante)
                }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch let error as ErrorImporte {
            errorMensaje = error.localizedDescription
        } catch {
            errorMensaje = String(localized: "No se guardaron los cambios. Comprobá que haya espacio disponible y volvé a tocar Guardar.")
        }
    }
}
