import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var tamanoTexto
    @Query(sort: \Evento.fechaCreacion, order: .reverse) private var eventos: [Evento]

    @State private var mostrandoInformacion = false
    @State private var errorGuardado = false
    @State private var ruta: [Evento] = []
    @State private var hojaEvento: HojaEvento?
    @State private var eventoRecienCreado: Evento?
    @State private var eventoAEliminar: Evento?
    @State private var busqueda = ""
    @FocusState private var busquedaEnfocada: Bool

    private var eventosFiltrados: [Evento] {
        let texto = busqueda.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return eventos }
        return eventos.filter { $0.nombre.localizedStandardContains(texto) }
    }

    var body: some View {
        NavigationStack(path: $ruta) {
            List {
                if !tamanoTexto.isAccessibilitySize || eventos.isEmpty {
                    portada.filaVaquita()
                }

                if eventos.isEmpty {
                    bienvenida.filaVaquita()
                } else {
                    if eventos.count > 4 {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass").foregroundStyle(EstiloVaquita.secundario)
                            TextField("Buscar un evento", text: $busqueda,
                                      prompt: Text("Buscar").foregroundStyle(EstiloVaquita.secundario))
                                .accessibilityLabel("Buscar un evento")
                                .accessibilityIdentifier("buscarEvento")
                                .focused($busquedaEnfocada)
                                .submitLabel(.search)
                                .onSubmit { busquedaEnfocada = false }
                                .autocorrectionDisabled()
                            if !busqueda.isEmpty {
                                Button { busqueda = "" } label: { Image(systemName: "xmark.circle.fill") }
                                    .accessibilityLabel("Borrar búsqueda")
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(EstiloVaquita.superficie, in: RoundedRectangle(cornerRadius: 18))
                        .filaVaquita()
                    }
                    EncabezadoSeccion(titulo: "Tus eventos", detalle: "\(eventosFiltrados.count)")
                        .filaVaquita()
                    ForEach(eventosFiltrados) { evento in
                        EventoRow(evento: evento, abrir: {
                            busquedaEnfocada = false
                            ruta.append(evento)
                        }) {
                            busquedaEnfocada = false
                            hojaEvento = .editar(evento)
                        } onDelete: {
                            busquedaEnfocada = false
                            eventoAEliminar = evento
                        }
                        .filaVaquita()
                    }
                    if eventosFiltrados.isEmpty {
                        ContentUnavailableView.search(text: busqueda).filaVaquita()
                    }
                    Text("Los buenos momentos se comparten.")
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(EstiloVaquita.secundario)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .filaVaquita()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
            .background(EstiloVaquita.fondo)
            .navigationTitle("Eventos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 7) {
                        Image("Mascota").resizable().scaledToFit().frame(width: 32, height: 32)
                        Text("vaquita").font(.system(.title2, design: .rounded, weight: .heavy))
                            .tracking(-0.8)
                    }
                    .foregroundStyle(EstiloVaquita.tinta)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Vaquita, eventos")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        busquedaEnfocada = false
                        mostrandoInformacion = true
                    } label: {
                        Label("Ayuda y privacidad", systemImage: "info.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PieDeAccion {
                    Button {
                        busquedaEnfocada = false
                        hojaEvento = .nuevo
                    } label: {
                        EtiquetaAccion(titulo: "Nuevo evento", compacto: "Crear", simbolo: "plus")
                    }
                    .buttonStyle(BotonPrincipal())
                    .accessibilityLabel("Nuevo evento")
                    .accessibilityIdentifier("Nuevo evento")
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
            .sheet(item: $hojaEvento, onDismiss: {
                if let eventoRecienCreado {
                    ruta.append(eventoRecienCreado)
                    self.eventoRecienCreado = nil
                }
            }) { hoja in
                EditarEventoView(evento: hoja.evento) { eventoRecienCreado = $0 }
                    .id(hoja.id)
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
        .tint(EstiloVaquita.acento)
    }

    private var portada: some View {
        VStack(alignment: .leading, spacing: 16) {
            EtiquetaCapsula(texto: "CUENTAS CLARAS, BUENOS MOMENTOS", invertida: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    textoPortada
                    Spacer(minLength: 8)
                    IlustracionReparto()
                        .scaleEffect(0.78)
                        .frame(width: 124, height: 140)
                }
                textoPortada
            }
            Text("Disfrutá el plan. Las cuentas, con Vaquita.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: 0xD2E0CF))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FondoDestacado())
        .padding(.top, 12)
    }

    private var textoPortada: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compartir\nhace bien.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .tracking(-1.2)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bienvenida: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tu próxima juntada\nempieza acá.")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(EstiloVaquita.tinta)
                Text("Un asado, un viaje o un café. Hacé una vaquita y que nada quede pendiente.")
                    .font(.subheadline)
                    .foregroundStyle(EstiloVaquita.secundario)
            }
            VStack(alignment: .leading, spacing: 18) {
                paso("1", titulo: "Armá el plan", detalle: "Creá un evento para la ocasión.")
                paso("2", titulo: "Sumá a tu gente", detalle: "Anotá cuánto aportó cada persona.")
                paso("3", titulo: "Repartí sin vueltas", detalle: "Mirá quién le paga a quién.")
            }
        }
        .padding(.vertical, 16)
    }

    private func paso(_ numero: String, titulo: String, detalle: String) -> some View {
        HStack(spacing: 14) {
            Text(numero).font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(EstiloVaquita.acento)
                .frame(width: 36, height: 36)
                .background(EstiloVaquita.suave, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(titulo).font(.subheadline.weight(.semibold)).foregroundStyle(EstiloVaquita.tinta)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detalle).font(.footnote).foregroundStyle(EstiloVaquita.secundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private enum HojaEvento: Identifiable {
    case nuevo
    case editar(Evento)

    var evento: Evento? {
        if case .editar(let evento) = self { return evento }
        return nil
    }

    var id: String {
        evento.map { String(describing: $0.persistentModelID) } ?? "nuevo-evento"
    }
}

private struct EventoRow: View {
    let evento: Evento
    let abrir: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var liquidacion: LiquidacionEvento? {
        try? CalculadoraVaquita.liquidar(participantes: evento.participantes)
    }

    private var mensaje: String? {
        guard let liquidacion else { return nil }
        return CalculadoraVaquita.generarMensajeParaCompartir(evento: evento, liquidacion: liquidacion)
    }

    var body: some View {
        Button(action: abrir) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    IconoEvento(nombre: evento.nombre)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(evento.nombre)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(EstiloVaquita.tinta)
                            .multilineTextAlignment(.leading)
                        Text(evento.fechaCreacion, format: .dateTime.day().month(.wide))
                            .font(.caption).foregroundStyle(EstiloVaquita.secundario)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.subheadline.weight(.semibold))
                        .foregroundStyle(EstiloVaquita.acento)
                        .padding(.top, 3)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 0) {
                        personas.fixedSize(horizontal: true, vertical: true)
                        Spacer(minLength: 16)
                        total.fixedSize(horizontal: true, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 14) { personas; total }
                }
            }
            .tarjetaVaquita()
            .contentShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(BotonTarjeta())
        .accessibilityIdentifier("evento-\(evento.nombre)")
        .accessibilityHint("Abrir el reparto de este evento")
        .swipeActions(edge: .leading) {
            Button("Editar", systemImage: "pencil", action: onEdit).tint(EstiloVaquita.acento)
            if let mensaje {
                ShareLink(item: mensaje) { Label("Compartir", systemImage: "square.and.arrow.up") }.tint(.blue)
            }
        }
        .swipeActions(edge: .trailing) {
            Button("Eliminar", systemImage: "trash", role: .destructive, action: onDelete)
                .tint(.red)
        }
        .contextMenu {
            Button("Editar", systemImage: "pencil", action: onEdit)
            if let mensaje { ShareLink(item: mensaje) { Label("Compartir", systemImage: "square.and.arrow.up") } }
            Button("Eliminar", systemImage: "trash", role: .destructive, action: onDelete)
        }
        .accessibilityAction(named: "Editar", onEdit)
        .accessibilityAction(named: "Eliminar", onDelete)
    }

    private var personas: some View {
        HStack(spacing: 8) {
            if !evento.participantes.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(CalculadoraVaquita.ordenar(evento.participantes).prefix(3).enumerated()), id: \.element.persistentModelID) { indice, persona in
                        AvatarPersona(nombre: persona.nombre, indice: indice, dimension: 28)
                    }
                }
            }
            Text(evento.participantes.isEmpty ? "Listo para sumar gente" : "\(evento.participantes.count) \(evento.participantes.count == 1 ? "persona" : "personas")")
                .font(.caption).foregroundStyle(EstiloVaquita.secundario)
        }
    }

    private var total: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if let liquidacion, !evento.participantes.isEmpty {
                Text(Dinero.formato(liquidacion.total, moneda: evento.moneda))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(EstiloVaquita.tinta)
                Text("Total · \(evento.moneda)").font(.caption2).foregroundStyle(EstiloVaquita.secundario)
            } else if liquidacion == nil {
                Label("Revisar importes", systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(EstiloVaquita.aviso)
            }
        }
    }
}

