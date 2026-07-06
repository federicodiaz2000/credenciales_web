import base64
from datetime import date, datetime
from io import BytesIO
from typing import Any


class Credencial:
    @staticmethod
    def crearTabla(conn: Any) -> None:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS credencial (
                credencial_id INTEGER PRIMARY KEY,
                descripcion   VARCHAR(255),
                usuario       VARCHAR(255),
                password      VARCHAR(255),
                notas         VARCHAR(2000),
                created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
        )

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
    def proximoCodigo(conn: Any) -> int:
        cursor = conn.execute("SELECT COALESCE(MAX(credencial_id), 0) + 1 AS proximo FROM credencial")
        row = cursor.fetchone()
        return int(row["proximo"])

    @staticmethod
    def agregar(
        conn: Any,
        credencial_id: int,
        descripcion: str | None,
        usuario: str | None,
        password: str | None,
        notas: str | None,
    ) -> None:
        conn.execute(
            """
            INSERT INTO credencial (
                credencial_id, descripcion, usuario, password, notas
            ) VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (credencial_id) DO UPDATE SET
                descripcion = EXCLUDED.descripcion,
                usuario = EXCLUDED.usuario,
                password = EXCLUDED.password,
                notas = EXCLUDED.notas
            """,
            [
                credencial_id,
                Credencial._to_text(descripcion),
                Credencial._to_text(usuario),
                Credencial._to_text(password),
                Credencial._to_text(notas),
            ],
        )

    @staticmethod
    def modificar(
        conn: Any,
        credencial_id: int,
        descripcion: str | None,
        usuario: str | None,
        password: str | None,
        notas: str | None,
    ) -> bool:
        cursor = conn.execute(
            """
            UPDATE credencial SET
                descripcion = %s,
                usuario = %s,
                password = %s,
                notas = %s
            WHERE credencial_id = %s
            """,
            [
                Credencial._to_text(descripcion),
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
            c.descripcion     AS descripcion,
            c.usuario         AS usuario,
            c.password        AS password,
            c.notas           AS notas,
            c.created_at      AS created_at
        FROM
            credencial c
        """

        where_clauses: list[str] = []
        params: list[Any] = []

        credencial_id = Credencial._to_int(filtros.get("credencial_id") or filtros.get("boleto_codigo"))
        if credencial_id is not None:
            where_clauses.append("c.credencial_id = %s")
            params.append(credencial_id)

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
                c.descripcion   AS descripcion,
                c.usuario       AS usuario,
                c.password      AS password,
                c.notas         AS notas,
                c.created_at    AS created_at
            FROM
                credencial c
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
