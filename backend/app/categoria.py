from typing import Any


class Categoria:
    @staticmethod
    def crearTabla(conn: Any) -> None:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS categoria (
                id SERIAL PRIMARY KEY,
                nombre VARCHAR(30) NOT NULL UNIQUE
            );
            """
        )

    @staticmethod
    def agregarDatosPorDefecto(conn: Any) -> None:
        conn.execute(
            """
            INSERT INTO categoria (id, nombre) VALUES
                (1, 'General')
            ON CONFLICT (id) DO NOTHING;
            """
        )

    @staticmethod
    def lista(conn: Any) -> list[dict[str, Any]]:
        cursor = conn.execute(
            """
            SELECT
                id,
                nombre
            FROM
                categoria
            ORDER BY
                id
            """
        )
        return [dict(row) for row in cursor.fetchall()]

    @staticmethod
    def agregar(conn: Any, nombre: str) -> None:
        conn.execute(
            """
            INSERT INTO categoria (nombre)
            VALUES (%s)
            """,
            [nombre],
        )

    @staticmethod
    def modificar(conn: Any, categoriaId: int, nombre: str) -> None:
        cursor = conn.execute(
            """
            UPDATE
                categoria
            SET
                nombre = %s
            WHERE
                id = %s
            """,
            [nombre, categoriaId],
        )
        return cursor.rowcount if hasattr(cursor, 'rowcount') else None

    @staticmethod
    def eliminar(conn: Any, categoriaId: int) -> None:
        conn.execute(
            """
            DELETE FROM categoria
            WHERE id = %s
            """,
            [categoriaId],
        )
