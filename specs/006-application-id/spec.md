# Spec 006 — Identificador de aplicación

Estado: implementada

## Contexto y objetivo

La marca visible ya es Alacena Bunker (spec 004). El identificador de instalación seguía siendo el temporal `com.example.food` (spec 001, RNF-5). Esta spec lo sustituye por el id definitivo para que Android e iOS traten la app como `com.developermarco.alacenabunker`.

## Usuarios

Los mismos que en spec 001.

## Historias de usuario

- HU-1. Como responsable del producto, quiero que la app instalada use el identificador `com.developermarco.alacenabunker` para dejar de publicar el id de ejemplo.

## Definiciones

- **Identificador de aplicación:** id con el que el sistema operativo distingue esta instalación de cualquier otra. En Android es el application id; en iOS, el bundle id. No es el nombre visible («Alacena Bunker»).

## Requisitos funcionales

- RF-1: EL SISTEMA se instala en Android con el identificador `com.developermarco.alacenabunker`.
- RF-2: EL SISTEMA se instala en iOS con el identificador `com.developermarco.alacenabunker`.
- RF-3: EL SISTEMA mantiene el nombre visible **Alacena Bunker** (spec 004).

## Requisitos no funcionales

- RNF-1: El paquete Kotlin de la actividad principal coincide con el identificador de Android.
- RNF-2: El target de tests de iOS usa `com.developermarco.alacenabunker.RunnerTests`.

## Casos límite

- Una instalación previa con `com.example.food` es otra app para el sistema: su inventario local no aparece en la instalación nueva. No hay migración entre ids.

## Fuera de alcance

- Cambiar el nombre del paquete Dart (`food`) ni el nombre visible.
- Firma de release, cuenta de Play o de App Store.
- Migrar datos desde el id anterior.

## Criterios de finalización

- Android e iOS declaran `com.developermarco.alacenabunker`.
- No queda `com.example.food` en el código de la app.

## Dudas abiertas

Ninguna. El id lo fijó el responsable del proyecto.
