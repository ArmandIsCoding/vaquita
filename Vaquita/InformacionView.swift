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
                Section("Cómo usar Vaquita") {
                    Text("Creá un evento y agregá a todas las personas, incluso a quienes no aportaron. Ingresá cuánto pagó cada una y Vaquita te muestra las transferencias para repartir el gasto.")
                    Text("Usá nombres o apodos diferentes dentro de cada evento. Para cambiar un aporte, tocá a la persona. Para editar o eliminar un evento, mantenelo presionado o deslizalo.")
                    Text("Todos los importes del evento usan la misma moneda, elegida según la región del dispositivo al crearlo. Vaquita no convierte monedas ni realiza pagos.")
                    Text("Podés compartir un resumen. Revisá los nombres y los importes antes de enviarlo: la app de destino recibirá ese contenido.")
                }
                Section("Privacidad") {
                    NavigationLink("Política de privacidad") { PoliticaView() }
                    Link("Ver política en la web", destination: ContactoVaquita.paginaPublica)
                }
                Section("Soporte") {
                    Link(ContactoVaquita.correo, destination: URL(string: "mailto:\(ContactoVaquita.correo)")!)
                    Text("Para informar un problema, indicá la versión de Vaquita y de iOS, y los pasos para reproducirlo. Evitá enviar nombres o gastos reales.")
                }
                Section("Acerca de") {
                    Text("Vaquita · Versión \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    Text("Desarrollada por Armando Meabe")
                }
            }
            .navigationTitle("Ayuda y privacidad")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } } }
        }
    }
}

private struct PoliticaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(PoliticaPrivacidad.secciones, id: \.titulo) { seccion in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(seccion.titulo).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                        Text(seccion.texto).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Link("Contactar por privacidad", destination: URL(string: "mailto:\(ContactoVaquita.correo)")!)
            }
            .padding()
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }
}
