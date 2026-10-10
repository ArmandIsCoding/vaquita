import SwiftUI

/// The shared visual language. Semantic colors follow the system appearance.
enum EstiloVaquita {
    static let fondo = adaptable(0xF5F4ED, 0x101C18)
    static let superficie = adaptable(0xFFFFFF, 0x1C2B24)
    static let tinta = adaptable(0x203D31, 0xF0F3E9)
    static let secundario = adaptable(0x526358, 0xB0BEB2)
    static let acento = adaptable(0x286047, 0xCEE99E)
    static let suave = adaptable(0xEAF0E3, 0x2A3D2D)
    static let borde = adaptable(0xDFE5D9, 0x3D4F41)
    static let lima = Color(hex: 0xDCF59C)
    static let bosque = Color(hex: 0x173F30)
    static let aviso = adaptable(0x985029, 0xF4BA8F)

    static func adaptable(_ claro: UInt32, _ oscuro: UInt32) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: oscuro) : UIColor(hex: claro) })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }
}

/// Keep the persistent action to one line, even at accessibility text sizes.
/// VoiceOver always receives the full action name.
struct EtiquetaAccion: View {
    let titulo: LocalizedStringKey
    let compacto: LocalizedStringKey
    let simbolo: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Label(titulo, systemImage: simbolo).fixedSize()
            Label(compacto, systemImage: simbolo).fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titulo)
    }
}

struct BotonPrincipal: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .foregroundStyle(EstiloVaquita.bosque)
            .background(habilitado ? EstiloVaquita.lima : EstiloVaquita.suave,
                        in: RoundedRectangle(cornerRadius: 22))
            .opacity(habilitado ? 1 : 0.55)
            .scaleEffect(configuration.isPressed && !reducirMovimiento ? 0.98 : 1)
            .animation(reducirMovimiento ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct BotonTarjeta: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reducirMovimiento ? 0.985 : 1)
            .animation(reducirMovimiento ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PieDeAccion<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: 680)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(EstiloVaquita.fondo)
    }
}

struct EncabezadoSeccion: View {
    let titulo: LocalizedStringKey
    var detalle: String? = nil
    @Environment(\.dynamicTypeSize) private var tamanoTexto

    var body: some View {
        let layout = tamanoTexto.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        layout {
            Text(titulo)
                .font(.title3.weight(.bold))
                .foregroundStyle(EstiloVaquita.tinta)
                .accessibilityAddTraits(.isHeader)
            if !tamanoTexto.isAccessibilitySize { Spacer(minLength: 8) }
            if let detalle {
                Text(detalle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(EstiloVaquita.secundario)
            }
        }
        .textCase(nil)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }
}

struct EtiquetaCapsula: View {
    let texto: String
    var simbolo: String? = nil
    var invertida = false

    var body: some View {
        HStack(spacing: 5) {
            if let simbolo { Image(systemName: simbolo) }
            Text(texto).fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(invertida ? EstiloVaquita.lima : EstiloVaquita.acento)
        .background(invertida ? Color.white.opacity(0.09) : EstiloVaquita.suave, in: Capsule())
    }
}

struct AvatarPersona: View {
    let nombre: String
    var indice = 0
    var dimension: CGFloat = 42

    private var iniciales: String {
        let palabras = nombre.split(separator: " ")
        return palabras.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    private var fondo: Color {
        [Color(hex: 0xE5EDBF), Color(hex: 0xF3D9C7), Color(hex: 0xD9E6F0), Color(hex: 0xE6DDF1)][abs(indice % 4)]
    }

    var body: some View {
        Text(iniciales.isEmpty ? "?" : iniciales)
            .font(.system(size: max(12, dimension * 0.32), weight: .bold, design: .rounded))
            .foregroundStyle(EstiloVaquita.bosque)
            .frame(width: dimension, height: dimension)
            .background(fondo, in: Circle())
            .accessibilityHidden(true)
    }
}

/// A lightweight native illustration; it remains sharp at every display size.
struct IlustracionReparto: View {
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                .frame(width: 132, height: 132)
            Circle().stroke(.white.opacity(0.08), lineWidth: 1)
                .frame(width: 98, height: 98)
            RoundedRectangle(cornerRadius: 22)
                .fill(EstiloVaquita.lima)
                .frame(width: 70, height: 78)
                .rotationEffect(.degrees(-12))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 8)
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(EstiloVaquita.bosque)
                .rotationEffect(.degrees(180))
            Image(systemName: "sparkle")
                .font(.system(size: 20))
                .foregroundStyle(EstiloVaquita.lima)
                .offset(x: 58, y: -46)
            burbuja("person.fill", color: Color(hex: 0xF3D9C7)).offset(x: -55, y: -41)
            burbuja("person.fill", color: Color(hex: 0xD9E6F0)).offset(x: 58, y: 26)
            burbuja("checkmark", color: EstiloVaquita.lima).offset(x: -35, y: 61)
        }
        .frame(width: 164, height: 172)
        .accessibilityHidden(true)
    }

    private func burbuja(_ simbolo: String, color: Color) -> some View {
        Image(systemName: simbolo)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(EstiloVaquita.bosque)
            .frame(width: 36, height: 36)
            .background(color, in: Circle())
            .overlay(Circle().stroke(EstiloVaquita.bosque, lineWidth: 4))
    }
}

struct FondoDestacado: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: 0x234F3B), Color(hex: 0x103C2F)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle().stroke(.white.opacity(0.05), lineWidth: 38).frame(width: 220)
                    Circle().stroke(.white.opacity(0.04), lineWidth: 1).frame(width: 300)
                }
                .offset(x: 115, y: -100)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

struct IconoEvento: View {
    let nombre: String
    var grande = false

    private var simbolo: String {
        let clave = CalculadoraVaquita.claveNombre(nombre)
        if ["asado", "comida", "cena", "almuerzo", "pizza", "bbq", "dinner", "lunch", "churrasco", "jantar", "almoco"].contains(where: clave.contains) { return "fork.knife" }
        if ["viaje", "vacaciones", "escapada", "playa", "trip", "getaway", "beach", "viagem", "ferias", "praia"].contains(where: clave.contains) { return "sun.max" }
        if ["casa", "hogar", "depto", "home", "apartment"].contains(where: clave.contains) { return "house" }
        if ["cumple", "fiesta", "festejo", "birthday", "party", "aniversario", "festa"].contains(where: clave.contains) { return "party.popper" }
        if ["cafe", "merienda", "coffee", "lanche"].contains(where: clave.contains) { return "cup.and.saucer" }
        return "sparkles"
    }

    var body: some View {
        Image(systemName: simbolo)
            .font(.system(size: grande ? 26 : 22, weight: .medium))
            .foregroundStyle(EstiloVaquita.acento)
            .frame(width: grande ? 64 : 50, height: grande ? 64 : 50)
            .background(EstiloVaquita.suave, in: RoundedRectangle(cornerRadius: grande ? 22 : 17))
            .accessibilityHidden(true)
    }
}

extension View {
    func tarjetaVaquita() -> some View {
        padding(20)
            .background(EstiloVaquita.superficie, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(EstiloVaquita.borde.opacity(0.5), lineWidth: 1))
    }

    func filaVaquita() -> some View {
        listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
