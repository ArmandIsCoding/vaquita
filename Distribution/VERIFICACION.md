# Verificación del 5 de octubre de 2026

## Resultados

- Xcode 27.0, SDK iOS 27.0; deployment target 17.0 e idioma de desarrollo español comprobados en el Info.plist generado.
- Suite completa en iPad Pro 13 pulgadas: **15 pruebas aprobadas, 0 fallos, 0 omitidas** (9 de lógica/persistencia y 6 de interfaz).
- iPhone: recorridos de creación, edición, compartir, reapertura, cancelación y borrado verificados; comprobación adicional de accesibilidad y texto máximo aprobada (2 pruebas).
- Auditoría automática de contraste, áreas de interacción, descripciones, recorte de texto y traits en la liquidación: aprobada en iPhone e iPad.
- Se detectó una advertencia de layout en la barra de teclado de SwiftUI. Se reemplazó por un control dentro del formulario. La comprobación posterior en iPad (importe inválido y texto máximo) terminó con **2 pruebas aprobadas, 0 fallos y 0 advertencias de runtime**.
- Migración real desde ambos esquemas históricos: participantes sin eventos y participantes con eventos. Las dos bases se abrieron dos veces con el modelo nuevo, sin duplicaciones, conservando importes y relaciones.
- Prueba de fallo real de escritura con base de solo lectura: creación, edición y eliminación revierten sus cambios cuando falla el guardado.
- Archive Release para dispositivo iOS: **ARCHIVE SUCCEEDED**, sin firma. Única advertencia de compilación: se omite la extracción de App Intents porque la app no utiliza ese framework.
- Ícono principal: PNG RGB de 1024 × 1024 sin canal alfa. Original conservado en `Logo/AppIcon-original.png`.
- URL pública https://cognitiva.ar/privacy/privacy.html: **HTTP 200**, contenido idéntico al HTML preparado, correo correcto y anclas de privacidad/soporte presentes.
- Seis capturas actuales en `Screenshots`: tres de iPhone (1320 × 2868) y tres de iPad (2064 × 2752).
- `git diff --check`: sin errores de espacios.

## Cobertura de los tests

Los tests de dinero incluyen coma/punto, negativos, separadores ambiguos, desbordamientos, valores no finitos, un centavo, restos al dividir y 80 grupos adicionales que comprueban conservación exacta del dinero y cuotas con diferencia máxima de un centavo.

Persistencia cubre reapertura desde disco, moneda conservada, migración idempotente, eliminación en cascada y rollback. La interfaz cubre formularios, nombres repetidos, edición, cancelación de borrado, limpieza, compartir, reapertura, orientación horizontal, política sin conexión y tamaño máximo de texto.

Las pruebas son reproducibles desde el esquema compartido `Vaquita` y `scripts/test-migration.sh`. Los resultados `.xcresult` y los registros de compilación se conservan localmente y no se publican.

## Pruebas físicas y límites

Se confirmó instalación y apertura mediante TestFlight en iPhone e iPad físicos, con uso general satisfactorio informado en iOS 27.0.1. Una grabación de demostración muestra apertura, creación y edición de un evento y participantes, reparto, compartir, borrado y ayuda.

Estos resultados no confirman todos los casos del siguiente recorrido. Quedan pendientes una ejecución en iOS 17, la evaluación manual completa con VoiceOver y la actualización desde una instalación anterior. El entorno de simulación usado dispone de iOS 27; compilar con target 17 no sustituye ejecutar sobre esa versión.

## Recorrido de validación manual

1. Instalar TestFlight de Apple en ambos dispositivos y aceptar la invitación con la cuenta del tester. Instalar Vaquita **1.0 (1)**. Si ya hay una versión anterior de Vaquita, conservarla para probar la actualización y comprobar primero que sus eventos/aportes sigan presentes.
2. Crear un evento de prueba y agregar Ana con 12000, Bruno con 0 y Carla con el importe vacío. Resultado esperado: total 12000, cuota 4000 por persona y dos pagos a Ana de 4000 (uno de Bruno y otro de Carla).
3. Editar el aporte de Ana a `0,01`. Debe conservarse exactamente un centavo. Probar `12,50` y `12.50`: ambos deben representar doce con cincuenta. Intentar `-500` o `abc`: debe mostrarse un error sin cambiar el aporte guardado.
4. Cerrar la app por completo, volver a abrirla y comprobar eventos, aportes y moneda. Repetir una creación/edición sin conexión. Abrir Ayuda y privacidad y leer la política interna sin conexión.
5. Compartir el resumen, revisar la vista previa y cancelar. Verificar en iPad vertical/horizontal que la hoja y los formularios sean utilizables. El envío a otra persona es opcional y debe decidirlo el titular.
6. Probar modo oscuro y el tamaño de texto accesible más grande; poder llegar a todos los botones y leer los importes sin recortes importantes.
7. Activar VoiceOver desde Ajustes → Accesibilidad → VoiceOver. Recorrer Eventos, crear un evento, agregar/editar un participante, leer total/cuotas/transferencias, compartir y cancelar, abrir privacidad y volver. Deslizar un dedo a derecha/izquierda para mover el foco y dar doble toque para activar. Verificar nombres claros, orden de foco lógico, importes/moneda comprensibles y ausencia de controles inaccesibles. Siri puede desactivar VoiceOver al terminar.
8. Borrar únicamente el evento creado para esta prueba y comprobar que los demás permanecen. Registrar cualquier cierre inesperado, mensaje confuso o control inaccesible con modelo del dispositivo, versión del sistema y pasos para repetirlo.

No marcar estas pruebas como aprobadas hasta recibir resultados reales de cada dispositivo. La instalación en iOS 17 sigue pendiente de un dispositivo adicional con ese sistema.
