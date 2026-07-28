import argparse
import os
from contextlib import contextmanager
from collections.abc import Iterator
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, Query, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import psycopg
from psycopg.rows import dict_row
from pydantic import BaseModel, Field
import uvicorn

BASE_DIR = Path(__file__).resolve().parent.parent

try:
    from app.rol import Rol
except ImportError:  # Compatibilidad al ejecutar como script: python app/main.py
    from rol import Rol

try:
    from app.categoria import Categoria
except ImportError:
    from categoria import Categoria

try:
    from app.usuario import Usuario
except ImportError:  # Compatibilidad al ejecutar como script: python app/main.py
    from usuario import Usuario

try:
    from app.credencial import Credencial
except ImportError:  # Compatibilidad al ejecutar como script: python app/main.py
    from credencial import Credencial

try:
    from app.usuario_login import UsuarioLogin
except ImportError:  # Compatibilidad al ejecutar como script: python app/main.py
    from usuario_login import UsuarioLogin

try:
    from dotenv import load_dotenv
    # Carga .env como base y permite que .env.local lo sobreescriba para desarrollo local.
    load_dotenv(BASE_DIR / ".env")
    load_dotenv(BASE_DIR / ".env.local", override=True)
except ImportError:
    pass

DB_ENGINE = "postgresql"


def resolve_runtime_mode(cli_mode: Optional[str] = None) -> str:
    mode = (cli_mode or os.getenv("APP_MODE", "release")).strip().lower()
    return "debug" if mode == "debug" else "release"

app = FastAPI(
    title="SQL Command API",
    version="2.0.0",
    description="API para consultar y ejecutar comandos SQL sobre PostgreSQL.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class UsuarioLoginRequest(BaseModel):
    usuario: str = Field(..., description="Nombre de usuario")


class UsuarioPasswordLoginRequest(BaseModel):
    usuarioId: int = Field(..., description="ID del usuario")
    password: Optional[str] = Field(default=None, description="Password ya encriptado o null")


class CredencialAgregarRequest(BaseModel):
    credencial_id: int = Field(..., description="ID de la credencial (clave primaria)")
    descripcion: Optional[str] = Field(default=None, description="Descripción de la credencial")
    usuario: Optional[str] = Field(default=None, description="Usuario asociado a la credencial")
    password: Optional[str] = Field(default=None, description="Password de la credencial")
    notas: Optional[str] = Field(default=None, description="Notas adicionales")
    categoriaId: Optional[int] = Field(default=None, description="ID de la categoría")


class CredencialModificarRequest(BaseModel):
    descripcion: Optional[str] = Field(default=None, description="Descripción de la credencial")
    usuario: Optional[str] = Field(default=None, description="Usuario asociado a la credencial")
    password: Optional[str] = Field(default=None, description="Password de la credencial")
    notas: Optional[str] = Field(default=None, description="Notas adicionales")
    categoriaId: Optional[int] = Field(default=None, description="ID de la categoría")


class UsuarioAgregarRequest(BaseModel):
    nombre: str = Field(..., description="Nombre de usuario")
    email: str = Field(..., description="Email")
    rolId: int = Field(..., description="ID del rol")
    activo: bool = Field(default=True, description="Indica si el usuario esta activo")


class UsuarioModificarRequest(BaseModel):
    nombre: str = Field(..., description="Nombre de usuario")
    email: str = Field(..., description="Email")
    rolId: int = Field(..., description="ID del rol")
    activo: bool = Field(default=True, description="Indica si el usuario esta activo")


class CategoriaAgregarRequest(BaseModel):
    nombre: str = Field(..., description="Nombre de la categoria")


class CategoriaModificarRequest(BaseModel):
    nombre: str = Field(..., description="Nombre de la categoria")


def require_api_key(x_api_key: Optional[str] = Header(default=None, alias="X-API-Key")) -> None:
    api_key = os.getenv("API_KEY", "dev-secret-key")

    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="API_KEY no esta configurada en el servidor",
        )
    if x_api_key != api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key invalida o ausente",
        )


