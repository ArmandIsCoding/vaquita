# 🐮 Vaquita - Liquidación Inteligente de Gastos (iOS)

**Vaquita** es una aplicación nativa para iOS diseñada para resolver el clásico problema de "quién le debe a quién" después de un asado, un viaje o una salida entre amigos. 

Desarrollada íntegramente en **Swift 6** y **SwiftUI**, utiliza un motor de cálculo basado en teoría de grafos para minimizar la cantidad de transferencias necesarias.

---

## 🧠 El Motor de Cálculo: Optimización de Flujo
A diferencia de otras aplicaciones que generan múltiples deudas cruzadas, **Vaquita** implementa un algoritmo de **Liquidación por Flujo Neto**:

1. **Cálculo de Balance:** Determinamos el gasto individual vs. el promedio del grupo.
2. **Clasificación de Nodos:** Separamos a los participantes en *Deudores* y *Acreedores*.
3. **Resolución Greedy:** El sistema empareja recursivamente al mayor deudor con el mayor acreedor.
4. **Resultado:** Se obtiene el **camino más corto** para saldar las deudas, evitando el "pasamanos" de dinero innecesario.

---

## 🛠️ Stack Tecnológico & Arquitectura
- **UI Framework:** SwiftUI (Declarativa y Reactiva).
- **Persistencia:** **SwiftData** (Core Data moderno) para almacenamiento local y persistencia de sesiones.
- **Formateo:** Localización dinámica de moneda (`Locale.current`) para soporte multi-región.
- **Sharing:** Integración nativa con `ShareLink` para enviar resúmenes por WhatsApp/iMessage.
- **Target:** Optimizado para iOS 17.0+ y procesadores Apple Silicon (M1/M2/M3/M4).

---

## 📱 Vista Previa
*(Aquí podés insertar una captura de pantalla de la app corriendo en tu iPhone 17 Pro más adelante)*

---

## 👨‍💻 Sobre el Autor
**Armando Meabe** Desarrollador de Software con más de 18 años de experiencia en el ecosistema **.NET (C#/C++)**. Este proyecto representa mi incursión en el desarrollo nativo de Apple, aplicando principios de ingeniería de software a las nuevas tecnologías de Swift.

---

## 📝 Licencia
Este proyecto es de código abierto bajo la licencia [MIT](LICENSE). Siéntete libre de usar el código para aprender o mejorar tus propios algoritmos de liquidación.

---
*Generado con ❤️ desde Santa Fe, Argentina.*
