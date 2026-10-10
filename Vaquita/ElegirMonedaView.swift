import SwiftUI

struct ElegirMonedaView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var seleccion: String
    @State private var busqueda = ""

    private var codigos: [String] {
        let consulta = busqueda.trimmingCharacters(in: .whitespacesAndNewlines)
        return Moneda.codigos.filter {
            consulta.isEmpty || $0.localizedStandardContains(consulta) || Moneda.nombre($0).localizedStandardContains(consulta)
        }.sorted { Moneda.nombre($0).localizedStandardCompare(Moneda.nombre($1)) == .orderedAscending }
    }

    var body: some View {
        List {
            ForEach(codigos, id: \.self) { codigo in
                Button {
                    seleccion = codigo
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Moneda.nombre(codigo)).foregroundStyle(EstiloVaquita.tinta)
                            Text(codigo).font(.caption).foregroundStyle(EstiloVaquita.secundario)
                        }
                        Spacer()
                        if codigo == seleccion {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(EstiloVaquita.acento)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityIdentifier("moneda-\(codigo)")
                .accessibilityAddTraits(codigo == seleccion ? .isSelected : [])
                .listRowBackground(EstiloVaquita.superficie)
            }
        }
        .overlay { if codigos.isEmpty { ContentUnavailableView.search(text: busqueda) } }
        .searchable(text: $busqueda, prompt: "Buscar moneda o código")
        .scrollContentBackground(.hidden)
        .background(EstiloVaquita.fondo)
        .navigationTitle("Moneda del evento")
        .navigationBarTitleDisplayMode(.inline)
    }
}
