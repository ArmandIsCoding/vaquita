import SwiftUI
import SwiftData

@main
struct VaquitaApp: App {
    @State private var container: ModelContainer?
    @State private var errorDeInicio = false

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    ContentView().modelContainer(container)
                } else if errorDeInicio {
                    ContentUnavailableView {
                        Label("No pudimos abrir tus datos", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text("Tus datos no fueron borrados. Comprobá que haya espacio disponible y volvé a intentar.")
                    } actions: {
                        Button("Reintentar", action: abrir)
                    }
                } else {
                    ProgressView("Abriendo Vaquita…")
                }
            }
            .task { if container == nil { abrir() } }
        }
    }

    private func abrir() {
        do {
            let nuevo = try ModelContainer(for: Evento.self, Participante.self)
            try Persistencia.preparar(nuevo.mainContext)
            container = nuevo
            errorDeInicio = false
        } catch {
            errorDeInicio = true
        }
    }
}
