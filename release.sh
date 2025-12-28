#!/bin/bash
# release.sh - Script para crear releases automáticamente

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# # Verificar que estemos en el directorio correcto
# if [ ! -f "CMakeLists.txt" ]; then
#     log_error "No estás en el directorio raíz del proyecto"
# fi

# Obtener la versión
if [ -z "$1" ]; then
    log_error "Uso: ./release.sh v1.x [mensaje]"
fi

VERSION=$1
MESSAGE=${2:-"Release $VERSION"}

log_info "Creando release $VERSION"

# 1. Verificar que no haya cambios sin commitear
if ! git diff-index --quiet HEAD --; then
    log_warn "Hay cambios sin commitear. Commitea primero."
    read -p "¿Continuar de todas formas? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# # 2. Compilar firmware
# log_info "Compilando firmware..."
# idf.py build || log_error "Build falló"

# 3. Verificar que el binario existe
if [ ! -f "tricoma.bin" ]; then
    log_error "No se encontró tricoma.bin"
fi

# 4. Crear tag
log_info "Creando tag $VERSION"
git tag -a $VERSION -m "$MESSAGE" || log_warn "Tag ya existe"
git push origin $VERSION || log_warn "Tag ya estaba en remoto"

# 5. Crear/actualizar release en GitHub
log_info "Subiendo release a GitHub..."
gh release create $VERSION \
    tricoma.bin \
    --title "Release $VERSION" \
    --notes "$MESSAGE" \
    --latest 2>/dev/null || \
gh release upload $VERSION tricoma.bin --clobber

log_info "✅ Release $VERSION creado exitosamente"
log_info "🌐 URL: https://github.com/psparodi/Tricoma_releases/releases/tag/$VERSION"
log_info "📦 Binario: https://github.com/psparodi/Tricoma/releases/latest/download/tricoma.bin"