struct EditarEventoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let evento: Evento?
    let onCreated: ((Evento) -> Void)?
    @State private var nombre: String
    @State private var errorGuardado = false
    @FocusState private var nombreEnfocado: Bool

    init(evento: Evento? = nil, onCreated: ((Evento) -> Void)? = nil) {
        self.evento = evento
        self.onCreated = onCreated
        _nombre = State(initialValue: evento?.nombre ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        IconoEvento(nombre: nombre, grande: true)
                        Text(evento == nil ? "¿Cuál es el plan?" : "Un nombre para\nese buen momento.")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .tracking(-1)
                        Text("Dale un nombre. Las cuentas van por nuestra parte.")
                            .font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NOMBRE DEL EVENTO").font(.caption.weight(.bold)).foregroundStyle(EstiloVaquita.secundario)
                        TextField("Ej. Asado del domingo", text: $nombre,
                                  prompt: Text("Ej. Asado del domingo").foregroundStyle(EstiloVaquita.secundario))
                            .font(.title3.weight(.medium))
                            .accessibilityLabel("Nombre del evento")
                            .accessibilityIdentifier("nombreEvento")
                            .textInputAutocapitalization(.sentences)
                            .focused($nombreEnfocado)
                            .submitLabel(.done)
                            .onSubmit { if !nombreLimpio.isEmpty { guardar() } }
                            .padding(.vertical, 8)
                    }
                    .tarjetaVaquita()
                    if evento == nil {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("UN POCO DE INSPIRACIÓN").font(.caption.weight(.bold)).foregroundStyle(EstiloVaquita.secundario)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 12) {
                                sugerencia("Asado", simbolo: "fork.knife")
                                sugerencia("Escapada", simbolo: "sun.max")
                                sugerencia("En casa", simbolo: "house")
                                sugerencia("Cumpleaños", simbolo: "party.popper")
                            }
                        }
                        Label("Cada evento, sus cuentas. Todo bien organizado.", systemImage: "square.stack.3d.up")
                            .font(.footnote).foregroundStyle(EstiloVaquita.secundario)
                    }
                }
                .foregroundStyle(EstiloVaquita.tinta)
                .padding(24)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(EstiloVaquita.fondo)
            .alert("No se pudo guardar", isPresented: $errorGuardado) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                Text("No se guardaron los cambios. Comprobá el espacio disponible y volvé a tocar Guardar.")
            }
            .navigationTitle(evento == nil ? "Nuevo evento" : "Editar evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: guardar).fontWeight(.semibold).disabled(nombreLimpio.isEmpty)
                }
            }
        }
        .tint(EstiloVaquita.acento)
    }

    private func sugerencia(_ texto: String, simbolo: String) -> some View {
        Button { nombre = texto; nombreEnfocado = true } label: {
            Label(texto, systemImage: simbolo)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(EstiloVaquita.suave, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .foregroundStyle(EstiloVaquita.acento)
    }

    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func guardar() {
        guard !nombreLimpio.isEmpty else { return }
        do {
            var eventoCreado: Evento?
            try Persistencia.guardar(en: modelContext) {
                if let evento { evento.nombre = nombreLimpio } else {
                    let nuevoEvento = Evento(nombre: nombreLimpio)
                    modelContext.insert(nuevoEvento)
                    eventoCreado = nuevoEvento
                }
            }
            if let eventoCreado { onCreated?(eventoCreado) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch { errorGuardado = true }
    }
}
