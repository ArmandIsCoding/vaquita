# 🐮 Vaquita: Liquidación Inteligente de Gastos

> **"La complejidad de una deuda no reside en el monto, sino en la ineficiencia de su resolución."**

**Vaquita** es un experimento de ingeniería para iOS diseñado para optimizar el flujo de dinero tras eventos sociales (asados, viajes o salidas). El objetivo es simple: convertir un caos de deudas cruzadas en la mínima cantidad de transacciones posibles.

Este proyecto marca mi transición personal hacia el desarrollo nativo con **Swift 6**, aplicando patrones de arquitectura que he perfeccionado durante años en .NET a la plataforma de Apple.

---

### 🧠 Ingeniería del Algoritmo: Teoría de Grafos
A diferencia de las soluciones lineales, Vaquita trata al grupo como un grafo dirigido donde el objetivo es la simplificación de aristas. Implementé un motor de **Liquidación por Flujo Neto**:

1.  **Cálculo de Balance:** Determinación del gasto individual frente al promedio.
2.  **Clasificación de Nodos:** Segmentación entre *Deudores* y *Acreedores*.
3.  **Resolución Greedy (Codiciosa):** El sistema empareja recursivamente al mayor deudor con el mayor acreedor hasta que el balance de todos los nodos sea cero.
4.  **Optimización de Camino:** El resultado es el **camino más corto** para saldar deudas, eliminando el "pasamanos" innecesario de dinero.

---

### 🛠️ Stack Tecnológico & Arquitectura
* **Lenguaje:** Swift 6 (aprovechando la seguridad de tipos y concurrencia moderna).
* **UI:** **SwiftUI** con un enfoque puramente declarativo.
* **Persistencia:** **SwiftData**, utilizando modelos vinculados para una gestión de memoria eficiente.
* **Hardware:** Optimizado para el ecosistema de Apple (iOS 17+), testeado específicamente en **iPhone 17 Pro**.
* **UX:** Integración nativa con `ShareLink` para la exportación de resultados vía WhatsApp o iMessage.

---

### 🚀 El Camino del Desarrollador (Blog Insight)
Como arquitecto de software con 18 años en el ecosistema Microsoft, migrar a Swift me obligó a repensar la reactividad de la interfaz. Vaquita no es solo una utilidad; es el cuaderno de bitácora de mi aprendizaje sobre cómo Apple maneja la memoria y el ciclo de vida de las aplicaciones.

---

### 📬 Conectemos
Este proyecto es parte de mi ecosistema de experimentación técnica. Podés leer más sobre mis otros desarrollos en:
🌐 **[helloworld.com.ar](https://helloworld.com.ar)**

---

### 📝 Licencia
Distribuido bajo la licencia [MIT](LICENSE). 
*Documentado con rebeldía frente al olvido desde Santa Fe, Argentina.*
