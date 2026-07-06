import secrets
from typing import Any


class UsuarioLogin:
    @staticmethod
    def crearTabla(conn: Any) -> None:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS usuario_login (
                id            VARCHAR(64)              NOT NULL,
                usuario_id    INTEGER                  NOT NULL,
                created       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                login_end     TIMESTAMP WITH TIME ZONE          DEFAULT NULL,
                due_date_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW() + INTERVAL '8 hours',
                PRIMARY KEY (id),
                CONSTRAINT fk_usuario_login_usuario
                    FOREIGN KEY (usuario_id) REFERENCES usuario (id)
            );
            """
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_usuario_login_usuario_id ON usuario_login (usuario_id);"
        )

    @staticmethod
    def agregar(conn: Any, usuario_id: int) -> str:
        login_id = secrets.token_hex(32)
        conn.execute(
            """
            INSERT INTO usuario_login (id, usuario_id)
            VALUES (%s, %s)
            """,
            [login_id, usuario_id],
        )
        return login_id

    @staticmethod
    def cerrar(conn: Any, login_id: str) -> None:
        conn.execute(
            """
            UPDATE usuario_login
            SET login_end = NOW()
            WHERE id = %s
            """,
            [login_id],
        )

    @staticmethod
    def obtenerPorId(conn: Any, login_id: str) -> dict[str, Any] | None:
        cursor = conn.execute(
            """
            SELECT
                id,
                usuario_id,
                created,
                login_end,
                due_date_time
            FROM
                usuario_login
            WHERE
                id = %s
            """,
            [login_id],
        )
        row = cursor.fetchone()
        if row is None:
            return None
        return dict(row)
