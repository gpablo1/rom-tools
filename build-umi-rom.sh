#!/usr/bin/env bash

###############################################################################
# Xiaomi Mi 10 (umi) - Multi-ROM Builder
#
# ROMs:
#   risingos   -> operativo
#   infinitix  -> reservado para futura implementación
#
# Variantes root actualmente operativas:
#   magisk     -> kernel limpio, sin KSU/ReSukiSU/SUSFS
#   resukisu   -> ReSukiSU Manual Hook
#   susfs      -> ReSukiSU + SUSFS Inline Hook
#
# Siempre compila la ROM COMPLETA.
#
# Uso:
#   build-umi-rom.sh
#   build-umi-rom.sh risingos susfs
#   build-umi-rom.sh risingos resukisu
#   build-umi-rom.sh risingos magisk
#   build-umi-rom.sh risingos susfs 16
#   build-umi-rom.sh risingos susfs --dry-run
#   build-umi-rom.sh risingos susfs 16 --dry-run
#
# Seguridad para ServerHive:
#   - no usa exit
#   - no usa logout
#   - no usa exec
#   - no usa set -e
#   - toda build larga se muestra en vivo mediante tee
###############################################################################

DEVICE="umi"
BUILD_TYPE="userdebug"

ROM="${1:-}"
ROOT_MODE="${2:-}"
ARG3="${3:-}"
ARG4="${4:-}"
ARG5="${5:-}"

VALID=1
BUILD_OK=0
CONFIG_OK=0
DO_BUILD=1
DRY_RUN=0

JOBS="$(nproc)"
KERNEL_JOBS="32"

###############################################################################
# ARGUMENTOS OPCIONALES
###############################################################################

if [[ "$ARG3" =~ ^[0-9]+$ ]]; then
    JOBS="$ARG3"
elif [ "$ARG3" = "--dry-run" ]; then
    DRY_RUN=1
elif [ -n "$ARG3" ]; then
    echo "[FAIL] Tercer argumento no reconocido: $ARG3"
    VALID=0
fi

if [[ "$ARG4" =~ ^[0-9]+$ ]]; then
    KERNEL_JOBS="$ARG4"
elif [ "$ARG4" = "--dry-run" ]; then
    DRY_RUN=1
elif [ -n "$ARG4" ]; then
    echo "[FAIL] Cuarto argumento no reconocido: $ARG4"
    VALID=0
fi

if [ "$ARG5" = "--dry-run" ]; then
    DRY_RUN=1
elif [ -n "$ARG5" ]; then
    echo "[FAIL] Quinto argumento no reconocido: $ARG5"
    VALID=0
fi

###############################################################################
# PERFILES ROM
###############################################################################

RISING_TOP="/home/pablo/rising"
INFINITIX_TOP="/home/pablo/infinitix"

echo "============================================================"
echo " Xiaomi Mi 10 (umi) - Multi-ROM Builder"
echo "============================================================"
echo

###############################################################################
# MENU ROM
###############################################################################

if [ "$VALID" -eq 1 ] && [ -z "$ROM" ]; then

    echo "Selecciona ROM:"
    echo
    echo "  1) RisingOS"
    echo "  2) Infinitix [todavía no configurada]"
    echo
    printf "Opción [1-2]: "

    read -r ROM_OPTION

    case "$ROM_OPTION" in
        1)
            ROM="risingos"
            ;;
        2)
            ROM="infinitix"
            ;;
        *)
            echo "[FAIL] Opción ROM no válida"
            VALID=0
            ;;
    esac
fi

ROM="${ROM,,}"

###############################################################################
# MENU ROOT
###############################################################################

