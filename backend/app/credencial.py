import base64
from datetime import date, datetime
from io import BytesIO
from typing import Any
import csv
from pathlib import Path


class Credencial:
    @staticmethod
    def crearTabla(conn: Any) -> None:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS credencial (
                credencial_id INTEGER PRIMARY KEY,
                descripcion   VARCHAR(255),
                categoria_id  INTEGER REFERENCES categoria(id),
                usuario       VARCHAR(255),
                password      VARCHAR(255),
                notas         VARCHAR(2000),
                created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
        )
        # Nota: la FK hacia categoria(id) se declara directamente en la sentencia CREATE TABLE

    @staticmethod
    def _to_text(value: Any) -> str | None:
        if value is None:
            return None
        return str(value).strip() or None

    @staticmethod
    def _to_date(value: Any) -> date | None:
        if value is None or value == "":
            return None
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, date):
            return value
        return None

    @staticmethod
    def _to_int(value: Any) -> int | None:
        if value is None or value == "":
            return None
        if isinstance(value, bool):
            return None
        if isinstance(value, int):
            return value
        if isinstance(value, float):
            return int(value)
        text_value = str(value).strip()
        if not text_value:
            return None
        return int(float(text_value))

    @staticmethod
    def _to_bytes(value: Any) -> bytes | None:
        if value is None:
            return None
        if isinstance(value, (bytes, bytearray, memoryview)):
            return bytes(value)
        if isinstance(value, str):
            stripped = value.strip()
            if not stripped:
                return None
            try:
                return base64.b64decode(stripped)
            except Exception:
                return None
        return None

    @staticmethod
    def _bytea_to_base64(value: Any) -> str | None:
        if value is None:
            return None

        if isinstance(value, (bytes, bytearray, memoryview)):
            raw = bytes(value)
            return base64.b64encode(raw).decode("ascii")

        if isinstance(value, str):
            stripped = value.strip()
            if not stripped:
                return None

            # Soporta representaciones hex de PostgreSQL bytea (\xDEADBEEF)
            if stripped.startswith("\\x") and len(stripped) > 2:
                try:
                    raw = bytes.fromhex(stripped[2:])
                    return base64.b64encode(raw).decode("ascii")
                except ValueError:
                    return stripped

            # Si ya viene en base64 desde otro origen, se mantiene como texto.
            return stripped

        if isinstance(value, list) and all(isinstance(item, int) and 0 <= item <= 255 for item in value):
            raw = bytes(value)
            return base64.b64encode(raw).decode("ascii")

        return str(value)

    @staticmethod
    def _row_to_dict(row: Any) -> dict[str, Any]:
        return dict(row)

    # importar removed

    @staticmethod
    def importarDesdeCsv(conn: Any, csv_path: str, overwrite: bool = False, wipe: bool = False) -> dict[str, int]:
        """
        Importa credenciales desde un archivo CSV.

        csv_path: ruta al archivo CSV. Se esperan columnas (al menos):
          - descripcion
          - categoria (nombre de la categoria)
          - usuario
          - password
          - notas
          - credencial_id (opcional)

        Comportamiento:
          - Si `wipe` es True, elimina todas las credenciales antes de empezar.
          - Para cada fila, se asegura de que exista la categoria por nombre (creandola si es necesario).
          - Busca una credencial existente por `descripcion` (coincidencia insensible a mayúsculas/espacios).
            - Si existe y `overwrite` es True -> actualiza con los datos del CSV.
            - Si existe y `overwrite` es False -> la fila se salta (no se modifica).
            - Si no existe -> inserta una nueva credencial con `credencial_id` tomado de la columna o del siguiente codigo.

        Devuelve un dict con contadores: total, inserted, updated, skipped, categories_added.
        """
        path = Path(csv_path)
        if not path.exists():
            raise FileNotFoundError(f"CSV file not found: {csv_path}")

        total = 0
        inserted = 0
        updated = 0
        skipped = 0
        categories_added = 0

        # Opcional: borrar todo antes de importar
        if wipe:
            conn.execute("DELETE FROM credencial")

        # Cache local de categorias por nombre (lower) -> id
        cat_cache: dict[str, int] = {}

        # precargar categorias existentes
        cur = conn.execute("SELECT id, nombre FROM categoria")
        for r in cur.fetchall():
            name = (r["nombre"] or "").strip()
            if name:
                cat_cache[name.lower()] = int(r["id"])

        with path.open(newline="", encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            for raw_row in reader:
                total += 1
                # Normalizar keys a minúsculas
                row = {k.strip().lower(): (v.strip() if isinstance(v, str) else v) for k, v in raw_row.items()}

                descripcion = row.get("descripcion")
                if descripcion is None or str(descripcion).strip() == "":
                    # ignorar filas sin descripcion
                    skipped += 1
                    continue
                descripcion = str(descripcion).strip()

                # Categoria: varias cabeceras posibles
                categoria_nombre = None
                for key in ("categoria", "categoria_nombre", "categoria nombre", "categoria-name"):
                    if key in row and row.get(key):
                        categoria_nombre = row.get(key)
                        break
                if categoria_nombre is not None:
                    categoria_nombre = str(categoria_nombre).strip()

                usuario = row.get("usuario")
                password = row.get("password")
                notas = row.get("notas")

                # resolver categoria_id (crear si no existe)
                categoria_id = None
                if categoria_nombre:
                    key = categoria_nombre.lower()
                    if key in cat_cache:
                        categoria_id = cat_cache[key]
                    else:
                        # crear nueva categoria y recuperar id
                        conn.execute("INSERT INTO categoria (nombre) VALUES (%s)", [categoria_nombre])
                        cur2 = conn.execute("SELECT id FROM categoria WHERE nombre = %s LIMIT 1", [categoria_nombre])
                        row2 = cur2.fetchone()
                        if row2:
                            categoria_id = int(row2["id"])
                            cat_cache[key] = categoria_id
                            categories_added += 1

                # intentar obtener credencial existente por descripcion (coincidencia exacta insensible a mayusculas)
                cur3 = conn.execute(
                    "SELECT credencial_id FROM credencial WHERE lower(trim(coalesce(descripcion,''))) = lower(trim(%s)) LIMIT 1",
                    [descripcion],
                )
                found = cur3.fetchone()

                # si la fila trae credencial_id explícito, usarlo como candidato
                cred_id_field = row.get("credencial_id") or row.get("id")
                cred_id_from_csv = None
                if cred_id_field is not None and str(cred_id_field).strip() != "":
                    try:
                        cred_id_from_csv = int(float(str(cred_id_field)))
                    except Exception:
                        cred_id_from_csv = None

                if found is not None:
                    existing_id = int(found["credencial_id"])
                    if overwrite:
                        Credencial.modificar(
                            conn,
                            credencial_id=existing_id,
                            descripcion=descripcion,
                            categoria_id=categoria_id,
                            usuario=usuario,
                            password=password,
                            notas=notas,
                        )
                        updated += 1
                    else:
                        skipped += 1
                else:
                    # insertar nueva credencial
                    if cred_id_from_csv is not None:
                        new_id = cred_id_from_csv
                    else:
                        new_id = Credencial.proximoCodigo(conn)

                    Credencial.agregar(
                        conn,
                        credencial_id=new_id,
                        descripcion=descripcion,
                        categoria_id=categoria_id,
                        usuario=usuario,
                        password=password,
                        notas=notas,
                    )
                    inserted += 1

        return {
            "total": total,
            "inserted": inserted,
            "updated": updated,
            "skipped": skipped,
            "categories_added": categories_added,
        }

    

    @staticmethod
    def proximoCodigo(conn: Any) -> int:
        cursor = conn.execute("SELECT COALESCE(MAX(credencial_id), 0) + 1 AS proximo FROM credencial")
        row = cursor.fetchone()
        return int(row["proximo"])

    @staticmethod
    def agregar(
        conn: Any,
        credencial_id: int,
        descripcion: str | None,
        categoria_id: int | None,
        usuario: str | None,
        password: str | None,
        notas: str | None,
    ) -> None:
        conn.execute(
            """
            INSERT INTO credencial (
                credencial_id, descripcion, usuario, password, notas
                , categoria_id
            ) VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (credencial_id) DO UPDATE SET
                descripcion = EXCLUDED.descripcion,
                usuario = EXCLUDED.usuario,
                password = EXCLUDED.password,
                notas = EXCLUDED.notas,
                categoria_id = EXCLUDED.categoria_id
            """,
            [
                credencial_id,
                Credencial._to_text(descripcion),
                Credencial._to_text(usuario),
                Credencial._to_text(password),
                Credencial._to_text(notas),
                Credencial._to_int(categoria_id),
            ],
        )

    @staticmethod
    def modificar(
        conn: Any,
        credencial_id: int,
        descripcion: str | None,
        categoria_id: int | None,
        usuario: str | None,
        password: str | None,
        notas: str | None,
    ) -> bool:
        cursor = conn.execute(
            """
            UPDATE credencial SET
                descripcion = %s,
                categoria_id = %s,
                usuario = %s,
                password = %s,
                notas = %s
            WHERE credencial_id = %s
            """,
            [
                Credencial._to_text(descripcion),
                Credencial._to_int(categoria_id),
                Credencial._to_text(usuario),
                Credencial._to_text(password),
                Credencial._to_text(notas),
                Credencial._to_int(credencial_id),
            ],
        )
        return cursor.rowcount > 0


    @staticmethod
    def lista(conn: Any, filtros: dict[str, Any] | None = None) -> list[dict[str, Any]]:
        filtros = filtros or {}
        sql = """
        SELECT
            c.credencial_id   AS credencial_id,
            c.categoria_id    AS categoria_id,
            cat.nombre        AS categoria_nombre,
            c.descripcion     AS descripcion,
            c.usuario         AS usuario,
            c.password        AS password,
            c.notas           AS notas,
            c.created_at      AS created_at
        FROM
            credencial c
        LEFT JOIN categoria cat ON c.categoria_id = cat.id
        """

        where_clauses: list[str] = []
        params: list[Any] = []

        credencial_id = Credencial._to_int(filtros.get("credencial_id"))
        if credencial_id is not None:
            where_clauses.append("c.credencial_id = %s")
            params.append(credencial_id)

        categoria_id = Credencial._to_int(filtros.get("categoria_id"))
        if categoria_id is not None:
            where_clauses.append("c.categoria_id = %s")
            params.append(categoria_id)

        descripcion = Credencial._to_text(filtros.get("descripcion"))
        if descripcion is not None:
            where_clauses.append("c.descripcion ILIKE %s")
            params.append(f"%{descripcion}%")

        usuario = Credencial._to_text(filtros.get("usuario"))
        if usuario is not None:
            where_clauses.append("c.usuario ILIKE %s")
            params.append(f"%{usuario}%")

        if where_clauses:
            sql += " WHERE " + " AND ".join(where_clauses)

        sql += " ORDER BY c.credencial_id"

        cursor = conn.execute(sql, params)
        return [Credencial._row_to_dict(row) for row in cursor.fetchall()]

    @staticmethod
    def consultaPorId(conn: Any, credencial_id: int) -> dict[str, Any] | None:
        cursor = conn.execute(
            """
            SELECT
                c.credencial_id AS credencial_id,
                c.categoria_id  AS categoria_id,
                cat.nombre      AS categoria_nombre,
                c.descripcion   AS descripcion,
                c.usuario       AS usuario,
                c.password      AS password,
                c.notas         AS notas,
                c.created_at    AS created_at
            FROM
                credencial c
            LEFT JOIN categoria cat ON c.categoria_id = cat.id
            WHERE
                c.credencial_id = %s
            """,
            [credencial_id],
        )

        row = cursor.fetchone()
        if row is None:
            return None
        return Credencial._row_to_dict(row)

    # consultaTitularesPorId and consultaBoletos removed

    @staticmethod
    def eliminar(conn: Any, boleto_cod: int) -> bool:
        """
        Elimina un boleto y sus relaciones en una transacción.

        - Primero borra de `boleto_titular` donde `boleto_cod` = parámetro.
        - Luego borra de `boleto` donde `boleto_cod` = parámetro.

        Devuelve True si se eliminó al menos un registro de `boleto`.
        """
        codigo = Credencial._to_int(boleto_cod)
        if codigo is None:
            raise ValueError("credencial_id es invalido")

        deleted_count = 0
        # Ejecutar DELETE dentro de una transacción explícita.
        with conn.transaction():
            cursor2 = conn.execute(
                """
                DELETE FROM credencial WHERE credencial_id = %s
                """,
                [codigo],
            )
            deleted_count = cursor2.rowcount

        return deleted_count > 0


    # alias removed
