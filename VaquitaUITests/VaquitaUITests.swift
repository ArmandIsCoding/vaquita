import XCTest

@MainActor
final class VaquitaUITests: XCTestCase {
    private var capturarEntrada = false
    private func iniciar(textoGrande: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_AR"]
        if textoGrande {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }

    private func agregar(_ app: XCUIApplication, nombre: String, importe: String) {
        app.buttons["Agregar participante"].tap()
        let nombreCampo = app.textFields["nombreParticipante"]
        XCTAssertTrue(nombreCampo.waitForExistence(timeout: 5))
        nombreCampo.tap(); nombreCampo.typeText(nombre)
        let monto = app.textFields["importe"]
        monto.tap(); monto.typeText(importe)
        XCTAssertEqual(nombreCampo.value as? String, nombre)
        XCTAssertEqual(monto.value as? String, importe)
        if capturarEntrada {
            let captura = XCTAttachment(screenshot: app.screenshot())
            captura.name = "Formulario-texto-grande"; captura.lifetime = .keepAlways; add(captura)
        }
        if app.buttons["ocultarTeclado"].exists { app.buttons["ocultarTeclado"].tap() }
        let guardar = app.buttons["guardarParticipante"]
        XCTAssertTrue(guardar.isEnabled)
        guardar.tap()
    }

    func testFlujoCompletoYCapturas() throws {
        let app = iniciar()
        app.buttons["Nuevo evento"].tap()
        app.textFields["nombreEvento"].tap()
        let nombre = "Asado \(Int(Date().timeIntervalSince1970))"
        app.textFields["nombreEvento"].typeText(nombre)
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.buttons["Agregar participante"].waitForExistence(timeout: 5))
        agregar(app, nombre: "Ana", importe: "1000")
        agregar(app, nombre: "Bruno", importe: "0")
        agregar(app, nombre: "Carla", importe: "0")
        XCTAssertTrue(app.staticTexts["Bruno paga a Ana"].waitForExistence(timeout: 5))
        let captura = XCTAttachment(screenshot: app.screenshot()); captura.name = "Liquidación"; captura.lifetime = .keepAlways; add(captura)
        app.buttons["Compartir"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5) || app.buttons["Copiar"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts[nombre].waitForExistence(timeout: 5))
        app.staticTexts[nombre].tap()
        XCTAssertTrue(app.staticTexts["Bruno paga a Ana"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        let horizontalListo = NSPredicate { _, _ in app.frame.width > app.frame.height }
        expectation(for: horizontalListo, evaluatedWith: app)
        waitForExpectations(timeout: 5)
        Thread.sleep(forTimeInterval: 1)
        let horizontal = XCTAttachment(screenshot: app.screenshot()); horizontal.name = "Horizontal"; horizontal.lifetime = .keepAlways; add(horizontal)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["Más opciones"].waitForExistence(timeout: 5))
        app.buttons["Más opciones"].tap()
        app.buttons["Limpiar participantes"].tap()
        app.alerts.buttons["Cancelar"].tap()
        XCTAssertTrue(app.staticTexts["Ana"].exists)
        app.buttons["Más opciones"].tap()
        app.buttons["Limpiar participantes"].tap()
        app.alerts.buttons["Limpiar"].tap()
        XCTAssertTrue(app.staticTexts["No hay participantes"].waitForExistence(timeout: 5))
    }

    func testImporteInvalidoNoCierraFormulario() throws {
        let app = iniciar()
        app.buttons["Nuevo evento"].tap()
        app.textFields["nombreEvento"].tap(); app.textFields["nombreEvento"].typeText("Validación")
        app.buttons["Guardar"].tap()
        agregar(app, nombre: "Prueba", importe: "1,234")
        XCTAssertTrue(app.alerts["No se pudo guardar"].waitForExistence(timeout: 5))
        app.alerts.buttons["Aceptar"].tap()
        XCTAssertTrue(app.textFields["importe"].exists)
        app.buttons["Cancelar"].tap()
        XCTAssertTrue(app.staticTexts["No hay participantes"].waitForExistence(timeout: 5))
    }

    func testPrivacidadAccesibleSinConexion() throws {
        let app = iniciar()
        app.buttons["Ayuda y privacidad"].tap()
        app.buttons["Política de privacidad"].tap()
        XCTAssertTrue(app.staticTexts["Política de privacidad"].waitForExistence(timeout: 5))
        let captura = XCTAttachment(screenshot: app.screenshot()); captura.name = "Privacidad"; captura.lifetime = .keepAlways; add(captura)
    }
    func testCapturasTiendaYAccesibilidad() throws {
        let app = iniciar()
        app.buttons["Nuevo evento"].tap()
        app.textFields["nombreEvento"].tap()
        app.textFields["nombreEvento"].typeText("Asado del domingo")
        app.buttons["Guardar"].tap()
        agregar(app, nombre: "Ana", importe: "48000")
        agregar(app, nombre: "Bruno", importe: "30000")
        agregar(app, nombre: "Carla", importe: "0")
        XCTAssertTrue(app.staticTexts["Carla paga a Ana"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .textClipped, .trait]) { issue in
            print("Accessibility:", issue.compactDescription, issue.element?.debugDescription ?? "no element")
            return false
        }
        let detalle = XCTAttachment(screenshot: app.screenshot())
        detalle.name = "AppStore-01-Detalle"; detalle.lifetime = .keepAlways; add(detalle)
        app.swipeUp()
        let resumen = XCTAttachment(screenshot: app.screenshot())
        resumen.name = "AppStore-02-Resumen"; resumen.lifetime = .keepAlways; add(resumen)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Eventos"].waitForExistence(timeout: 5))
        let lista = XCTAttachment(screenshot: app.screenshot())
        lista.name = "AppStore-03-Eventos"; lista.lifetime = .keepAlways; add(lista)
    }

    func testEditarYEvitarNombresDuplicados() throws {
        let app = iniciar()
        app.buttons["Nuevo evento"].tap()
        app.textFields["nombreEvento"].tap(); app.textFields["nombreEvento"].typeText("Edición")
        app.buttons["Guardar"].tap()
        agregar(app, nombre: "Ana", importe: "12.50")
        agregar(app, nombre: "Ana", importe: "0")
        XCTAssertTrue(app.alerts["No se pudo guardar"].waitForExistence(timeout: 5))
        app.alerts.buttons["Aceptar"].tap()
        app.buttons["Cancelar"].tap()
        app.staticTexts["Ana"].tap()
        let nombre = app.textFields["nombreParticipante"]
        XCTAssertTrue(nombre.waitForExistence(timeout: 5))
        nombre.tap()
        nombre.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "Ana María")
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.staticTexts["Ana María"].waitForExistence(timeout: 5))
        app.staticTexts["Ana María"].swipeLeft()
        app.buttons["Eliminar"].tap()
        XCTAssertTrue(app.staticTexts["No hay participantes"].waitForExistence(timeout: 5))
    }

    func testTextoGrande() throws {
        capturarEntrada = true
        let app = iniciar(textoGrande: true)
        app.buttons["Nuevo evento"].tap()
        app.textFields["nombreEvento"].tap(); app.textFields["nombreEvento"].typeText("Texto grande")
        app.buttons["Guardar"].tap()
        agregar(app, nombre: "Ana", importe: "100")
        agregar(app, nombre: "Beto", importe: "0")
        for _ in 0..<5 {
            if app.staticTexts["Beto paga a Ana"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Beto paga a Ana"].isHittable)
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion])
        let captura = XCTAttachment(screenshot: app.screenshot())
        captura.name = "Texto-grande"; captura.lifetime = .keepAlways; add(captura)
    }

}