if [ "$VALID" -eq 1 ] && [ -z "$ROOT_MODE" ]; then

    echo
    echo "Selecciona variante de root:"
    echo
    echo "  1) Magisk-ready"
    echo "     Kernel sin KSU/ReSukiSU/SUSFS"
    echo
    echo "  2) ReSukiSU"
    echo "     Manual Hook"
    echo
    echo "  3) ReSukiSU + SUSFS"
    echo "     SUSFS Inline Hook"
    echo
    echo "  4) SukiSU Ultra + SUSFS"
    echo "     SukiSU builtin + SUSFS Inline Hook"
    echo
    printf "Opción [1-4]: "

    read -r ROOT_OPTION

    case "$ROOT_OPTION" in
        1)
            ROOT_MODE="magisk"
            ;;
        2)
            ROOT_MODE="resukisu"
            ;;
        3)
            ROOT_MODE="susfs"
            ;;
        4)
            ROOT_MODE="sukisu"
            ;;
        *)
            echo "[FAIL] Opción root no válida"
            VALID=0
            ;;
    esac
fi

ROOT_MODE="${ROOT_MODE,,}"

###############################################################################
# SELECCIONAR PERFIL ROM
###############################################################################

if [ "$VALID" -eq 1 ]; then

    case "$ROM" in

        risingos|rising)

            ROM="risingos"
            ROM_NAME="RisingOS"
            ROM_TOP="$RISING_TOP"
            ROM_CONFIGURED=1
            ;;

        infinitix)

            ROM_NAME="Infinitix"
            ROM_TOP="$INFINITIX_TOP"
            ROM_CONFIGURED=0

            echo
            echo "[INFO] Infinitix todavía no tiene perfil de build."
            echo "[INFO] No se ejecutará ninguna compilación."
            VALID=0
            ;;

        *)

            echo "[FAIL] ROM desconocida: $ROM"
            VALID=0
            ;;
    esac
fi

###############################################################################
# SELECCIONAR VARIANTE ROOT
###############################################################################

if [ "$VALID" -eq 1 ]; then

    case "$ROOT_MODE" in

        magisk|none|noroot|stock)

            ROOT_MODE="magisk"
            ROOT_LABEL="MAGISK-READY / NO KSU"
            ROOT_FRAGMENT="vendor/xiaomi/umi-no-resukisu.config"
            ;;

        resukisu|manual)

            ROOT_MODE="resukisu"
            ROOT_LABEL="ReSukiSU MANUAL HOOK"
            ROOT_FRAGMENT="vendor/xiaomi/umi-resukisu.config"
            ;;

        susfs|resukisu-susfs|resukisu_susfs)

            ROOT_MODE="susfs"
            ROOT_LABEL="ReSukiSU + SUSFS 2.3.0 INLINE HOOK"
            ROOT_FRAGMENT="vendor/xiaomi/umi-resukisu-susfs.config"
            ;;

        sukisu|sukisu-susfs|sukisu_susfs)

            ROOT_MODE="sukisu"
            ROOT_LABEL="SukiSU ULTRA + SUSFS 2.3.0 INLINE HOOK"
            ROOT_FRAGMENT="vendor/xiaomi/umi-sukisu-susfs.config"
            ;;

        *)

            echo "[FAIL] Variante root desconocida: $ROOT_MODE"
            VALID=0
            ;;
    esac
fi

###############################################################################
# RUTAS
###############################################################################

if [ "$VALID" -eq 1 ]; then

    OUT="$ROM_TOP/out/target/product/$DEVICE"
    DEVICE_TREE="$ROM_TOP/device/xiaomi/umi"

    if [ "$ROOT_MODE" = "sukisu" ]; then
        KERNEL="$ROM_TOP/kernel/xiaomi/sm8250_sukisu"
    else
        KERNEL="$ROM_TOP/kernel/xiaomi/sm8250"
    fi

    FRAGMENT_PATH="$KERNEL/arch/arm64/configs/$ROOT_FRAGMENT"

    AUDIT_ROOT="$ROM_TOP/_audits/build_variants"
    AUDIT_DIR="$AUDIT_ROOT/${ROM}_${ROOT_MODE}"

    mkdir -p "$AUDIT_DIR"
fi

###############################################################################
# RESUMEN SOLICITADO
###############################################################################

