#!/usr/bin/env python3
"""
Script para automatizar la importación de tools/Credenciales.csv usando el backend local.

Flujo:
- Carga variables desde tools/.env (API_BASE_URL, API_KEY, USUARIO, PASSWORD, OVERWRITE, WIPE)
- Intenta copiar tools/Credenciales.csv al contenedor Docker "credenciales-api" en /app/credenciales.csv (si existe)
  o, si no hay contenedor, copia al directorio padre del script (suponiendo que es la raíz del repo y el backend lee BASE_DIR/credenciales.csv).
- Realiza POST /usuarioLogin (requiere X-API-Key) para obtener login id.
- Llama POST /importarCredenciales?overwrite=...&wipe=... con encabezados X-API-Key y X-Login-Id.

Requisitos: python3, requests, docker CLI (si el backend corre en contenedor).
Instalar dependencias: pip install -r requirements.txt  (o pip install requests python-dotenv)
"""

from __future__ import annotations
import os
import sys
import subprocess
import shutil
import time
from pathlib import Path
from typing import Optional

try:
    import requests
except Exception:
    print("Por favor instale la dependencia 'requests' (pip install requests)")
    raise

from dotenv import load_dotenv
import hashlib

HERE = Path(__file__).resolve().parent
ENV_PATH = HERE / ".env"
CSV_NAME = "Credenciales.csv"
LOCAL_CSV = HERE / CSV_NAME

if not ENV_PATH.exists():
    print(f"No se encuentra {ENV_PATH}. Cree el archivo con la configuración (ver .env.example).")
    sys.exit(1)

load_dotenv(ENV_PATH)

API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8081")
API_KEY = os.getenv("API_KEY", "dev-secret-key")
USUARIO = os.getenv("USUARIO")
PASSWORD = os.getenv("PASSWORD")
OVERWRITE = os.getenv("OVERWRITE", "false").lower() in ("1", "true", "yes")
WIPE = os.getenv("WIPE", "false").lower() in ("1", "true", "yes")


def encriptar_password(password_plain: str) -> str:
    """Encripta la contraseña igual que el frontend: sha256(utf8) y toma los primeros 30 caracteres."""
    digest = hashlib.sha256(password_plain.encode("utf-8")).hexdigest()
    return digest[:30]

if not LOCAL_CSV.exists():
    print(f"Archivo CSV no encontrado: {LOCAL_CSV}")
    sys.exit(1)

# Intentar detectar contenedor Docker que contenga 'credenciales-api' en su nombre
def find_container_name() -> Optional[str]:
    try:
        out = subprocess.check_output(["docker", "ps", "--format", "{{.Names}}"], text=True)
        for line in out.splitlines():
            if "credenciales-api" in line:
                return line.strip()
        return None
    except Exception:
        return None


def copy_to_container(container: str, src: Path, dest_path: str) -> bool:
    try:
        subprocess.check_call(["docker", "cp", str(src), f"{container}:{dest_path}"])
        return True
    except subprocess.CalledProcessError as exc:
        print(f"Error al copiar al contenedor: {exc}")
        return False


def copy_to_backend_root(src: Path) -> bool:
    # Asumimos que la estructura es: repo_root/tools/script.py -> repo_root/credenciales.csv
    repo_root = HERE.parent
    dest = repo_root / "credenciales.csv"
    try:
        shutil.copy2(src, dest)
        return True
    except Exception as exc:
        print(f"Error al copiar al backend root {dest}: {exc}")
        return False


print(f"Usando API: {API_BASE_URL}")
print(f"Overwrite={OVERWRITE}  Wipe={WIPE}")

# 1) copiar CSV al backend (container o fs)
copied = False
container = find_container_name()
if container:
    print(f"Contenedor detectado: {container} -> copiando {LOCAL_CSV} a /app/credenciales.csv")
    copied = copy_to_container(container, LOCAL_CSV, "/app/credenciales.csv")
    if not copied:
        print("Fallo al copiar al contenedor; intentar copiar al filesystem del repo...")
        copied = copy_to_backend_root(LOCAL_CSV)
