# Changelog - build-umi-rom.sh

Historial del orquestador de compilaciones para Xiaomi Mi 10 (`umi`).

## 2026-09-25

### Arquitectura multi-ROM

Se creó el orquestador:

    /home/pablo/rom-tools/build-umi-rom.sh

El script se mantiene fuera de los árboles Android para poder controlar varias ROMs desde una herramienta común.

Perfiles actuales:

    RisingOS    operativo
    Infinitix   reservado / pendiente

### Build completa

RisingOS se prepara mediante:

    . build/envsetup.sh
    riseup umi userdebug

La build completa usa:

    rise b -j<ROM_JOBS>

### Variantes root

Añadidas:

    magisk
    resukisu
    susfs
#### magisk

Kernel sin KSU/SUSFS.

El script conserva el `boot.img` final de `target_files` como entrada correcta para el parcheo posterior mediante Magisk.

#### resukisu

Configuración:

    ReSukiSU
    Manual Hook
    SUSFS OFF

Validada en hardware.

#### susfs

Configuración:

    ReSukiSU
    SUSFS 2.3.0
    Inline Hook

Validada en hardware.

#### SukiSU Ultra (experimento retirado)

Se evaluó SukiSU Ultra + SUSFS 2.3.0 sobre el kernel 4.19.325 de umi.

Resultado final en hardware:

    KernelSU/SukiSU ejecutándose: PASS
    SUSFS ejecutándose: PASS
    packages.list detectado: PASS
    Manager reconocido/coronado: FAIL
    boot completed/prune: FAIL
    ioctl 0xc0004bc8: unsupported
    feature_id 4: invalid

Conclusión:

SukiSU Ultra compila y arranca sobre umi/4.19, pero el camino
Manager/UAPI/features de este backport no es funcional como solución
de root completa.

El experimento se retiró el 2026-09-28.

La variante recomendada y validada continúa siendo:

    ReSukiSU + SUSFS 2.3.0 Inline Hook

### Paralelismo separado

Se separaron:

    ROM_JOBS
    KERNEL_JOBS

Motivo:

`m -j32 kernel` no impedía que la infraestructura Lineage/Rising invocase internamente `make -j96`.

Se añadió al `BoardConfig.mk`:

    ifneq ($(KERNEL_JOBS),)
    TARGET_KERNEL_ADDITIONAL_FLAGS += -j$(KERNEL_JOBS)
    endif

Configuración recomendada para ServerHive:

    ROM_JOBS=96
    KERNEL_JOBS=32

Validado mediante:

    TARGET_KERNEL_ADDITIONAL_FLAGS:
    ... -j32 TARGET_BOARD_PLATFORM=kona

### Dry-run

Añadido modo:

    --dry-run

Permite comprobar ROM, root, árboles, fragments, variables y jobs sin limpiar outputs ni compilar.

### Logging

Las compilaciones largas muestran progreso en tiempo real y guardan simultáneamente el log mediante `tee`.

### Documentación

Añadido:

    /home/pablo/rom-tools/README-build-umi-rom.md
    /home/pablo/rom-tools/CHANGELOG.md

El README describe el uso cotidiano del orquestador.

El CHANGELOG registra la evolución técnica de la herramienta.

### Ayuda integrada

Añadidas las opciones:

    -h
    --help

Ambas muestran una ayuda rápida con:

- sintaxis;
- ROMs;
- variantes root;
- `ROM_JOBS`;
- `KERNEL_JOBS`;
- valores recomendados para ServerHive;
- ejemplos;
- `--dry-run`;
- ruta del README.

Validación realizada:

    --help RC=0
    -h RC=0
    menú ROM no ejecutado
    menú ROOT no ejecutado
    entorno de build no preparado
    compilación no iniciada
    salida de -h y --help idéntica

La implementación mantiene la política de seguridad del script:

    sin exit
    sin logout
    sin exec
    sin set -e

### Pendiente

- APatch / KernelPatch.
- Wild KSU.
- Perfil Infinitix.
