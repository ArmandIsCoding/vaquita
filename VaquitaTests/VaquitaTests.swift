import XCTest
import SwiftData
@testable import Vaquita

@MainActor
final class VaquitaTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: Evento.self, Participante.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    func testImportesSinReinterpretacion() throws {
        for (texto, esperado): (String, Int64) in [("12.50", 1250), ("12,50", 1250), (" 0,01 ", 1), ("", 0), ("1234,56", 123456), ("999999999.99", Dinero.maximoCentavos)] {
            XCTAssertEqual(try Dinero.centavos(desde: texto), esperado, texto)
        }
        for texto in ["-500", "+500", "1.234,56", "1,234.56", "1,234", "1.234", "1.", "1,", "NaN", "inf", "1e9", "12abc", "1 000", "1000000000", "999999999999999999999999"] {
            XCTAssertThrowsError(try Dinero.centavos(desde: texto), texto)
        }
        XCTAssertEqual(Dinero.textoEditable(1250, locale: Locale(identifier: "es_AR")), "12,50")
        XCTAssertEqual(Dinero.textoEditable(1250, locale: Locale(identifier: "en_US")), "12.50")
        XCTAssertEqual(try Dinero.centavosLegados(12.505), 1251)
        XCTAssertThrowsError(try Dinero.centavosLegados(.infinity))
        XCTAssertThrowsError(try Dinero.centavosLegados(-1))
    }

    func testCentavoYRepartoExacto() throws {
        let store = try container()
        let ctx = store.mainContext
        for aportes: [Int64] in [[2, 0], [1000, 0, 0], [1, 0, 0], [100, 100], [0, 0], [], [Dinero.maximoCentavos, 0]] {
            let evento = Evento(nombre: "Prueba")
            ctx.insert(evento)
            for (i, aporte) in aportes.enumerated() {
                let persona = Participante(nombre: "Persona \(i)", evento: evento)
                persona.asignar(unidades: aporte)
                ctx.insert(persona)
            }
            try ctx.save()
            let liquidacion = try CalculadoraVaquita.liquidar(participantes: evento.participantes)
            try comprobarBalance(liquidacion)
            if aportes == [2, 0] { XCTAssertEqual(liquidacion.transacciones.map(\.unidades), [1]) }
            ctx.delete(evento)
            try ctx.save()
        }
    }

    private func comprobarBalance(_ liquidacion: LiquidacionEvento) throws {
        XCTAssertEqual(liquidacion.cuotas.reduce(0) { $0 + $1.cuota }, liquidacion.total)
        XCTAssertEqual(Set(liquidacion.transacciones.map(\.id)).count, liquidacion.transacciones.count)
        for persona in liquidacion.cuotas {
            let pagos = liquidacion.transacciones.filter { $0.id.de == persona.id }.reduce(Int64(0)) { $0 + $1.unidades }
            let cobros = liquidacion.transacciones.filter { $0.id.a == persona.id }.reduce(Int64(0)) { $0 + $1.unidades }
            XCTAssertEqual(persona.aportado + pagos - cobros, persona.cuota)
        }
        XCTAssertTrue(liquidacion.transacciones.allSatisfy { $0.unidades > 0 })
        let cuotas = liquidacion.cuotas.map(\.cuota)
        if let minimo = cuotas.min(), let maximo = cuotas.max() { XCTAssertLessThanOrEqual(maximo - minimo, 1) }
    }

    func testMuchosRepartosConservanCadaCentavo() throws {
        let store = try container()
        for caso in 0..<80 {
            let personas = (0..<(2 + caso % 11)).map { indice in
                let p = Participante(nombre: "P\(indice)")
                p.asignar(unidades: Int64((caso * 997 + indice * 331) % 100_003))
                store.mainContext.insert(p)
                return p
            }
            try store.mainContext.save()
            let resultado = try CalculadoraVaquita.liquidar(participantes: personas)
            try comprobarBalance(resultado)
            let invertido = try CalculadoraVaquita.liquidar(participantes: personas.reversed())
            XCTAssertEqual(resultado.transacciones.map(\.id), invertido.transacciones.map(\.id))
            XCTAssertEqual(resultado.transacciones.map(\.unidades), invertido.transacciones.map(\.unidades))
            personas.forEach(store.mainContext.delete)
            try store.mainContext.save()
        }
    }

    func testNombresRepetidosNoColisionan() throws {
        let store = try container()
        let personas = [("Ana", 2000), ("Ana", 2000), ("Luis", 0), ("Luis", 0)].map { nombre, centavos in
            let p = Participante(nombre: nombre)
            p.asignar(unidades: Int64(centavos))
            store.mainContext.insert(p)
            return p
        }
        try store.mainContext.save()
        let resultado = try CalculadoraVaquita.liquidar(participantes: personas)
        XCTAssertEqual(Set(resultado.cuotas.map(\.nombre)).count, 4)
        XCTAssertEqual(resultado.transacciones.count, 2)
        try comprobarBalance(resultado)
        XCTAssertEqual(CalculadoraVaquita.claveNombre("  ÁNA  "), "ana")
    }

    func testRecuperacionIdempotenteYBorradoEnCascada() throws {
        let store = try container()
        let ctx = store.mainContext
        ctx.insert(Participante(nombre: "Anterior", montoPagado: 12.50))
        let existente = Evento(nombre: "Actual")
        ctx.insert(existente)
        ctx.insert(Participante(nombre: "Actual", montoPagado: 20, evento: existente))
        try ctx.save()
        try Persistencia.preparar(ctx)
        try Persistencia.preparar(ctx)
        let eventos = try ctx.fetch(FetchDescriptor<Evento>())
        XCTAssertEqual(eventos.count, 2)
        let recuperado = try XCTUnwrap(eventos.first { $0.nombre == String(localized: "Gastos anteriores") })
        XCTAssertEqual(recuperado.participantes.count, 1)
        XCTAssertEqual(recuperado.participantes.first?.montoCentavos, 1250)
        try Persistencia.guardar(en: ctx) { ctx.delete(recuperado) }
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Participante>()).count, 1)
        XCTAssertEqual(existente.participantes.count, 1)
    }

    func testRollbackConservaDatosAnteError() throws {
        enum Fallo: Error { case simulado }
        let store = try container()
        let ctx = store.mainContext
        let evento = Evento(nombre: "Original")
        ctx.insert(evento)
        try ctx.save()
        XCTAssertThrowsError(try Persistencia.guardar(en: ctx) {
            evento.nombre = "Cambio no confirmado"
            throw Fallo.simulado
        })
        XCTAssertEqual(evento.nombre, "Original")
        XCTAssertFalse(ctx.hasChanges)
    }

    func testPersistenciaRealYMonedaEstable() throws {
        let directorio = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directorio, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directorio) }
        let config = ModelConfiguration(url: directorio.appendingPathComponent("prueba.store"))
        do {
            let store = try ModelContainer(for: Evento.self, Participante.self, configurations: config)
            let evento = Evento(nombre: "Persistente")
            evento.codigoMoneda = "ARS"
            store.mainContext.insert(evento)
            let persona = Participante(nombre: "Ana", evento: evento)
            persona.asignar(unidades: 12345)
            store.mainContext.insert(persona)
            try store.mainContext.save()
        }
        let store = try ModelContainer(for: Evento.self, Participante.self, configurations: config)
        let evento = try XCTUnwrap(store.mainContext.fetch(FetchDescriptor<Evento>()).first)
        XCTAssertEqual(evento.moneda, "ARS")
        XCTAssertEqual(evento.participantes.first?.montoCentavos, 12345)
    }

    func testResumenIncluyeCuotasYNuncaMarcaEventoVacioSaldado() throws {
        let evento = Evento(nombre: "Vacío")
        let resumen = CalculadoraVaquita.generarMensajeParaCompartir(evento: evento, liquidacion: try CalculadoraVaquita.liquidar(participantes: []))
        XCTAssertTrue(resumen.contains(String(localized: "Todavía no hay participantes.")))
        XCTAssertFalse(resumen.contains(String(localized: "¡Están todos al día!")))
    }
    func testFalloRealDeGuardadoRevierteCambios() throws {
        let directorio = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directorio, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directorio) }
        let url = directorio.appendingPathComponent("readonly.store")
        do {
            let store = try ModelContainer(for: Evento.self, Participante.self, configurations: ModelConfiguration(url: url))
            store.mainContext.insert(Evento(nombre: "Conservado"))
            try store.mainContext.save()
        }
        let store = try ModelContainer(for: Evento.self, Participante.self, configurations: ModelConfiguration(url: url, allowsSave: false))
        let ctx = store.mainContext
        ctx.autosaveEnabled = false
        let evento = try XCTUnwrap(ctx.fetch(FetchDescriptor<Evento>()).first)
        XCTAssertThrowsError(try Persistencia.guardar(en: ctx) { evento.nombre = "No guardado" })
        XCTAssertEqual(evento.nombre, "Conservado")
        XCTAssertThrowsError(try Persistencia.guardar(en: ctx) { ctx.delete(evento) })
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Evento>()).count, 1)
        XCTAssertThrowsError(try Persistencia.guardar(en: ctx) { ctx.insert(Evento(nombre: "No insertado")) })
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Evento>()).count, 1)
    }

    func testMonedasPorRegionYPrecision() throws {
        for (region, codigo, precision) in [("es_AR", "ARS", 2), ("pt_BR", "BRL", 2), ("pt_PT", "EUR", 2),
                                          ("en_US", "USD", 2), ("en_BR", "BRL", 2), ("pt_US", "USD", 2), ("en_GB", "GBP", 2), ("es_CL", "CLP", 0),
                                          ("ja_JP", "JPY", 0), ("ar_KW", "KWD", 3)] {
            let evento = Evento(nombre: "Regional", locale: Locale(identifier: region))
            XCTAssertEqual(evento.moneda, codigo)
            XCTAssertEqual(evento.decimales, precision)
        }
        let arabe = Locale(identifier: "ar_KW")
        XCTAssertEqual(try Dinero.unidades(desde: "١٢٫٣٤٥", decimales: 3, locale: arabe), 12345)
        XCTAssertThrowsError(try Dinero.unidades(desde: "١٬٢٣٤", decimales: 3, locale: arabe))
        XCTAssertEqual(try Dinero.unidades(desde: Dinero.textoEditable(12345, decimales: 3, locale: arabe),
                                         decimales: 3, locale: arabe), 12345)
        XCTAssertEqual(Moneda.decimales("CLF"), 4)
        XCTAssertEqual(Moneda.predeterminada(locale: Locale(identifier: "en")), "USD")
        XCTAssertEqual(try Dinero.unidades(desde: "123", decimales: 0), 123)
        XCTAssertThrowsError(try Dinero.unidades(desde: "123,45", decimales: 0))
        XCTAssertEqual(try Dinero.unidades(desde: "12,345", decimales: 3), 12345)
        XCTAssertEqual(try Dinero.unidades(desde: "12.3456", decimales: 4), 123456)
        XCTAssertThrowsError(try Dinero.unidades(desde: "1.2345", decimales: 3))
        for decimales in 0...4 {
            let limite = Dinero.maximo(decimales: decimales)
            let texto = Dinero.textoEditable(limite, decimales: decimales, locale: Locale(identifier: "pt_BR"))
            XCTAssertEqual(try Dinero.unidades(desde: texto, decimales: decimales), limite)
            XCTAssertThrowsError(try Dinero.unidades(desde: "1000000000", decimales: decimales))
        }
        XCTAssertEqual(Dinero.formato(12345, moneda: "USD", locale: Locale(identifier: "en_US")), "$123.45")
        XCTAssertEqual(Dinero.formato(123, moneda: "JPY", locale: Locale(identifier: "en_US")), "¥123")
        XCTAssertTrue(Dinero.formato(12345, moneda: "BRL", locale: Locale(identifier: "pt_BR")).contains("123,45"))
        XCTAssertTrue(Dinero.formato(12345, moneda: "KWD", locale: Locale(identifier: "en_US")).contains("12.345"))
    }

    func testRepartoYReaperturaConDistintasUnidades() throws {
        let directorio = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directorio, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directorio) }
        let config = ModelConfiguration(url: directorio.appendingPathComponent("monedas.store"))
        do {
            let store = try ModelContainer(for: Evento.self, Participante.self, configurations: config)
            for codigo in ["CLP", "JPY", "BRL", "USD", "KWD", "CLF"] {
                let evento = Evento(nombre: codigo, moneda: codigo)
                store.mainContext.insert(evento)
                for (nombre, unidades) in [("Ana", Int64(1001)), ("Bruno", 0), ("Carla", 0)] {
                    let persona = Participante(nombre: nombre, evento: evento)
                    persona.asignar(unidades: unidades)
                    store.mainContext.insert(persona)
                }
            }
            try store.mainContext.save()
        }
        let store = try ModelContainer(for: Evento.self, Participante.self, configurations: config)
        try Persistencia.preparar(store.mainContext)
        for evento in try store.mainContext.fetch(FetchDescriptor<Evento>()) {
            XCTAssertEqual(evento.moneda, evento.nombre)
            XCTAssertEqual(evento.decimales, Moneda.decimales(evento.nombre))
            let liquidacion = try CalculadoraVaquita.liquidar(participantes: evento.participantes)
            XCTAssertEqual(liquidacion.total, 1001)
            try comprobarBalance(liquidacion)
            let persona = try XCTUnwrap(evento.participantes.first { $0.nombre == "Ana" })
            let editable = Dinero.textoEditable(try persona.unidadesValidadas(), decimales: evento.decimales)
            XCTAssertEqual(try Dinero.unidades(desde: editable, decimales: evento.decimales), 1001)
        }
    }

    func testMigracionConservaCentavosDeMonedaSinDecimales() throws {
        let store = try container()
        let evento = Evento(nombre: "Anterior", moneda: "CLP")
        evento.decimalesMoneda = nil
        store.mainContext.insert(evento)
        let persona = Participante(nombre: "Ana", montoPagado: 12.34, evento: evento)
        persona.montoCentavos = 1234
        store.mainContext.insert(persona)
        try store.mainContext.save()
        try Persistencia.preparar(store.mainContext)
        try Persistencia.preparar(store.mainContext)
        XCTAssertEqual(evento.moneda, "CLP")
        XCTAssertEqual(evento.decimales, 2)
        XCTAssertEqual(persona.montoUnidades, 1234)
        XCTAssertEqual(persona.montoPagado, 12.34)
        XCTAssertTrue(Dinero.formato(1234, moneda: evento.moneda, decimales: evento.decimales,
                                    locale: Locale(identifier: "es_CL")).contains("12,34"))
    }

    func testTraduccionesIncluidasEnLaApp() throws {
        for (idioma, guardar, privacidad, singular, plural, resumen) in [
            ("es", "Guardar", "Política de privacidad", "1 persona", "2 personas", "Generado por Vaquita 🐮"),
            ("en", "Save", "Privacy policy", "1 person", "2 people", "Made with Vaquita 🐮"),
            ("pt", "Salvar", "Política de privacidade", "1 pessoa", "2 pessoas", "Feito com Vaquita 🐮")
        ] {
            let ruta = try XCTUnwrap(Bundle.main.path(forResource: idioma, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: ruta))
            XCTAssertEqual(bundle.localizedString(forKey: "Guardar", value: nil, table: nil), guardar)
            XCTAssertEqual(bundle.localizedString(forKey: "Política de privacidad", value: nil, table: nil), privacidad)
            XCTAssertEqual(bundle.localizedString(forKey: "Generado por Vaquita 🐮", value: nil, table: nil), resumen)
            XCTAssertEqual(String(localized: "\(1) personas", bundle: bundle), singular)
            XCTAssertEqual(String(localized: "\(2) personas", bundle: bundle), plural)
        }
    }

}
