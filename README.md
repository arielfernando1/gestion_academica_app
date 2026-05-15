# Agenda Académica

Aplicación Flutter para la gestión de eventos académicos (tareas, exámenes, clases y entregas).

---

## Semana 3 — Sincronización Online y Arquitectura Offline-First

### Arquitectura Offline-First

La aplicación opera sobre **SQLite local** como fuente principal de datos. Todas las lecturas y escrituras del usuario van primero a la base local, garantizando funcionamiento sin conexión a internet.

Cada evento tiene un campo `synced` (0/1) que indica si ya fue enviado al servidor MySQL remoto.

### Sincronización bidireccional (`SyncService`)

Se implementó un servicio de sincronización con dos fases en orden:

1. **Push (local → remoto):** Obtiene todos los eventos con `synced = 0`, los inserta en MySQL y actualiza `remote_id` y `synced = 1` en SQLite.
2. **Pull (remoto → local):** Descarga todos los eventos de MySQL y agrega localmente los que aún no existen (detectados por `remote_id`).

La sincronización devuelve `true` si fue exitosa o `false` si el servidor no es alcanzable, sin interrumpir el uso de la aplicación. Se dispara automáticamente al iniciar la app y puede ejecutarse manualmente desde el `AppBar`.

### Eliminación coordinada

Al eliminar un evento, `SyncService.deleteEvento()` intenta primero borrar el registro en MySQL y luego lo elimina de SQLite. Si el servidor no responde, la eliminación local procede de todas formas.

### Pantalla de estado de conexión (`ConnectionLogScreen`)

Nueva pantalla accesible desde el `AppBar` (ícono `monitor_heart`) con tres secciones:

**Tarjeta de estado de conexión**
- Estado en tiempo real: Conectado / Sin conexión / Verificando…
- Información del servidor: host, puerto y nombre de base de datos.
- Botón "Verificar conexión" que realiza una prueba contra MySQL.

**Estadísticas locales**
- Total de eventos en SQLite.
- Sincronizados (`synced = 1`).
- Pendientes (`synced = 0`).

**Registro de actividad (`ConnectionLogService`)**

Singleton en memoria que almacena hasta 200 entradas con marca de tiempo. Se alimenta automáticamente desde `SyncService`:

| Tipo | Color | Ejemplo |
|---|---|---|
| `info` | Azul | "Iniciando sincronización con MySQL..." |
| `success` | Verde | "Sincronización completada · 2 enviado(s) · 1 recibido(s)" |
| `warning` | Naranja | "No se pudo eliminar en servidor" |
| `error` | Rojo | "Fallo de sincronización" |

### Archivos nuevos o modificados

| Archivo | Cambio |
|---|---|
| `lib/services/connection_log_service.dart` | Nuevo — singleton de registro de actividad |
| `lib/services/sync_service.dart` | Modificado — agrega entradas al log en cada operación |
| `lib/services/remote_database_service.dart` | Modificado — agrega método `testConnection()` |
| `lib/screens/connection_log_screen.dart` | Nuevo — pantalla de estado y registro |
| `lib/screens/home_screen.dart` | Modificado — botón de navegación a la pantalla de conexión |
