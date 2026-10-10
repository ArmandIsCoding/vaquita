import SwiftUI

enum ContactoVaquita {
    static let correo = "armando.meabe@icloud.com"
    static let paginaPublica = URL(string: "https://cognitiva.ar/privacy/privacy.html")!
}

struct InformacionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                VStack(spacing: 10) {
                    Image("Mascota")
                        .resizable().scaledToFit().frame(width: 100, height: 100)
                        .accessibilityHidden(true)
                    Text("Entre todos, más fácil.")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(EstiloVaquita.tinta)
                    Text("Un buen plan. Las cuentas claras.")
                        .font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    paso("calendar.badge.plus", titulo: "Creá un evento", texto: "Poné un nombre al plan y agregá a todas las personas, incluso a quienes no aportaron.")
                    paso("person.2", titulo: "Anotá los aportes", texto: "Ingresá cuánto pagó cada persona. Usá nombres o apodos diferentes. Para cambiar un aporte, tocá a la persona.")
                    paso("arrow.triangle.branch", titulo: "Repartí y compartí", texto: "Vaquita te muestra quién le paga a quién. Compartí el resumen para que todos tengan las cuentas claras.")
                } header: { EncabezadoSeccion(titulo: "Así de simple") }
                .listRowBackground(EstiloVaquita.superficie)

                Section {
                    Text("Para editar o eliminar un evento, mantenelo presionado o deslizalo.")
                    Text("Todos los importes del evento usan la misma moneda, elegida según la región del dispositivo al crearlo. Vaquita no convierte monedas ni realiza pagos.")
                    Text("Revisá los nombres y los importes antes de compartir: la app de destino recibirá ese contenido.")
                } header: { EncabezadoSeccion(titulo: "A tu manera") }
                .font(.subheadline)
                .listRowBackground(EstiloVaquita.superficie)

                Section {
                    Label("Tus datos se guardan en tu dispositivo.", systemImage: "lock.shield")
                        .font(.subheadline)
                    NavigationLink { PoliticaView() } label: {
                        Label("Política de privacidad", systemImage: "hand.raised")
                    }
                    Link(destination: ContactoVaquita.paginaPublica) {
                        Label("Ver política en la web", systemImage: "arrow.up.right.square")
                    }
                } header: { EncabezadoSeccion(titulo: "Tu privacidad") }
                .listRowBackground(EstiloVaquita.superficie)

                Section {
                    Link(destination: URL(string: "mailto:\(ContactoVaquita.correo)")!) {
                        Label("Escribinos", systemImage: "envelope")
                    }
                    Text("Para informar un problema, indicá la versión de Vaquita y de iOS, y los pasos para reproducirlo. Evitá enviar nombres o gastos reales.")
                        .font(.footnote).foregroundStyle(EstiloVaquita.secundario)
                } header: { EncabezadoSeccion(titulo: "¿Te damos una mano?") }
                .listRowBackground(EstiloVaquita.superficie)

                VStack(spacing: 6) {
                    Text("vaquita").font(.system(.title3, design: .rounded, weight: .heavy))
                    Text("Versión \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") · Hecha por Armando Meabe")
                        .font(.caption)
                }
                .foregroundStyle(EstiloVaquita.secundario)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .listRowBackground(Color.clear)
            }
            .foregroundStyle(EstiloVaquita.tinta)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .background(EstiloVaquita.fondo)
            .navigationTitle("Ayuda y privacidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } } }
        }
        .tint(EstiloVaquita.acento)
    }

    private func paso(_ icono: String, titulo: String, texto: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icono)
                .font(.title3).foregroundStyle(EstiloVaquita.acento)
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(titulo).font(.headline)
                Text(texto).font(.subheadline).foregroundStyle(EstiloVaquita.secundario)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

private struct PoliticaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(PoliticaPrivacidad.secciones, id: \.titulo) { seccion in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(seccion.titulo).font(.system(.title2, design: .rounded, weight: .bold)).accessibilityAddTraits(.isHeader)
                        Text(seccion.texto).fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(EstiloVaquita.secundario)
                    }
                }
                Link("Contactar por privacidad", destination: URL(string: "mailto:\(ContactoVaquita.correo)")!)
            }
            .foregroundStyle(EstiloVaquita.tinta)
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(EstiloVaquita.fondo)
        .navigationTitle("Privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }
}