if [ "$VALID" -eq 1 ]; then

    echo
    echo "============================================================"
    echo " CONFIGURACION SOLICITADA"
    echo "============================================================"
    echo
    echo "ROM          : $ROM_NAME"
    echo "Source tree  : $ROM_TOP"
    echo "Device       : $DEVICE"
    echo "Build type   : $BUILD_TYPE"
    echo "Root         : $ROOT_LABEL"
    echo "Fragment     : $ROOT_FRAGMENT"
    echo "ROM jobs     : $JOBS"
    echo "Kernel jobs  : $KERNEL_JOBS"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Modo         : DRY-RUN"
    else
        echo "Modo         : BUILD COMPLETA"
    fi
fi

###############################################################################
# VALIDAR ÁRBOL
###############################################################################

if [ "$VALID" -eq 1 ]; then

    echo
    echo "=== VALIDACION DEL SOURCE TREE ==="

    if [ -d "$ROM_TOP" ]; then
        echo "[PASS] Source tree encontrado"
    else
        echo "[FAIL] Source tree no encontrado: $ROM_TOP"
        VALID=0
    fi

    if [ -f "$ROM_TOP/build/envsetup.sh" ]; then
        echo "[PASS] build/envsetup.sh encontrado"
    else
        echo "[FAIL] Falta build/envsetup.sh"
        VALID=0
    fi

    if [ -d "$KERNEL" ]; then
        echo "[PASS] Kernel tree encontrado"
    else
        echo "[FAIL] Kernel tree no encontrado"
        VALID=0
    fi

    if [ -d "$DEVICE_TREE" ]; then
        echo "[PASS] Device tree encontrado"
    else
        echo "[FAIL] Device tree no encontrado"
        VALID=0
    fi

    if [ -f "$FRAGMENT_PATH" ]; then
        echo "[PASS] Fragment root encontrado"
    else
        echo "[FAIL] Fragment root no encontrado:"
        echo "$FRAGMENT_PATH"
        VALID=0
    fi
fi

###############################################################################
# ESTADO DE GIT
###############################################################################

if [ "$VALID" -eq 1 ]; then

    echo
    echo "=== SOURCE STATUS ==="

    KERNEL_STATUS="$(git -C "$KERNEL" status --porcelain 2>/dev/null)"
    DEVICE_STATUS="$(git -C "$DEVICE_TREE" status --porcelain 2>/dev/null)"

    if [ -z "$KERNEL_STATUS" ]; then
        echo "[PASS] Kernel repo limpio"
    else
        echo "[WARN] Kernel repo tiene cambios:"
        printf '%s\n' "$KERNEL_STATUS"
    fi

    if [ -z "$DEVICE_STATUS" ]; then
        echo "[PASS] Device repo limpio"
    else
        echo "[WARN] Device repo tiene cambios:"
        printf '%s\n' "$DEVICE_STATUS"
    fi

    echo
    echo "Kernel HEAD:"
    git -C "$KERNEL" log -1 --oneline

    echo
    echo "Device HEAD:"
    git -C "$DEVICE_TREE" log -1 --oneline
fi

###############################################################################
# DRY-RUN
###############################################################################

if [ "$VALID" -eq 1 ] && [ "$DRY_RUN" -eq 1 ]; then

    DO_BUILD=0

    echo
    echo "============================================================"
    echo " DRY-RUN"
    echo "============================================================"
    echo
    echo "No se borrará ningún output."
    echo "No se ejecutará ninguna compilación."
    echo
    echo "Entorno previsto:"

    case "$ROM" in
        risingos)
            echo ". build/envsetup.sh"
            echo "riseup umi userdebug"
            echo "rise b -j$JOBS"
            echo "KERNEL_JOBS=$KERNEL_JOBS"
            ;;
    esac

    echo
    echo "Root previsto:"

    case "$ROOT_MODE" in
        magisk)
            echo "WITH_SUKISU=<unset>"
            echo "WITH_RESUKISU=<unset>"
            echo "WITH_RESUKISU_SUSFS=<unset>"
            ;;
        resukisu)
            echo "WITH_SUKISU=<unset>"
            echo "WITH_RESUKISU=true"
            echo "WITH_RESUKISU_SUSFS=<unset>"
            ;;
        susfs)
            echo "WITH_SUKISU=<unset>"
            echo "WITH_RESUKISU=<unset>"
            echo "WITH_RESUKISU_SUSFS=true"
            ;;
        sukisu)
            echo "WITH_SUKISU=true"
            echo "WITH_RESUKISU=<unset>"
            echo "WITH_RESUKISU_SUSFS=<unset>"
            echo "TARGET_KERNEL_SOURCE=kernel/xiaomi/sm8250_sukisu"
            ;;
    esac

    echo
    echo "[PASS] Dry-run completado"
