import SwiftUI
import SwiftData

@main
struct VaquitaApp: App {
    // Ya no necesitamos la variable sharedModelContainer acá
    // porque le pasamos el modelo directamente al modificador abajo.

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Esta línea es la que hace toda la magia por vos:
        // Crea el archivo SQL, mapea la clase Participante y prepara el Context.
        .modelContainer(for: Participante.self)
    }
}