@contextmanager
def get_conn() -> Iterator[Any]:
    database_url = os.getenv("DATABASE_URL")

    if not database_url:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="DATABASE_URL no esta configurada en el servidor",
        )

    conn = psycopg.connect(database_url, row_factory=dict_row)
    try:
        yield conn
    finally:
        conn.close()


def require_sesion_activa(
    x_login_id: Optional[str] = Header(default=None, alias="X-Login-Id"),
    _: None = Depends(require_api_key),
) -> None:
    if not x_login_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="X-Login-Id es requerido",
        )
    try:
        with get_conn() as conn:
            cursor = conn.execute(
                "SELECT login_end, due_date_time FROM usuario_login WHERE id = %s",
                [x_login_id],
            )
            row = cursor.fetchone()
            if row is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sesión no válida",
                )
            if row["login_end"] is not None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sesión cerrada",
                )
            if row["due_date_time"] <= datetime.now(timezone.utc):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sesión expirada",
                )
    except HTTPException:
        raise
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


def require_rol_admin(
    x_login_id: Optional[str] = Header(default=None, alias="X-Login-Id"),
    _: None = Depends(require_api_key),
) -> None:
    if not x_login_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="X-Login-Id es requerido",
        )
    try:
        with get_conn() as conn:
            cursor = conn.execute(
                """
                SELECT ul.login_end, ul.due_date_time, u.rol_id
                FROM usuario_login ul
                JOIN usuario u ON u.id = ul.usuario_id
                WHERE ul.id = %s
                """,
                [x_login_id],
            )
            row = cursor.fetchone()
            if row is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sesión no válida",
                )
            if row["login_end"] is not None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sesión cerrada",
                )
            if row["due_date_time"] <= datetime.now(timezone.utc):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sesión expirada",
                )
            if row["rol_id"] != 1:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="No tiene permiso de ejecutar la accion seleccionada",
                )
    except HTTPException:
        raise
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


# solamente requieren sesión activa (`require_sesion_activa`).


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "engine": DB_ENGINE, "db_target": "DATABASE_URL"}


