# Registro de decisiones — Food

Decisiones tomadas **durante la implementación** (o del proceso) que no estaban en un plan aprobado. Una entrada por decisión; nunca se borran, se marcan como sustituidas.

Formato: contexto → decisión → alternativas descartadas → consecuencias. Si la decisión cambia el QUÉ, primero se actualiza la spec.

---

## D-001 — Registro de avisos entregados (spec 003)

- Fecha: 2026-10-06 · Estado: vigente · Afecta: `specs/003-recordatorios/plan.md`, T2, T3, T6
- **Contexto:** el plan recalcula todos los avisos en cada cambio (`resync`). Un aviso que ya llegó tiene su hora en el pasado, así que el siguiente `resync` lo trataba como “tardío” (RF-11) y lo reprogramaba: el artículo avisaría cada día hasta caducar, y los avisos inmediatos se repetirían en cada apertura de la app.
- **Decisión:** tabla `reminder_log` (por artículo: hora programada + clave de caducidad). Si la hora ya pasó y la caducidad no cambió, el artículo ya avisó y se omite. Editar la caducidad cambia la clave → vuelve a avisar.
- **Descartado:** consultar al sistema qué avisos se entregaron (iOS y Android no lo exponen de forma fiable); programar por artículo con ids propios (frágil con la agrupación por día).
- **Consecuencias:** si el sistema no entregó un aviso (permiso denegado, batería), no se reintenta. Aceptable: el inventario sigue mostrando la urgencia.
- **Lección de proceso:** el fallo pasó spec, plan y aprobación → se añade revisión obligatoria del plan por el subagente `reviewer` (D-003).

## D-002 — Splash implementado fuera de spec (spec 002)

- Fecha: 2026-10-06 · Estado: vigente
- **Contexto:** el splash se implementó por petición directa sin spec, saltándose “la spec manda”. Se documentó a posteriori en spec 002 (RF-10/11, T6).
- **Decisión:** mantenerlo y documentarlo; reforzar la regla con un hook que bloquea editar `lib/` sin una spec aprobada (D-003).

## D-003 — Flujo de agentes v2: git, hooks, revisor y avance por bloques

- Fecha: 2026-10-07 · Estado: vigente · Aprobado por el usuario
- **Contexto:** las reglas eran solo advertencias (D-002), un fallo de diseño pasó la aprobación (D-001), “una tarea y parar” era lento, el estado estaba triplicado y no había control de versiones.
- **Decisión:**
  1. Git local; commit por tarea terminada.
  2. Hooks de Cursor: análisis tras cada edición de Dart, `flutter analyze` + `flutter test` al terminar el turno si hubo cambios, y bloqueo de edición de `lib/` sin spec aprobada.
  3. Subagente `reviewer` (solo lectura) revisa el plan antes de pedir aprobación.
  4. Tests de integración (`integration_test`) para lo que antes era solo prueba manual.
  5. Estado en un solo sitio: `tasks.md` (progreso) y `Estado:` de la spec (ciclo de vida); `MEMORY.md` solo resume.
  6. Implementación por bloques hasta la siguiente verificación manual o decisión del usuario.
  7. Este registro de decisiones.
- **Descartado:** cambiar de metodología (la base SDD funciona); hooks que ejecuten `flutter test` en cada edición (≈30 s por edición).

## D-004 — Ciclo visual para la UI: MCP de Dart y capturas del simulador

- Fecha: 2026-10-08 · Estado: vigente · Aprobado por el usuario
- **Contexto:** la UI se veía genérica (“parece IA”). El agente escribía widgets sin ver el resultado; los tests validan comportamiento, no aspecto.
- **Decisión:** herramienta de proceso, no de producto (no requiere spec):
  1. MCP oficial `dart mcp-server` en `.cursor/mcp.json` (lanzar app, hot reload, inspector de widgets, errores en tiempo de ejecución).
  2. `tool/screenshot.sh` para capturar el simulador iOS o un dispositivo Android en `build/screens/`.
  3. La skill `ui-design` exige mirar capturas reales en cada cambio visible y seguir las referencias del usuario en `docs/design/referencias/`.
- **Descartado por ahora:** golden tests (útiles cuando haya un diseño estable que proteger).
- **Actualización (2026-10-21):** MCP Figma remoto en `.cursor/mcp.json`. Spec 004 implementa UI Alacena Bunker (Lottie splash, onboarding, Home con filtros, tabs). Seed de tema `#2E7D4F`.
- **Consecuencias:** la marca visible y el flujo de arranque pasan a 004; el `applicationId` sigue siendo `com.example.food` hasta otra spec.
