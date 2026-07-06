from typing import Any


class Rol:
    @staticmethod
    def crearTabla(conn: Any) -> None:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS rol (
                id INTEGER PRIMARY KEY,
                nombre VARCHAR(30) NOT NULL UNIQUE
            );  
            """
        )

    @staticmethod
    def agregarDatosPorDefecto(conn: Any) -> None:
        conn.execute(
            """
            INSERT INTO rol (id, nombre) VALUES
                (1, 'Administrador'),
                (2, 'Usuario'),
                (3, 'Unidad de Negocio')
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
                rol
            ORDER BY
                id
            """
        )
        return [dict(row) for row in cursor.fetchall()]