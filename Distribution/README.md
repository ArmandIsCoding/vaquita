# Preparación de App Store

## HTML público

Publicado y verificado el 5 de octubre de 2026 en **https://cognitiva.ar/privacy/privacy.html**: HTTP 200 y contenido idéntico al archivo `privacidad.html` de esta carpeta. El archivo contiene privacidad y soporte, no carga recursos externos y funciona en móvil, escritorio y modo oscuro.

URLs de App Store Connect:

- Política de privacidad: https://cognitiva.ar/privacy/privacy.html#privacidad
- Soporte: https://cognitiva.ar/privacy/privacy.html#soporte

El enlace público ya está configurado dentro de la app. La política interna es accesible desde **Ayuda y privacidad → Política de privacidad** sin conexión; no depende del dominio elegido y no hace falta recompilar la app para alojar el HTML.

Responsable y soporte: Armando Meabe — armando.meabe@icloud.com.

## Ficha propuesta (español)

**Nombre:** Vaquita: gastos compartidos

**Subtítulo:** Repartí gastos entre amigos

**Texto promocional:** Organizá los gastos de tus juntadas y descubrí quién le paga a quién. Guardá tus eventos y compartí un resumen claro con tu grupo.

**Descripción:**

Vaquita te ayuda a repartir los gastos de asados, salidas y viajes.

Creá un evento, agregá a todas las personas e ingresá cuánto aportó cada una. La app calcula la cuota de cada participante y las transferencias necesarias para saldar los gastos.

• Organizá distintas juntadas en eventos independientes.
• Editá nombres y aportes cuando haga falta.
• Repartí los centavos sobrantes con una cuota exacta para cada persona.
• Compartí los aportes y la liquidación con tu grupo.
• Conservá tus eventos en el dispositivo, sin crear una cuenta.
• Usá Vaquita en iPhone o iPad, incluso sin conexión.

Todos los importes de un evento deben corresponder a la misma moneda. Vaquita no convierte monedas ni realiza transferencias bancarias. La función Compartir usa la aplicación que elijas para enviar el resumen.

**Palabras clave:** gastos,amigos,dividir,cuentas,asado,viajes,repartir,grupo,aportes

**Categoría sugerida:** Finanzas (utilidad de reparto de gastos; no es un servicio bancario).

**Copyright:** 2026 Armando Meabe

**Notas para App Review:**

La app no requiere cuenta, credenciales ni conexión a un servidor. Crear un evento con el botón +, agregar participantes y sus aportes. Los participantes sin aportes deben ingresarse con 0 o dejar el importe vacío. Las cuotas y las transferencias se calculan automáticamente. Tocar un participante para editarlo; mantener presionado un evento para editarlo o eliminarlo. Privacidad y soporte están en el botón de información de la pantalla Eventos. La aplicación no realiza pagos: solo calcula importes y comparte texto por la hoja nativa de iOS.

## Declaraciones basadas en el código actual

- Privacidad de la app: sin recopilación de datos por la aplicación ni SDK externos. Los eventos permanecen en el dispositivo; compartir es una acción explícita del usuario. Las consultas de soporte por correo se explican en la política.
- Seguimiento: ninguno; no se usa ATT ni publicidad.
- Cifrado: `ITSAppUsesNonExemptEncryption = NO`; no hay implementación propia de cifrado.
- Edad: cuestionario completado según las funciones reales. No hay anuncios, chat interno, contenido público de usuarios, apuestas, compras ni controles médicos. App Store Connect calculó la clasificación **4+**.
- Accesibilidad: no declarar compatibilidad completa en la ficha sin terminar la evaluación manual de VoiceOver en dispositivo real.

## Distribución

1. Configurar la cuenta de Apple Developer en Xcode y el equipo en `Config/Signing.local.xcconfig`, que queda fuera del repositorio.
2. Archivar para un dispositivo iOS genérico y distribuir desde Organizer a App Store Connect. Cada nueva carga debe tener un número de build superior al último enviado.
3. Completar la ficha, contacto de revisión, clasificación por edad, privacidad, precio y territorios en App Store Connect.
4. Cargar las capturas con datos de ejemplo de `Screenshots` y probar el build mediante TestFlight en iPhone e iPad físicos.
5. Verificar la versión mínima de iOS, VoiceOver, texto grande, persistencia y compartir. La compilación y las auditorías automáticas no sustituyen esas pruebas manuales.
6. Para App Review, proporcionar instrucciones completas y una grabación en dispositivo físico si se solicita. Conservar videos, mensajes, identificadores de revisión y datos de la cuenta en almacenamiento privado.
7. Enviar la versión a revisión. Con publicación manual, liberarla únicamente después de que Apple la apruebe.

## Material público y privado

Este directorio publica la ficha de tienda, la política de privacidad, las capturas de ejemplo y los resultados técnicos de validación. La configuración prevista es gratuita para iPhone y iPad, sin compras dentro de la app ni cuentas de usuario.

La correspondencia y los registros internos de distribución se conservan localmente, en rutas excluidas por `.gitignore`. No adjuntar certificados, perfiles de aprovisionamiento, claves, datos de usuarios, grabaciones personales ni archivos de Xcode a un commit público.

Referencias: [revisión de Apple](https://developer.apple.com/app-store/review/guidelines/), [privacidad](https://developer.apple.com/app-store/app-privacy-details/), [capturas](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

## Ícono

El ícono principal está en `Vaquita/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, en RGB sin alfa a 1024 × 1024. Se conservó el original en `Logo/AppIcon-original.png` y las variantes oscuras existentes. Se usó ImageGen integrado con esta instrucción: conservar la vaca, los billetes y los colores, extender el fondo a las cuatro esquinas y quitar el marco redondeado para obtener un cuadrado opaco. El sistema aplica la máscara final del ícono.

Prompt utilizado con ImageGen integrado:

> Edit the provided Vaquita app icon for App Store compliance. Preserve the illustrated smiling cow, the floating green banknotes, composition, brown outlines, and green-to-cyan background, with no redesign of the mascot. Make the artwork a fully opaque 1024x1024 full-bleed square: extend the existing green/cyan background to all four square corners, remove the baked-in rounded-square frame and thin brown border. No transparent pixels, no new text. Save the opaque square icon as a project-ready PNG.

## Evidencia de validación

Consultar [VERIFICACION.md](VERIFICACION.md) para las pruebas ejecutadas, sus resultados y los límites de la comprobación local. Las capturas listas para cargar están en `Screenshots/iPhone-6.9` y `Screenshots/iPad-13`.