fi

###############################################################################
# LIMPIEZA DE OUTPUTS SENSIBLES A LA VARIANTE
###############################################################################

if [ "$VALID" -eq 1 ] && [ "$DO_BUILD" -eq 1 ]; then

    echo
    echo "============================================================"
    echo " LIMPIEZA DE OUTPUTS DEPENDIENTES DEL KERNEL"
    echo "============================================================"

    rm -rf "$OUT/obj/KERNEL_OBJ"

    rm -f "$OUT/kernel"
    rm -f "$OUT/boot.img"

    rm -rf "$OUT/obj/PACKAGING/target_files_intermediates"

    echo "[PASS] Outputs sensibles a la variante eliminados"
    echo "[INFO] No se ha borrado el resto de out/"
fi

###############################################################################
# PREPARAR ENTORNO ROM
###############################################################################

if [ "$VALID" -eq 1 ] && [ "$DO_BUILD" -eq 1 ]; then

    cd "$ROM_TOP"

    echo
    echo "============================================================"
    echo " PREPARANDO ENTORNO $ROM_NAME"
    echo "============================================================"

    . build/envsetup.sh
    ENV_RC=$?

    if [ "$ENV_RC" -eq 0 ]; then
        echo "[PASS] envsetup cargado"
    else
        echo "[FAIL] envsetup rc=$ENV_RC"
        VALID=0
    fi
fi

###############################################################################
# VARIABLES ROOT
###############################################################################

if [ "$VALID" -eq 1 ] && [ "$DO_BUILD" -eq 1 ]; then

    unset WITH_SUKISU
    unset WITH_RESUKISU
    unset WITH_RESUKISU_SUSFS

    export KERNEL_JOBS="$KERNEL_JOBS"

    case "$ROOT_MODE" in

        magisk)

            unset WITH_SUKISU
            unset WITH_RESUKISU
            unset WITH_RESUKISU_SUSFS
            ;;

        resukisu)

            unset WITH_SUKISU
            export WITH_RESUKISU=true
            unset WITH_RESUKISU_SUSFS
            ;;

        susfs)

            unset WITH_SUKISU
            unset WITH_RESUKISU
            export WITH_RESUKISU_SUSFS=true
            ;;

        sukisu)

            export WITH_SUKISU=true
            unset WITH_RESUKISU
            unset WITH_RESUKISU_SUSFS
            ;;
    esac

    echo
    echo "=== ROOT ENVIRONMENT ==="
    echo "WITH_SUKISU=${WITH_SUKISU:-<unset>}"
    echo "WITH_RESUKISU=${WITH_RESUKISU:-<unset>}"
    echo "WITH_RESUKISU_SUSFS=${WITH_RESUKISU_SUSFS:-<unset>}"
    echo "KERNEL_JOBS=${KERNEL_JOBS}"
fi

###############################################################################
# CONFIGURACIÓN ESPECÍFICA DE ROM
###############################################################################

if [ "$VALID" -eq 1 ] && [ "$DO_BUILD" -eq 1 ]; then

    echo
    echo "=== CONFIGURACION DE $ROM_NAME ==="

    case "$ROM" in

        risingos)

            riseup umi userdebug
            SETUP_RC=$?

            if [ "$SETUP_RC" -eq 0 ]; then
                echo "[PASS] riseup umi userdebug"
            else
                echo "[FAIL] riseup rc=$SETUP_RC"
                VALID=0
            fi
            ;;

        infinitix)

            echo "[FAIL] Perfil Infinitix todavía no implementado"
            VALID=0
            ;;
    esac