else:
    print("No se detectó contenedor Docker con 'credenciales-api'; copiando al filesystem del repo...")
    copied = copy_to_backend_root(LOCAL_CSV)

if not copied:
    print("No fue posible colocar el CSV en la ubicación que el backend espera. Abortando.")
    sys.exit(1)

# 2) autenticarse: POST /usuarioLogin (requiere X-API-Key)
if not USUARIO or not PASSWORD:
    print("USUARIO o PASSWORD no definidos en .env")
    sys.exit(1)

login_url = f"{API_BASE_URL.rstrip('/')}/usuarioLogin"
headers = {"X-API-Key": API_KEY}
PASSWORD_HASHED = encriptar_password(PASSWORD) if PASSWORD else None


def try_login() -> Optional[str]:
    print(f"Autenticando usuario {USUARIO} en {login_url}")
    resp = requests.post(login_url, json={"usuario": USUARIO, "password": PASSWORD_HASHED}, headers=headers)
    if resp.status_code == 200:
        login_data = resp.json()
        return login_data.get("id")
    print(f"Error al autenticar: {resp.status_code} {resp.text}")
    return None


# Intentar login inicial
login_id = try_login()

if not login_id:
    # Intentar crear datos por defecto y asignar password usando la API key
    print("Intentando crear usuario por defecto y asignar password via API key...")
    try:
        # 1) crear usuarios por defecto (requiere API key)
        adpd_url = f"{API_BASE_URL.rstrip('/')}/agregarDatosPorDefectoUsuario"
        r1 = requests.post(adpd_url, headers={"X-API-Key": API_KEY})
        if r1.status_code not in (200, 201):
            print(f"Advertencia: agregarDatosPorDefectoUsuario devolvió {r1.status_code} {r1.text}")

        # 2) obtener credenciales de login para el usuario
        obtener_url = f"{API_BASE_URL.rstrip('/')}/obtenerCredencialesLoginUsuario"
        r2 = requests.post(obtener_url, json={"usuario": USUARIO}, headers={"X-API-Key": API_KEY})
        if r2.status_code != 200:
            print(f"No se pudo obtener id de usuario: {r2.status_code} {r2.text}")
        else:
            data = r2.json()
            user_row = data.get("row")
            if user_row and user_row.get("id"):
                usuario_id = user_row["id"]
                # 3) actualizar password
                upd_url = f"{API_BASE_URL.rstrip('/')}/actualizarPasswordLogin"
                # enviar la password encriptada igual que el frontend
                r3 = requests.post(upd_url, json={"usuarioId": usuario_id, "password": PASSWORD_HASHED}, headers={"X-API-Key": API_KEY})
                if r3.status_code not in (200, 201):
                    print(f"No se pudo actualizar password: {r3.status_code} {r3.text}")
                else:
                    print("Password actualizado, reintentando login...")
                    login_id = try_login()
    except Exception as exc:
        print(f"Error durante el intento de creación/actualización de usuario: {exc}")

if not login_id:
    print("No fue posible autenticarse. Ajusta tools/.env con credenciales válidas o revisa la API key.")
    sys.exit(1)

print(f"Login id obtenido: {login_id}")

# 3) llamar al endpoint de importación
imp_url = f"{API_BASE_URL.rstrip('/')}/importarCredenciales"
params = {"overwrite": str(OVERWRITE).lower(), "wipe": str(WIPE).lower()}
headers.update({"X-Login-Id": str(login_id)})
print(f"Llamando a {imp_url} params={params}")
resp2 = requests.post(imp_url, params=params, headers=headers)

if resp2.status_code != 200:
    print(f"Error en importación: {resp2.status_code} {resp2.text}")
    sys.exit(1)

print("Importación completada:")
print(resp2.json())

print("Hecho.")
