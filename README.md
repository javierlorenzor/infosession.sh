# 🧩 Sistema de Monitorización de Procesos y Sesiones en Bash

## 📘 Descripción General

Este proyecto implementa un **script en Bash** que analiza y muestra información detallada sobre los **procesos y sesiones del sistema** asociados al usuario actual.  

---

## ⚙️ Características Principales

- Visualiza **procesos** o **sesiones** del usuario actual.
- Muestra información detallada: **SID**, **PGID**, **PID**, **Usuario**, **TTY**, **%MEM**, **Comando**, etc.
- Permite aplicar **filtros combinables**, como:
  - Usuarios específicos.
  - Procesos con terminal asignada.
  - Procesos que acceden a un directorio.
- Soporta **ordenación** por porcentaje de memoria o número de procesos.
- Permite mostrar la información en **orden inverso**.
- Incluye **control avanzado de errores** y mensajes de ayuda interactivos.

---

## 🧰 Lenguaje y Dependencias

- **Lenguaje:** Bash (Bourne Again Shell)
- **Dependencias del sistema:**
  - `ps` — para listar procesos.
  - `awk` — para el filtrado y formato de columnas.
  - `lsof` — para identificar archivos abiertos por procesos.
  - `tput` — para aplicar estilos de color.
  - `sort`, `uniq`, `wc` — para ordenar y procesar datos.

---

## 🧪 Instalación y Uso

### 1️⃣ Dar permisos de ejecución
```bash
chmod +x script_procesos.sh
