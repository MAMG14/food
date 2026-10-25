# Plan 006 — Identificador de aplicación

Cubre RF-1, RF-2, RF-3 y RNF-1, RNF-2.

## Archivos

- `android/app/build.gradle.kts`: `namespace` y `applicationId` = `com.developermarco.alacenabunker`.
- `android/app/src/main/kotlin/com/developermarco/alacenabunker/MainActivity.kt`: mismo paquete; se elimina `com/example/food/MainActivity.kt`. El manifiesto sigue usando `.MainActivity` (relativo al namespace).
- `ios/Runner.xcodeproj/project.pbxproj`: `PRODUCT_BUNDLE_IDENTIFIER` de la app y de RunnerTests.

## Decisiones

- Mismo id en Android e iOS. Alternativa descartada: dejar el bundle de iOS en `com.example.food`.
- Sin migración de datos: el id nuevo es otra app. Alternativa descartada: copiar la base del id viejo (fuera de alcance y frágil).

## Tests

No hay lógica de dominio. Comprobación: no queda `com.example.food` en fuentes de la app y los ids declarados coinciden.