fi

###############################################################################
# METADATA DE BUILD
###############################################################################

if [ "$VALID" -eq 1 ] && [ "$DO_BUILD" -eq 1 ]; then

    META="$AUDIT_DIR/build-metadata.txt"

    {
        echo "ROM=$ROM_NAME"
        echo "ROM_ID=$ROM"
        echo "DEVICE=$DEVICE"
        echo "BUILD_TYPE=$BUILD_TYPE"
        echo "ROOT_MODE=$ROOT_MODE"
        echo "ROOT_LABEL=$ROOT_LABEL"
        echo "ROOT_FRAGMENT=$ROOT_FRAGMENT"
        echo "ROM_JOBS=$JOBS"
        echo "KERNEL_JOBS=$KERNEL_JOBS"
        echo "DATE=$(date -Is)"
        echo "ROM_TOP=$ROM_TOP"
        echo "KERNEL_HEAD=$(git -C "$KERNEL" rev-parse HEAD 2>/dev/null)"
        echo "DEVICE_HEAD=$(git -C "$DEVICE_TREE" rev-parse HEAD 2>/dev/null)"
        echo "WITH_SUKISU=${WITH_SUKISU:-}"
        echo "WITH_RESUKISU=${WITH_RESUKISU:-}"
        echo "WITH_RESUKISU_SUSFS=${WITH_RESUKISU_SUSFS:-}"
    } > "$META"

    echo
    echo "Metadata:"
    echo "$META"
fi

###############################################################################
# BUILD COMPLETA DE LA ROM
###############################################################################

if [ "$VALID" -eq 1 ] && [ "$DO_BUILD" -eq 1 ]; then

    TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
    LOG="$AUDIT_DIR/${ROM}_${ROOT_MODE}_${TIMESTAMP}.log"

    echo
    echo "============================================================"
    echo " BUILD COMPLETA DE $ROM_NAME"
    echo "============================================================"
    echo
    echo "Root : $ROOT_LABEL"
    echo "Jobs : $JOBS"
    echo "Log  : $LOG"
    echo

    case "$ROM" in

        risingos)

            rise b -j"$JOBS" 2>&1 | tee "$LOG"
            BUILD_RC=${PIPESTATUS[0]}
            ;;

        infinitix)

            echo "[FAIL] Comando de build Infinitix todavía no configurado"
            BUILD_RC=1
            ;;
    esac

    echo
    echo "============================================================"
    echo " RESULTADO BUILD"
    echo "============================================================"

    if [ "$BUILD_RC" -eq 0 ]; then
        echo "[PASS] Build completa terminada"
        BUILD_OK=1
    else
        echo "[FAIL] Build completa rc=$BUILD_RC"
        BUILD_OK=0
    fi

    echo "Log: $LOG"
fi

###############################################################################
# VALIDAR CONFIG REAL DEL KERNEL
###############################################################################

