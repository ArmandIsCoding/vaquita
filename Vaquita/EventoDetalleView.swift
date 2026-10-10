import SwiftUI
import SwiftData

struct EventoDetalleView: View {
    @Environment(\.modelContext) private var modelContext
    let evento: Evento
    @State private var hojaParticipante: HojaParticipante?
    @State private var mostrandoConfirmacionLimpiar = false
    @State private var errorGuardado = false

    private var participantes: [Participante] { CalculadoraVaquita.ordenar(evento.participantes) }

    var body: some View {
        let liquidacion = try? CalculadoraVaquita.liquidar(participantes: participantes)
        List {
            HStack(alignment: .center, spacing: 16) {
                IconoEvento(nombre: evento.nombre, grande: true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(evento.fechaCreacion, format: .dateTime.day().month(.wide))
                        .font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
                    Text(evento.nombre)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .tracking(-0.6)
                        .foregroundStyle(EstiloVaquita.tinta)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .padding(.vertical, 12)
            .filaVaquita()

            if participantes.isEmpty {
                estadoVacio.filaVaquita()
            } else {
                if let liquidacion {
                    ResumenEventoView(liquidacion: liquidacion, moneda: evento.moneda, decimales: evento.decimales).filaVaquita()
                    EncabezadoSeccion(titulo: "¿Cómo se paga?", detalle: liquidacion.transacciones.isEmpty ? nil : String(localized: "\(liquidacion.transacciones.count) transferencias"))
                        .filaVaquita()
                    if liquidacion.transacciones.isEmpty {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title).foregroundStyle(EstiloVaquita.acento)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("¡Están todos al día!").font(.headline)
                                Text("Los aportes están equilibrados. A disfrutar del plan.")
                                    .font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
                            }
                        }
                        .foregroundStyle(EstiloVaquita.tinta)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tarjetaVaquita()
                        .filaVaquita()
                    } else {
                        ForEach(Array(liquidacion.transacciones.enumerated()), id: \.element.id) { indice, transaccion in
                            TransferenciaRow(transaccion: transaccion, moneda: evento.moneda, decimales: evento.decimales, numero: indice + 1)
                                .filaVaquita()
                        }
                        Text("Con estas transferencias, las cuentas quedan parejas.")
                            .font(.footnote).foregroundStyle(EstiloVaquita.secundario)
                            .filaVaquita()
                    }
                } else {
                    Label("Hay importes que necesitan revisión. Tocá cada participante señalado para corregirlos.", systemImage: "exclamationmark.triangle")
                        .font(.subheadline).foregroundStyle(EstiloVaquita.aviso)
                        .tarjetaVaquita().filaVaquita()
                }

                EncabezadoSeccion(titulo: "La vaquita", detalle: String(localized: "\(participantes.count) personas"))
                    .filaVaquita()
                ForEach(Array(participantes.enumerated()), id: \.element.persistentModelID) { indice, participante in
                    let cuota = liquidacion?.cuotas.first { $0.id == participante.persistentModelID }
                    Button { hojaParticipante = .editar(participante) } label: {
                        ParticipanteRow(participante: participante, cuota: cuota, moneda: evento.moneda, decimales: evento.decimales, indice: indice)
                    }
                    .buttonStyle(BotonTarjeta())
                    .accessibilityIdentifier("participante-\(participante.nombre)")
                    .accessibilityHint("Editar nombre o aporte")
                    .swipeActions(edge: .trailing) {
                        Button("Eliminar", systemImage: "trash", role: .destructive) { eliminar([participante]) }
                            .tint(.red)
                    }
                    .contextMenu {
                        Button("Editar", systemImage: "pencil") { hojaParticipante = .editar(participante) }
                        Button("Eliminar", systemImage: "trash", role: .destructive) { eliminar([participante]) }
                    }
                    .accessibilityAction(named: "Eliminar") { eliminar([participante]) }
                    .filaVaquita()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tocá una persona para editar su aporte.", systemImage: "hand.tap")
                    Text("El resto se distribuye en la unidad mínima del evento y en el orden de la lista. Cada persona tiene su importe exacto indicado arriba.")
                }
                .font(.footnote).foregroundStyle(EstiloVaquita.secundario)
                .padding(.vertical, 10)
                .filaVaquita()
            }
        }
        .listStyle(.plain)
        // An empty event starts at the top even after deleting its last visible row.
        .id(participantes.isEmpty)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 840)
        .frame(maxWidth: .infinity)
        .background(EstiloVaquita.fondo)
        .navigationTitle("El reparto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let liquidacion, !participantes.isEmpty {
                    ShareLink(item: CalculadoraVaquita.generarMensajeParaCompartir(evento: evento, liquidacion: liquidacion)) {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                    }
                }
                if !participantes.isEmpty {
                    Menu {
                        Button("Limpiar participantes", systemImage: "trash", role: .destructive) {
                            mostrandoConfirmacionLimpiar = true
                        }
                    } label: { Label("Más opciones", systemImage: "ellipsis") }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PieDeAccion {
                Button { hojaParticipante = .nuevo } label: {
                    EtiquetaAccion(titulo: "Agregar participante", compacto: "Sumar", simbolo: "person.badge.plus")
                }
                .buttonStyle(BotonPrincipal())
                .accessibilityLabel("Agregar participante")
                .accessibilityIdentifier("Agregar participante")
            }
        }
        .alert("¿Borrar los participantes?", isPresented: $mostrandoConfirmacionLimpiar) {
            Button("Cancelar", role: .cancel) { }
            Button("Limpiar", role: .destructive) { eliminar(participantes) }
        } message: { Text("Se eliminarán todos los participantes de este evento.") }
        .alert("No se pudo eliminar", isPresented: $errorGuardado) {
            Button("Aceptar", role: .cancel) { }
        } message: { Text("Los participantes se conservaron. Comprobá el espacio disponible y volvé a intentar.") }
        .sheet(item: $hojaParticipante) { hoja in
            AgregarParticipanteView(evento: evento, participanteAEditar: hoja.participante)
                .id(hoja.id)
        }
    }

    private var estadoVacio: some View {
        VStack(spacing: 24) {
            IlustracionReparto()
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(FondoDestacado())
            VStack(spacing: 10) {
                Text("El plan está.\nAhora falta tu gente.")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(EstiloVaquita.tinta)
                Text("No hay participantes")
                    .font(.headline).foregroundStyle(EstiloVaquita.secundario)
                Text("Sumá a todas las personas, incluso a quienes no pagaron. Vaquita hace el reparto.")
                    .font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private func eliminar(_ seleccionados: [Participante]) {
        do {
            try Persistencia.guardar(en: modelContext) { seleccionados.forEach(modelContext.delete) }
        } catch { errorGuardado = true }
    }
}

/// One presentation route gives each form a fresh editing identity.
private enum HojaParticipante: Identifiable {
    case nuevo
    case editar(Participante)

    var participante: Participante? {
        if case .editar(let participante) = self { return participante }
        return nil
    }

    var id: String {
        participante.map { String(describing: $0.persistentModelID) } ?? "nuevo-participante"
    }
}

private struct ResumenEventoView: View {
    let liquidacion: LiquidacionEvento
    let moneda: String
    let decimales: Int
    @Environment(\.horizontalSizeClass) private var ancho
    @Environment(\.dynamicTypeSize) private var tamanoTexto

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Total gastado")
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
                    .foregroundStyle(Color(hex: 0xD2E0CF))
                Spacer(minLength: 8)
                EtiquetaCapsula(texto: moneda, invertida: true)
            }
            if ancho == .regular && !tamanoTexto.isAccessibilitySize {
                HStack(alignment: .center, spacing: 28) {
                    total.frame(maxWidth: .infinity, alignment: .leading)
                    Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 60).accessibilityHidden(true)
                    porPersona.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                total
                Rectangle().fill(.white.opacity(0.18)).frame(height: 1).accessibilityHidden(true)
                porPersona
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FondoDestacado())
    }

    private var total: some View {
        Text(Dinero.formato(liquidacion.total, moneda: moneda, decimales: decimales))
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .tracking(-1.4)
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Total gastado, \(Dinero.formato(liquidacion.total, moneda: moneda, decimales: decimales))")
    }

    private var porPersona: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Por persona")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
                .foregroundStyle(Color(hex: 0xD2E0CF))
            Text(liquidacion.reparto(moneda: moneda, decimales: decimales))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(EstiloVaquita.lima)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TransferenciaRow: View {
    let transaccion: Transaccion
    let moneda: String
    let decimales: Int
    let numero: Int

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(EstiloVaquita.acento)
                .frame(width: 40, height: 40)
                .background(EstiloVaquita.suave, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text("\(transaccion.de) paga a \(transaccion.a)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(EstiloVaquita.tinta)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Dinero.formato(transaccion.unidades, moneda: moneda, decimales: decimales))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(EstiloVaquita.acento)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text(String(format: "%02d", numero))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(EstiloVaquita.secundario)
                .accessibilityHidden(true)
        }
        .tarjetaVaquita()
        .accessibilityElement(children: .combine)
    }
}

private struct ParticipanteRow: View {
    let participante: Participante
    let cuota: CuotaParticipante?
    let moneda: String
    let decimales: Int
    let indice: Int
    @Environment(\.dynamicTypeSize) private var tamanoTexto

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                AvatarPersona(nombre: participante.nombre, indice: indice)
                Text(cuota?.nombre ?? participante.nombre)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(EstiloVaquita.tinta)
                Spacer(minLength: 0)
                Image(systemName: "pencil").font(.caption).foregroundStyle(EstiloVaquita.secundario)
                    .accessibilityHidden(true)
            }
            if let importe = try? participante.unidadesValidadas() {
                if tamanoTexto.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 10) { importes(importe) }
                } else {
                    HStack(alignment: .top, spacing: 16) { importes(importe) }
                }
                if let cuota {
                    let balance = cuota.aportado - cuota.cuota
                    Label(balance == 0 ? String(localized: "Su aporte está al día") : balance > 0
                          ? String(localized: "Recibe \(Dinero.formato(balance, moneda: moneda, decimales: decimales))")
                          : String(localized: "Paga \(Dinero.formato(-balance, moneda: moneda, decimales: decimales))"),
                          systemImage: balance == 0 ? "checkmark.circle.fill" : balance > 0 ? "arrow.down.left" : "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(balance < 0 ? EstiloVaquita.aviso : EstiloVaquita.acento)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Label("Revisá este importe", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(EstiloVaquita.aviso)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjetaVaquita()
    }

    @ViewBuilder private func importes(_ importe: Int64) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Aportó").font(.caption).foregroundStyle(EstiloVaquita.secundario)
            Text(Dinero.formato(importe, moneda: moneda, decimales: decimales)).font(.subheadline.weight(.semibold)).foregroundStyle(EstiloVaquita.tinta)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if let cuota {
            VStack(alignment: .leading, spacing: 4) {
                Text("Le corresponde").font(.caption).foregroundStyle(EstiloVaquita.secundario)
                Text(Dinero.formato(cuota.cuota, moneda: moneda, decimales: decimales)).font(.subheadline.weight(.semibold)).foregroundStyle(EstiloVaquita.tinta)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
