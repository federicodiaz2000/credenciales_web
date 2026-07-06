from typing import Any, Optional


class Usuario:
    @staticmethod
    def crearTabla(conn: Any) -> None:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS usuario (
                id SERIAL PRIMARY KEY,
                nombre VARCHAR(50) NOT NULL UNIQUE,
                email VARCHAR(100) NOT NULL UNIQUE,
                password VARCHAR(30) NULL,
                rol_id INTEGER NOT NULL,
                activo BOOLEAN NOT NULL DEFAULT true,
                FOREIGN KEY (rol_id) REFERENCES rol(id)
            );
            """
        )

        conn.execute(
            """
            CREATE UNIQUE INDEX IF NOT EXISTS usuario_nombre_idx ON usuario (nombre);
            """
        )

        conn.execute(
            """
            CREATE INDEX IF NOT EXISTS usuario_email_idx ON usuario (email);
            """
        )

        conn.execute(
            """
            CREATE INDEX IF NOT EXISTS usuario_rol_id_idx ON usuario (rol_id);
            """
        )

    @staticmethod
    def agregarDatosPorDefecto(conn: Any) -> None:
        conn.execute(
            """
            INSERT INTO usuario (nombre, email, rol_id)
            SELECT
                x.nombre,
                x.email,
                x.rol_id
            FROM
                (
                    SELECT 'admin' as nombre, 'admin@example.com' as email, 1 as rol_id
                    UNION ALL
                    SELECT 'usuario' as nombre, 'usuario@example.com' as email, 2 as rol_id
                ) x
                LEFT JOIN usuario u ON (u.nombre = x.nombre)
            WHERE
                u.nombre IS NULL
            ;
            """
        )

    @staticmethod
    def lista(conn: Any) -> list[dict[str, Any]]:
        cursor = conn.execute(
            """
            SELECT
                id,
                nombre,
                email,
                rol_id,
                activo
            FROM
                usuario
            ORDER BY
                id
            """
        )
        return [dict(row) for row in cursor.fetchall()]

    @staticmethod
    def obtenerCredencialesLogin(conn: Any, usuario: str) -> dict[str, Any] | None:
        cursor = conn.execute(
            """
            SELECT
                id,
                nombre,
                rol_id,
                trim(coalesce(password, '')) <> '' AS tiene_password
            FROM
                usuario
            WHERE
                activo = true
                AND trim(coalesce(nombre, '')) ILIKE trim(%s)
            LIMIT 1
            """,
            [usuario.strip()],
        )

        row = cursor.fetchone()
        if row is None:
            return None

        return dict(row)

    @staticmethod
    def actualizarPasswordLogin(conn: Any, usuarioId: int, password: Optional[str]) -> None:
        conn.execute(
            """
            UPDATE
                usuario
            SET
                password = %s
            WHERE
                id = %s
            """,
            [password, usuarioId],
        )

    @staticmethod
    def obtenerPorId(conn: Any, usuarioId: int) -> dict[str, Any] | None:
        cursor = conn.execute(
            """
            SELECT
                u.id,
                u.nombre,
                u.email,
                u.rol_id,
                u.activo
            FROM
                usuario u
            WHERE
                u.id = %s
            LIMIT 1
            """,
            [usuarioId],
        )

        row = cursor.fetchone()
        if row is None:
            return None

        return dict(row)

    @staticmethod
    def agregar(conn: Any, nombre: str, email: str, rolId: int, activo: bool) -> None:
        conn.execute(
            """
            INSERT INTO usuario (nombre, email, rol_id, activo)
            VALUES (%s, %s, %s, %s)
            """,
            [nombre, email, rolId, activo],
        )

    @staticmethod
    def modificar(conn: Any, usuarioId: int, nombre: str, email: str, rolId: int, activo: bool) -> None:
        conn.execute(
            """
            UPDATE
                usuario
            SET
                nombre = %s,
                email = %s,
                rol_id = %s,
                activo = %s
            WHERE
                id = %s
            """,
            [nombre, email, rolId, activo, usuarioId],
        )

    @staticmethod
    def eliminar(conn: Any, usuarioId: int) -> None:
        with conn.transaction():
            conn.execute(
                """
                DELETE FROM usuario_login
                WHERE usuario_id = %s
                """,
                [usuarioId],
            )
            conn.execute(
                """
                DELETE FROM usuario
                WHERE id = %s
                """,
                [usuarioId],
            )
