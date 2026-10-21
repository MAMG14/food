# Tareas — Spec 004 UI Alacena Bunker

Estado: aprobado

Implementar por bloques (skill `sdd`): en orden, tests de lógica primero, `flutter test` en verde, marcar y commit `004/Tn: …`; parar solo en puntos de control.

- [x] **T1. Dominio `HomeFilter` + tests.** RF-7–10, RNF-3
  - Hecho cuando: `flutter test test/domain/home_filter_test.dart` cubre contadores, filtrado y `defaultHomeFilter` (vacío, solo caducados, mezcla).

- [x] **T2. Preferencias de onboarding + skip por instalación previa.** RF-5–6
  - Hecho cuando: tests cubren flag por defecto, `markCompleted`, “hay artículos ⇒ completed”, y “archivo SQLite ya existía + 0 artículos ⇒ completed” (instalación limpia sin DB ⇒ no completed).

- [x] **T3. Dependencias y assets.** RNF-4
  - Hecho cuando: `lottie` + `shared_preferences` en `pubspec.yaml`; Lottie registrado; `flutter pub get` ok.

- [x] **T4. Tema Alacena Bunker + display name + splash nativo.** RF-1, RF-3, RF-17
  - Hecho cuando: tema verde alineado a Figma; label Android/iOS “Alacena Bunker”; splash nativo coherente; analyze limpio.

- [ ] **T5. SplashGate con Lottie + fallback.** RF-2
  - Hecho cuando: Lottie ~1,5 s en arranque; tests pueden acortar/saltar; si falla el asset, frame estático y continúa ≤ 2 s.

- [ ] **T6. Onboarding + cableado de arranque.** RF-4–6
  - Hecho cuando: instalación limpia → onboarding → Iniciar → Home; siguientes arranques → Home; upgrade con DB previa (con o sin datos) → sin onboarding.

- [ ] **T7. HomeShell: tabs Home / Añadir.** RF-14
  - Hecho cuando: tab Añadir hace `push` del alta; al guardar o cancelar/pop el tab vuelve a Home; retirados FAB de alta y `SegmentedButton` Activos/Caducados del inventario.

- [ ] **T8. Home: tarjetas, filtro, empty, orden, ajustes + tap recordatorio.** RF-7–13, RF-16
  - Hecho cuando: tarjetas cuentan y filtran; empty i18n; orden 001; icono abre ajustes 003; tap de notificación fija filtro `soon` y tab Home.

- [ ] **T9. Formulario alineado a Figma (campos 001) + ARB de UI nueva.** RF-15, RF-18
  - Hecho cuando: alta/edición con layout Figma + campos restantes; validaciones 001; cadenas nuevas en ARB (marca, onboarding, tarjetas, empty).

- [ ] **T10. Cierre visual + suite.** Criterios de finalización, RNF-5
  - Hecho cuando: `flutter analyze` + `flutter test` en verde; capturas Home/Add/splash vs Figma; punto de control: 1ª instalación vs upgrade y tap → Por caducar; `MEMORY.md` actualizado; spec → `implementada` tras OK del usuario.
