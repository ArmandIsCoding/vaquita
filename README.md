# Vaquita

Aplicación nativa para iPhone y iPad que organiza gastos compartidos por evento. Guarda los datos en el dispositivo, calcula las transferencias necesarias y permite compartir un resumen mediante la hoja de compartir de iOS.

## Desarrollo

- SwiftUI y SwiftData, sin dependencias externas.
- Compatibilidad configurada desde iOS/iPadOS 17.0.
- Interfaz y región de desarrollo en español.
- Abrir `Vaquita.xcodeproj`, seleccionar el esquema compartido `Vaquita` y un simulador.
- Para firmar en dispositivos, iniciar sesión con Apple Developer en Xcode, copiar `Config/Signing.local.xcconfig.example` a `Config/Signing.local.xcconfig` y completar el Team ID. El archivo local está excluido de Git; los simuladores no lo necesitan.

## Importes y reparto

Los aportes nuevos se guardan y calculan en centavos enteros. Se acepta coma o punto decimal, hasta dos decimales y sin separadores de miles. Los formatos ambiguos y los importes negativos se rechazan sin transformar el texto. El máximo individual es 999.999.999,99.

Se divide el total en cuotas enteras y se asigna un centavo adicional a las primeras personas de la lista hasta agotar el resto. La lista se ordena por nombre y, ante nombres iguales heredados, por su identificador persistente. Cada participante muestra su cuota exacta. El algoritmo salda todos los balances con un máximo de n−1 transferencias; no promete el mínimo matemático de transferencias.

Cada evento conserva la moneda correspondiente a la región del dispositivo al crearlo. No hay conversión de monedas. Los nombres nuevos deben distinguirse dentro del evento; los nombres repetidos heredados se muestran numerados.

## Persistencia y migración

La columna histórica `montoPagado` se conserva para permitir migraciones ligeras de SwiftData. `montoCentavos` es la fuente de los cálculos nuevos. Al abrir una base existente, los importes válidos se convierten y los participantes sin evento se agrupan en **Gastos anteriores**. El proceso es idempotente y no elimina datos inválidos: esos importes se señalan para corregirlos.

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

La prueba de migración crea bases con las dos versiones históricas del modelo en procesos separados y las abre con el modelo actual. No utiliza ni modifica la base de la app instalada.

Los tests de interfaz crean eventos de ejemplo en el simulador seleccionado. Usar un simulador de pruebas. Las capturas quedan como adjuntos del resultado de XCTest.

## Publicación y soporte

Ver [Distribution/README.md](Distribution/README.md) para la ficha de tienda y el procedimiento de distribución. `Distribution/privacidad.html` es el HTML público de privacidad y soporte; la misma política se incluye en la app para lectura sin conexión. Después de editar `Vaquita/privacidad.html`, ejecutar `python3 scripts/sync-privacy.py` para sincronizar ambas copias y el texto nativo.

El repositorio incluye código, pruebas, recursos y capturas con datos de ejemplo. Las credenciales, certificados, configuración local de firma, bases de datos, grabaciones, archivos de compilación y correspondencia privada con App Review quedan fuera de Git. Antes de publicar cambios, revisar `git diff --cached` y los archivos nuevos; `.gitignore` no elimina información de commits anteriores.

Contacto: armando.meabe@icloud.com.

Autor: Armando Meabe. Sitio: [helloworld.com.ar](https://helloworld.com.ar). Licencia declarada por el proyecto original: MIT.