if [ "$BUILD_OK" -eq 1 ]; then

    CONFIG="$OUT/obj/KERNEL_OBJ/.config"
    SYSMAP="$OUT/obj/KERNEL_OBJ/System.map"
    VMLINUX="$OUT/obj/KERNEL_OBJ/vmlinux"

    CONFIG_OK=1

    echo
    echo "============================================================"
    echo " VALIDACION DEL KERNEL INCLUIDO EN LA ROM"
    echo "============================================================"

    if [ ! -f "$CONFIG" ]; then
        echo "[FAIL] No existe $CONFIG"
        CONFIG_OK=0
    fi

    if [ "$CONFIG_OK" -eq 1 ]; then

        case "$ROOT_MODE" in

            magisk)

                if grep -q '^# CONFIG_KSU is not set$' "$CONFIG"; then
                    echo "[PASS] CONFIG_KSU desactivado"
                else
                    echo "[FAIL] CONFIG_KSU no está desactivado"
                    CONFIG_OK=0
                fi

                if grep -qw 'ksu_handle_execveat' "$SYSMAP" 2>/dev/null; then
                    echo "[FAIL] Persisten símbolos KSU"
                    CONFIG_OK=0
                else
                    echo "[PASS] Sin símbolos KSU"
                fi

                SUSFS_COUNT="$(grep -c ' susfs_' "$SYSMAP" 2>/dev/null || true)"

                if [ "$SUSFS_COUNT" -eq 0 ]; then
                    echo "[PASS] Sin símbolos SUSFS"
                else
                    echo "[FAIL] Persisten $SUSFS_COUNT símbolos SUSFS"
                    CONFIG_OK=0
                fi
                ;;

            resukisu)

                if grep -q '^CONFIG_KSU=y$' "$CONFIG"; then
                    echo "[PASS] CONFIG_KSU=y"
                else
                    echo "[FAIL] CONFIG_KSU"
                    CONFIG_OK=0
                fi

                if grep -q '^CONFIG_KSU_MANUAL_HOOK=y$' "$CONFIG"; then
                    echo "[PASS] Manual Hook activo"
                else
                    echo "[FAIL] Manual Hook no activo"
                    CONFIG_OK=0
                fi

                if grep -q '^CONFIG_KSU_SUSFS=y$' "$CONFIG"; then
                    echo "[FAIL] SUSFS activo inesperadamente"
                    CONFIG_OK=0
                else
                    echo "[PASS] SUSFS desactivado"
                fi
                ;;

            susfs)

                if grep -q '^CONFIG_KSU=y$' "$CONFIG"; then
                    echo "[PASS] CONFIG_KSU=y"
                else
                    echo "[FAIL] CONFIG_KSU"
                    CONFIG_OK=0
                fi

                if grep -q '^CONFIG_KSU_SUSFS=y$' "$CONFIG"; then
                    echo "[PASS] SUSFS Inline activo"
                else
                    echo "[FAIL] SUSFS no activo"
                    CONFIG_OK=0
                fi

                if grep -q '^CONFIG_KSU_MANUAL_HOOK=y$' "$CONFIG"; then
                    echo "[FAIL] Manual Hook activo inesperadamente"
                    CONFIG_OK=0
                else
                    echo "[PASS] Manual Hook desactivado"
                fi

                SUSFS_COUNT="$(grep -c '^CONFIG_KSU_SUSFS.*=y$' "$CONFIG" || true)"

                echo "CONFIG_KSU_SUSFS*=y: $SUSFS_COUNT"

                if [ "$SUSFS_COUNT" -eq 10 ]; then
                    echo "[PASS] SUSFS parent + 9 features"
                else
                    echo "[WARN] Se esperaban 10 opciones SUSFS activas"
                fi
                ;;

            sukisu)

                if grep -q '^CONFIG_KSU=y$' "$CONFIG"; then
                    echo "[PASS] CONFIG_KSU=y"
                else
                    echo "[FAIL] CONFIG_KSU"
                    CONFIG_OK=0
                fi

                if grep -q '^CONFIG_KSU_SUSFS=y$' "$CONFIG"; then
                    echo "[PASS] SukiSU SUSFS activo"
                else
                    echo "[FAIL] SukiSU SUSFS no activo"
                    CONFIG_OK=0
                fi

                if grep -q '^# CONFIG_KPM is not set$' "$CONFIG"; then
                    echo "[PASS] KPM desactivado"
                else
                    echo "[FAIL] Estado KPM inesperado"
                    CONFIG_OK=0
                fi

                SUSFS_COUNT="$(grep -c '^CONFIG_KSU_SUSFS.*=y$' "$CONFIG" || true)"

                echo "CONFIG_KSU_SUSFS*=y: $SUSFS_COUNT"

                if [ "$SUSFS_COUNT" -eq 10 ]; then
                    echo "[PASS] SUSFS parent + 9 features"
                else
                    echo "[WARN] Se esperaban 10 opciones SUSFS activas"
                fi
                ;;
        esac
    fi

    if [ -f "$OUT/obj/KERNEL_OBJ/include/config/kernel.release" ]; then
        echo
        echo "Kernel release:"
        cat "$OUT/obj/KERNEL_OBJ/include/config/kernel.release"
    fi
