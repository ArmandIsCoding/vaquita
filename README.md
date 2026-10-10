# Vaquita

Aplicación nativa para iPhone y iPad que organiza gastos compartidos por evento. Guarda los datos en el dispositivo, calcula las transferencias necesarias y permite compartir un resumen mediante la hoja de compartir de iOS.

## Desarrollo

- SwiftUI y SwiftData, sin dependencias externas.
- Compatibilidad configurada desde iOS/iPadOS 17.0.
- Interfaz en español, inglés y portugués; idioma de desarrollo español.
- Abrir `Vaquita.xcodeproj`, seleccionar el esquema compartido `Vaquita` y un simulador.
- Para firmar en dispositivos, iniciar sesión con Apple Developer en Xcode, copiar `Config/Signing.local.xcconfig.example` a `Config/Signing.local.xcconfig` y completar el Team ID. El archivo local está excluido de Git; los simuladores no lo necesitan.

## Diseño de la interfaz

La interfaz usa una paleta de crema, verde bosque y lima, con variantes semánticas para modo oscuro. `DisenoVaquita.swift` reúne colores, tarjetas, avatares, ilustración vectorial y botones; las pantallas comparten estos componentes y usan tipografía del sistema con Dynamic Type. Las animaciones de pulsación respetan Reducir movimiento.

Los eventos muestran sus totales, moneda y participantes; a partir de cinco eventos aparece la búsqueda. El detalle prioriza el total, el costo por persona y las transferencias, y luego muestra los aportes y balances individuales. La acción principal permanece accesible al pie de la pantalla. Los formularios incluyen sugerencias de planes y personas conocidas, y confirman los guardados con respuesta háptica. Se conservan las acciones de deslizar, los menús contextuales y el resumen para compartir.

## Importes y reparto

Los aportes nuevos se guardan y calculan como unidades monetarias mínimas enteras: dos decimales para ARS, BRL, USD y EUR; cero para CLP o JPY; tres para KWD; cuatro para CLF. La precisión proviene de Foundation. Se acepta coma o punto decimal, el separador decimal y los dígitos de la región, sin separadores de miles. Los signos negativos, formatos ambiguos y decimales de más se rechazan. El máximo individual es menor a mil millones, con la precisión del evento.

Se divide el total en cuotas enteras y se asigna una unidad mínima adicional a las primeras personas de la lista hasta agotar el resto. La lista se ordena por nombre y, ante nombres iguales heredados, por su identificador persistente. Cada participante muestra su cuota exacta. El algoritmo salda todos los balances con un máximo de n−1 transferencias; no promete el mínimo matemático de transferencias.

Cada evento propone la moneda de la región del dispositivo y permite elegir otra al crearlo, con búsqueda por nombre o código ISO. La moneda y la precisión quedan guardadas con el evento. Cambiar de idioma o región no reinterpreta los importes anteriores. No hay conversión de monedas. Los nombres nuevos deben distinguirse dentro del evento; los nombres repetidos heredados se muestran numerados.

## Persistencia y migración

La columna histórica `montoPagado` se conserva para permitir migraciones ligeras de SwiftData. `montoCentavos` se conserva para leer eventos anteriores; `montoUnidades` es la fuente de los cálculos nuevos. Al abrir una base existente, los importes válidos se convierten y los participantes sin evento se agrupan en **Gastos anteriores**. El proceso es idempotente y no elimina datos inválidos: esos importes se señalan para corregirlos.

Los cambios se guardan explícitamente. Ante un fallo se revierte la operación y se informa al usuario. Si no se puede abrir la base, se ofrece reintentar sin borrar ni reemplazar el archivo.

## Pruebas

En Xcode: Product → Test. El esquema incluye `VaquitaTests` y `VaquitaUITests`.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Vaquita.xcodeproj -scheme Vaquita \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  CODE_SIGNING_ALLOWED=NO test

./scripts/test-migration.sh
```

La prueba de migración crea bases con las tres versiones históricas del modelo en procesos separados y las abre con el modelo actual. No utiliza ni modifica la base de la app instalada.

Los tests de interfaz crean eventos de ejemplo en el simulador seleccionado. Usar un simulador de pruebas. Las capturas quedan como adjuntos del resultado de XCTest.

## Publicación y soporte

Ver [Distribution/README.md](Distribution/README.md) para la ficha de tienda y el procedimiento de distribución. `Distribution/privacidad.html` es el HTML público de privacidad y soporte; la misma política se incluye en la app para lectura sin conexión. Después de editar `Vaquita/privacidad.html`, ejecutar `python3 scripts/sync-privacy.py` para sincronizar ambas copias y el texto nativo.

El repositorio incluye código, pruebas, recursos y capturas con datos de ejemplo. Las credenciales, certificados, configuración local de firma, bases de datos, grabaciones, archivos de compilación y correspondencia privada con App Review quedan fuera de Git. Antes de publicar cambios, revisar `git diff --cached` y los archivos nuevos; `.gitignore` no elimina información de commits anteriores.

Contacto: armando.meabe@icloud.com.

Autor: Armando Meabe. Sitio: [helloworld.com.ar](https://helloworld.com.ar). Licencia declarada por el proyecto original: MIT.

## Idiomas y regiones

La interfaz, las etiquetas de accesibilidad, los errores, la ayuda, la privacidad sin conexión y el resumen para compartir están disponibles en español, inglés y portugués. iOS elige el idioma según las preferencias del usuario; también puede seleccionarse para Vaquita desde Ajustes. La región es independiente del idioma y determina el formato de importes y fechas. No se pide acceso a la ubicación.

`Localizable.xcstrings` contiene las traducciones nativas y los plurales. Los nombres introducidos por el usuario no se traducen. Ejecutar `python3 scripts/check-localizations.py` para verificar cobertura y argumentos de formato; `scripts/sync-privacy.py` conserva la política fuente en español y genera las claves localizables de la lectura sin conexión.

Los eventos históricos mantienen sus dos decimales, incluso si la moneda actualmente usa otra precisión: no se redondean ni se convierten gastos existentes. Las columnas anteriores se conservan para la migración y los nuevos aportes se almacenan en `montoUnidades`. `scripts/test-migration.sh` prueba la actualización y reapertura desde los tres esquemas históricos, incluidos eventos CLP y KWD que antes guardaban centavos.