@app.post("/crearTablaRol")
def crearTablaRol(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Rol.crearTabla(conn)
            conn.commit()
            return {"message": "Tabla rol creada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/agregarDatosPorDefectoRol")
def agregarDatosPorDefectoRol(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Rol.agregarDatosPorDefecto(conn)
            conn.commit()
            return {"message": "Datos por defecto de rol agregados correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/listaRol")
def listaRol(_: None = Depends(require_sesion_activa)) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            rows = Rol.lista(conn)
            return {"rows": rows, "count": len(rows)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/crearTablaCategoria")
def crearTablaCategoria(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Categoria.crearTabla(conn)
            conn.commit()
            return {"message": "Tabla categoria creada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/agregarDatosPorDefectoCategoria")
def agregarDatosPorDefectoCategoria(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Categoria.agregarDatosPorDefecto(conn)
            conn.commit()
            return {"message": "Datos por defecto de categoria agregados correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/listaCategoria")
def listaCategoria(_: None = Depends(require_sesion_activa)) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            rows = Categoria.lista(conn)
            return {"rows": rows, "count": len(rows)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/crearTablaUsuario")
def crearTablaUsuario(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Usuario.crearTabla(conn)
            conn.commit()
            return {"message": "Tabla usuario creada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/crearTablaCredencial")
def crearTablaCredencial(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Credencial.crearTabla(conn)
            conn.commit()
            return {"message": "Tabla credencial creada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/listaCredencial")
def listaCredencial(
    credencial_id: Optional[int] = Query(default=None, description="ID de la credencial"),
    descripcion: Optional[str] = Query(default=None, description="Texto para buscar en descripcion"),
    usuario: Optional[str] = Query(default=None, description="Texto para buscar en usuario"),
    notas: Optional[str] = Query(default=None, description="Texto para buscar en notas"),
    categoria_id: Optional[int] = Query(default=None, description="ID de la categoría"),
    _: None = Depends(require_sesion_activa),
) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            filtros: dict[str, Any] = {
                "credencial_id": credencial_id,
                "descripcion": descripcion,
                "usuario": usuario,
                "notas": notas,
                "categoria_id": categoria_id,
            }
            rows = Credencial.lista(conn, filtros)
            # `Credencial.lista` ya devuelve filas con claves: credencial_id, descripcion, usuario, password, notas, created_at
            # Serializar tipos no JSON-nativos (por ejemplo datetime) a cadenas.
            for r in rows:
                if "categoria_nombre" not in r:
                    r["categoria_nombre"] = None
                for k, v in list(r.items()):
                    if hasattr(v, "isoformat"):
                        r[k] = v.isoformat()
            return {"rows": rows, "count": len(rows)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/consultaPorIdCredencial")
def consultaPorIdCredencial(
    credencial_id: int,
    _: None = Depends(require_sesion_activa),
) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            row = Credencial.consultaPorId(conn, credencial_id)
            return {"row": row}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/credenciales/proximoCodigo")
def proximoCodigoCredencial(_: None = Depends(require_rol_admin)) -> dict[str, int]:
    try:
        with get_conn() as conn:
            Credencial.crearTabla(conn)
            return {"proximo_codigo": Credencial.proximoCodigo(conn)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc





@app.get("/consultaCredenciales")
def consultaCredenciales(
    _: None = Depends(require_sesion_activa),
    credencial_id: Optional[int] = Query(default=None, description="ID de la credencial"),
    descripcion: Optional[str] = Query(default=None, description="Texto para buscar en descripcion"),
    usuario: Optional[str] = Query(default=None, description="Texto para buscar en usuario"),
    notas: Optional[str] = Query(default=None, description="Texto para buscar en notas"),
    categoria_id: Optional[int] = Query(default=None, description="ID de la categoría"),
) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            filtros: dict[str, Any] = {
                "credencial_id": credencial_id,
                "descripcion": descripcion,
                "usuario": usuario,
                "notas": notas,
                "categoria_id": categoria_id,
            }
            rows = Credencial.lista(conn, filtros)
            for r in rows:
                if "categoria_nombre" not in r:
                    r["categoria_nombre"] = None
                for k, v in list(r.items()):
                    if hasattr(v, "isoformat"):
                        r[k] = v.isoformat()
            return {"rows": rows, "count": len(rows)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc





@app.delete("/credenciales/{credencial_id}")
def eliminarCredencial(credencial_id: int, _: None = Depends(require_rol_admin)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            deleted = Credencial.eliminar(conn, credencial_id)
            if not deleted:
                raise HTTPException(status_code=404, detail=f"No existe credencial con id {credencial_id}")
            return {"message": "Credencial eliminada correctamente", "credencial_id": str(credencial_id)}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=f"Datos invalidos: {exc}") from exc
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/credenciales")
def agregarCredencial(
    request: CredencialAgregarRequest,
    _: None = Depends(require_sesion_activa),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Credencial.crearTabla(conn)
            Credencial.agregar(
                conn,
                credencial_id=request.credencial_id,
                descripcion=request.descripcion,
                categoria_id=request.categoriaId,
                usuario=request.usuario,
                password=request.password,
                notas=request.notas,
            )
            # Sincronizacion de titulares eliminada.
            conn.commit()
            return {"message": "Credencial agregada correctamente", "credencial_id": str(request.credencial_id)}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=f"Datos invalidos: {exc}") from exc
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.patch("/credenciales/{credencial_id}")
def modificarCredencial(
    credencial_id: int,
    request: CredencialModificarRequest,
    _: None = Depends(require_rol_admin),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            updated = Credencial.modificar(
                conn,
                credencial_id=credencial_id,
                descripcion=request.descripcion,
                categoria_id=request.categoriaId,
                usuario=request.usuario,
                password=request.password,
                notas=request.notas,
            )
            if not updated:
                raise HTTPException(status_code=404, detail=f"No existe credencial con id {credencial_id}")
            # Sincronizacion de titulares eliminada.
            conn.commit()
            return {"message": "Credencial modificada correctamente", "credencial_id": str(credencial_id)}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=f"Datos invalidos: {exc}") from exc
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/agregarDatosPorDefectoUsuario")
def agregarDatosPorDefectoUsuario(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Usuario.agregarDatosPorDefecto(conn)
            conn.commit()
            return {"message": "Datos por defecto de usuario agregados correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/usuarios")
def agregarUsuario(
    request: UsuarioAgregarRequest,
    _: None = Depends(require_sesion_activa),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Usuario.agregar(conn, request.nombre, request.email, request.rolId, request.activo)
            conn.commit()
            return {"message": "Usuario agregado correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/categorias")
def agregarCategoria(
    request: CategoriaAgregarRequest,
    _: None = Depends(require_sesion_activa),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Categoria.agregar(conn, request.nombre)
            conn.commit()
            return {"message": "Categoria agregada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.patch("/categorias/{categoriaId}")
def modificarCategoria(
    categoriaId: int,
    request: CategoriaModificarRequest,
    _: None = Depends(require_sesion_activa),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Categoria.modificar(conn, categoriaId, request.nombre)
            conn.commit()
            return {"message": "Categoria modificada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.delete("/categorias/{categoriaId}")
def eliminarCategoria(
    categoriaId: int,
    _: None = Depends(require_sesion_activa),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Categoria.eliminar(conn, categoriaId)
            conn.commit()
            return {"message": "Categoria eliminada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.patch("/usuarios/{usuarioId}")
def modificarUsuario(
    usuarioId: int,
    request: UsuarioModificarRequest,
    _: None = Depends(require_sesion_activa),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Usuario.modificar(conn, usuarioId, request.nombre, request.email, request.rolId, request.activo)
            conn.commit()
            return {"message": "Usuario modificado correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.delete("/usuarios/{usuarioId}")
def eliminarUsuario(
    usuarioId: int,
    _: None = Depends(require_sesion_activa),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Usuario.eliminar(conn, usuarioId)
            conn.commit()
            return {"message": "Usuario eliminado correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/listaUsuario")
def listaUsuario(_: None = Depends(require_sesion_activa)) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            rows = Usuario.lista(conn)
            return {"rows": rows, "count": len(rows)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/obtenerPorIdUsuario")
def obtenerPorIdUsuario(usuarioId: int, _: None = Depends(require_sesion_activa)) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            row = Usuario.obtenerPorId(conn, usuarioId)
            return {"row": row}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/exportarCredenciales")
def exportarCredenciales(_: None = Depends(require_rol_admin)) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            cursor = conn.execute(
                """
                SELECT
                    boleto_cod, renspa, senial_desc, boleto_fv, expe,
                    ofcarga, oftransaccio, titu_desc, titu_dom_dep,
                    esta_desc, esta_dep_cod, esta_dep_desc, cuit, bol_obs,
                    record_source, created_at
                FROM boleto
                ORDER BY boleto_cod
                """
            )
            rows = [dict(row) for row in cursor.fetchall()]
            # Serializar tipos no JSON-nativos
            for r in rows:
                for k, v in r.items():
                    if hasattr(v, "isoformat"):
                        r[k] = v.isoformat()
            return {"rows": rows, "count": len(rows)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.get("/exportarImagenesCredenciales")
def exportarImagenesCredenciales(_: None = Depends(require_rol_admin)) -> dict[str, Any]:
    import base64 as _b64
    try:
        with get_conn() as conn:
            cursor = conn.execute(
                """
                SELECT boleto_cod, ofcarga, oftransaccio, marca_img, senial_img
                FROM boleto
                WHERE marca_img IS NOT NULL OR senial_img IS NOT NULL
                ORDER BY boleto_cod
                """
            )
            rows = []
            for row in cursor.fetchall():
                d: dict[str, Any] = {
                    "boleto_cod": row["boleto_cod"],
                    "ofcarga": row["ofcarga"],
                    "oftransaccio": row["oftransaccio"],
                }
                for col in ("marca_img", "senial_img"):
                    val = row[col]
                    if val is None:
                        d[col] = None
                    elif isinstance(val, (bytes, bytearray, memoryview)):
                        d[col] = _b64.b64encode(bytes(val)).decode("ascii")
                    else:
                        d[col] = str(val)
                rows.append(d)
            return {"rows": rows, "count": len(rows)}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc





@app.post("/obtenerCredencialesLoginUsuario")
def obtenerCredencialesLoginUsuario(
    request: UsuarioLoginRequest,
    _: None = Depends(require_api_key),
) -> dict[str, Any]:
    try:
        with get_conn() as conn:
            row = Usuario.obtenerCredencialesLogin(conn, request.usuario)
            return {"row": row}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


class UsuarioLoginIniciarRequest(BaseModel):
    usuario: str = Field(..., description="Nombre de usuario")
    password: str = Field(..., description="Password encriptado")


@app.post("/crearTablaUsuarioLogin")
def crearTablaUsuarioLogin(_: None = Depends(require_api_key)) -> dict[str, str]:
    try:
        with get_conn() as conn:
            UsuarioLogin.crearTabla(conn)
            conn.commit()
            return {"message": "Tabla usuario_login creada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/usuarioLogin")
def iniciarSesion(
    request: UsuarioLoginIniciarRequest,
    _: None = Depends(require_api_key),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            cursor = conn.execute(
                """
                SELECT id
                FROM usuario
                WHERE activo = true
                  AND trim(coalesce(nombre, '')) ILIKE trim(%s)
                  AND password = %s
                LIMIT 1
                """,
                [request.usuario.strip(), request.password],
            )
            row = cursor.fetchone()
            if row is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Usuario o contraseña incorrectos",
                )
            UsuarioLogin.crearTabla(conn)
            login_id = UsuarioLogin.agregar(conn, row["id"])
            conn.commit()
            return {"id": login_id}
    except HTTPException:
        raise
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.patch("/usuarioLogin/{login_id}/cerrar")
def cerrarSesion(
    login_id: str,
    _: None = Depends(require_api_key),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            UsuarioLogin.cerrar(conn, login_id)
            conn.commit()
            return {"message": "Sesión cerrada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


@app.post("/actualizarPasswordLogin")
def actualizarPasswordLogin(
    request: UsuarioPasswordLoginRequest,
    _: None = Depends(require_api_key),
) -> dict[str, str]:
    try:
        with get_conn() as conn:
            Usuario.actualizarPasswordLogin(conn, request.usuarioId, request.password)
            conn.commit()
            return {"message": "Password de login actualizada correctamente"}
    except psycopg.Error as exc:
        raise HTTPException(status_code=400, detail=f"Database error: {exc}") from exc


frontend_build_dir = Path(os.getenv("FRONTEND_BUILD_DIR", "/app/frontend_web"))
if frontend_build_dir.exists():
    # Se monta al final para no interceptar las rutas API ya definidas.
    app.mount("/", StaticFiles(directory=str(frontend_build_dir), html=True), name="frontend-web")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ejecuta la API en modo debug o release")
    parser.add_argument(
        "--mode",
        choices=["debug", "release"],
        help="Modo de ejecucion: debug habilita auto-recarga",
    )
    args = parser.parse_args()

    app_mode = resolve_runtime_mode(args.mode)
    is_debug = app_mode == "debug"
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))

    app_target: Any = "app.main:app" if is_debug else app

    uvicorn.run(
        app_target,
        host=host,
        port=port,
        reload=is_debug,
        log_level="debug" if is_debug else "info",
    )