fi

###############################################################################
# LOCALIZAR BOOT FINAL REAL DEL PACKAGING
###############################################################################

if [ "$BUILD_OK" -eq 1 ]; then

    echo
    echo "============================================================"
    echo " BOOT FINAL INCLUIDO EN LA ROM"
    echo "============================================================"

    FINAL_BOOT="$(
        find "$OUT/obj/PACKAGING/target_files_intermediates" \
            -type f \
            -path '*/IMAGES/boot.img' \
            -printf '%T@ %p\n' \
            2>/dev/null \
        | sort -nr \
        | head -n 1 \
        | cut -d' ' -f2-
    )"

    if [ -n "$FINAL_BOOT" ] && [ -s "$FINAL_BOOT" ]; then

        echo "[PASS] Boot final encontrado:"
        echo "$FINAL_BOOT"

        FINAL_BOOT_SHA="$(sha256sum "$FINAL_BOOT" | awk '{print $1}')"

        echo
        echo "SHA256:"
        echo "$FINAL_BOOT_SHA"

        SAVED_BOOT="$AUDIT_DIR/boot-final-${ROM}-${ROOT_MODE}.img"

        cp -f "$FINAL_BOOT" "$SAVED_BOOT"

        echo
        echo "Copia preservada:"
        echo "$SAVED_BOOT"

        sha256sum "$SAVED_BOOT"

        if [ "$ROOT_MODE" = "magisk" ]; then

            echo
            echo "------------------------------------------------------------"
            echo " MAGISK PATCH INPUT"
            echo "------------------------------------------------------------"
            echo
            echo "Parchea ESTE archivo con Magisk:"
            echo
            echo "$SAVED_BOOT"
            echo
            echo "No uses out/target/product/umi/boot.img previo al packaging."
        fi

    else

        echo "[WARN] No se encontró IMAGES/boot.img en target_files"
    fi
fi

###############################################################################
# ARTEFACTOS FINALES
###############################################################################

if [ "$BUILD_OK" -eq 1 ]; then

    echo
    echo "============================================================"
    echo " ARTEFACTOS FINALES DE $ROM_NAME"
    echo "============================================================"

    mapfile -t ROM_FILES < <(
        find "$OUT" \
            -maxdepth 1 \
            -type f \
            -name 'RisingOS-*.zip' \
            -printf '%T@ %p\n' \
            2>/dev/null \
        | sort -nr \
        | head -n 4 \
        | cut -d' ' -f2-
    )

    if [ "${#ROM_FILES[@]}" -eq 0 ]; then

        echo "[WARN] No se encontraron ZIP finales"

    else

        for FILE in "${ROM_FILES[@]}"; do
            echo
            ls -lh "$FILE"
            sha256sum "$FILE"
        done
    fi
fi

###############################################################################
# RESUMEN FINAL
###############################################################################

echo
echo "============================================================"
echo " RESUMEN FINAL"
echo "============================================================"
echo

echo "ROM          : ${ROM_NAME:-desconocida}"
echo "Root         : ${ROOT_LABEL:-desconocido}"
echo "Jobs         : $JOBS"

if [ "$DRY_RUN" -eq 1 ] && [ "$VALID" -eq 1 ]; then

    echo "Modo         : DRY-RUN"
    echo "Resultado    : PASS"

elif [ "$BUILD_OK" -eq 1 ] && [ "$CONFIG_OK" -eq 1 ]; then

    echo "Modo         : BUILD COMPLETA"
    echo "Build ROM    : PASS"
    echo "Kernel root  : PASS"

else

    echo "Build ROM    : FAIL / NO EJECUTADA"
    echo "Kernel root  : NO VALIDADO"
fi

echo
echo "La sesión SSH permanece abierta."

if [ "$DRY_RUN" -eq 1 ] && [ "$VALID" -eq 1 ]; then
    true
elif [ "$BUILD_OK" -eq 1 ] && [ "$CONFIG_OK" -eq 1 ]; then
    true
else
    false
fi
