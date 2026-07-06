# PostgreSQL API en Python + Docker

API en FastAPI para consultar y ejecutar comandos SQL sobre una base PostgreSQL.
El contenedor Docker despliega solo la API; la base de datos puede vivir en un servidor externo.

Incluye autenticacion por API key para endpoints SQL usando el header `X-API-Key`.

## Requisitos

- Docker
- Docker Compose

## Levantar el proyecto

```bash
docker compose up --build
```

### Modos de ejecucion (`debug` y `release`)

Por defecto el backend arranca en `release`.

Ejecutar local con Python:

```bash
# Release (sin auto-recarga)
python app/main.py --mode release

# Debug (con auto-recarga y logs debug)
python app/main.py --mode debug
```

Tambien puedes usar variable de entorno:

```bash
APP_MODE=debug python app/main.py
APP_MODE=release python app/main.py
```

Con Docker Compose:

```bash
# Release
APP_MODE=release docker compose up --build

# Debug
APP_MODE=debug docker compose up --build
```

La clave API se define en `docker-compose.yml` con `API_KEY`.

La conexion de la API a PostgreSQL se define mediante `DATABASE_URL` (por ejemplo en `.env`).

Ejemplo de `.env`:

```env
DATABASE_URL=postgresql://usuario:password@host-remoto:5432/mi_base
API_KEY=dev-secret-key
```

La API quedara disponible en:

- `http://localhost:8000`
- Documentacion Swagger: `http://localhost:8000/docs`

## Endpoints

### `GET /health`

Estado de la API y destino de base de datos configurado.

### `POST /query`

Solo permite `SELECT`.

Header requerido:

```text
X-API-Key: dev-secret-key
```

Body:

```json
{
  "sql": "SELECT * FROM users WHERE id = %s",
  "params": [1]
}
```

### `POST /execute`

Permite ejecutar comandos SQL (ej: `CREATE`, `INSERT`, `UPDATE`, `DELETE`).

Header requerido:

```text
X-API-Key: dev-secret-key
```

Body:

```json
{
  "sql": "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)",
  "params": []
}
```

## Ejemplos de uso con curl

Crear tabla:

```bash
curl -X POST http://localhost:8000/execute \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-secret-key" \
  -d '{"sql":"CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)","params":[]}'
```

Insertar registro:

```bash
curl -X POST http://localhost:8000/execute \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-secret-key" \
  -d '{"sql":"INSERT INTO users (name) VALUES (%s)","params":["Ana"]}'
```

Consultar:

```bash
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-secret-key" \
  -d '{"sql":"SELECT * FROM users","params":[]}'
```

## Ejemplo desde Flutter

Agrega la dependencia en `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.2.2
```

Servicio basico para consumir la API:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class PostgresApiClient {
  PostgresApiClient({required this.baseUrl, required this.apiKey});

  final String baseUrl;
  final String apiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      };

  Future<Map<String, dynamic>> execute(String sql, {List<dynamic> params = const []}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/execute'),
      headers: _headers,
      body: jsonEncode({'sql': sql, 'params': params}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Execute error: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> query(String sql, {List<dynamic> params = const []}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/query'),
      headers: _headers,
      body: jsonEncode({'sql': sql, 'params': params}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Query error: ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (payload['rows'] as List<dynamic>?) ?? [];
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
}
```

Uso rapido:

```dart
final api = PostgresApiClient(
  baseUrl: 'http://10.0.2.2:8000', // Android emulator -> host
  apiKey: 'dev-secret-key',
);

await api.execute(
  'CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)',
);

await api.execute('INSERT INTO users (name) VALUES (%s)', params: ['Ana']);

final users = await api.query('SELECT * FROM users');
print(users);
```

Nota: en iOS simulator puedes usar `http://localhost:8000`; en Android emulator usa `http://10.0.2.2:8000`.

## Ejemplos en Postman

### 1. Crear un Environment

En Postman crea un environment con estas variables:

- `base_url` = `http://localhost:8000`
- `api_key` = `dev-secret-key`

Para Android emulator (si pruebas desde app movil), recuerda que el host es `http://10.0.2.2:8000`.

### 2. Request: Health Check

- Method: `GET`
- URL: `{{base_url}}/health`
- Headers: ninguno

Test sugerido en Postman (pestana `Tests`):

```javascript
pm.test('Health responde 200', function () {
  pm.response.to.have.status(200);
});
```

### 3. Request: Crear tabla (`/execute`)

- Method: `POST`
- URL: `{{base_url}}/execute`
- Headers:
  - `Content-Type: application/json`
  - `X-API-Key: {{api_key}}`
- Body (`raw` -> `JSON`):

```json
{
  "sql": "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)",
  "params": []
}
```

Test sugerido:

```javascript
pm.test('Execute responde 200', function () {
  pm.response.to.have.status(200);
});
```

### 4. Request: Insertar registro (`/execute`)

- Method: `POST`
- URL: `{{base_url}}/execute`
- Headers:
  - `Content-Type: application/json`
  - `X-API-Key: {{api_key}}`
- Body (`raw` -> `JSON`):

```json
{
  "sql": "INSERT INTO users (name) VALUES (%s)",
  "params": ["Ana"]
}
```

### 5. Request: Consultar registros (`/query`)

- Method: `POST`
- URL: `{{base_url}}/query`
- Headers:
  - `Content-Type: application/json`
  - `X-API-Key: {{api_key}}`
- Body (`raw` -> `JSON`):

```json
{
  "sql": "SELECT * FROM users",
  "params": []
}
```

Test sugerido:

```javascript
pm.test('Query devuelve filas', function () {
  pm.response.to.have.status(200);
  const json = pm.response.json();
  pm.expect(json).to.have.property('rows');
  pm.expect(json.rows).to.be.an('array');
});
```

### 6. Validar autenticacion

Si omites `X-API-Key` o envias una clave incorrecta en `/query` o `/execute`, la API responde `401 Unauthorized`.

## Troubleshooting

### Error de conexion a base (`connection refused`)

Verifica que `DATABASE_URL` apunte al host, puerto y credenciales correctos del servidor PostgreSQL remoto.

Tambien valida la conectividad de red entre el contenedor de la API y el servidor de base de datos.

### Reiniciar todo limpio

```bash
docker compose down -v
docker compose up --build
```
