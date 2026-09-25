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
    sukisu

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

#### sukisu

Configuración experimental:

    SukiSU Ultra builtin
    SUSFS 2.3.0
    Inline Hook
    KPM OFF

Kernel independiente:

    kernel/xiaomi/sm8250_sukisu

Submódulo SukiSU:

    branch local: umi-4.19-builtin
    commit: 05ee7d0a
    kernel: guard selinux_hide hooks on legacy kernels

Kernel padre experimental:

    branch: sukisu-ultra-builtin-test
    commit: b5148f728f8b
    sm8250: add experimental SukiSU Ultra SUSFS support

La primera compilación directa del kernel terminó correctamente.

Image validado:

    SHA256:
    5fcb9702ef468809bf4ef9f09fcd22b892a6155c6628cdcfaede6cebb2f10182

Auditoría binaria:

    PASS: 33
    WARN: 0
    FAIL: 0

Identificación comprobada:

    SukiSU-Ultra version: 40939 [v4.2.0-b20dee70@HEAD]
    KERNEL_VERSION: 4.19
    KERNEL_TYPE: Non-GKI
    SukiSU-Ultra: using SUSFS_INLINE_HOOK
    SUSFS_VERSION: v2.3.0

Validación hardware de SukiSU todavía pendiente.

### Compatibilidad SukiSU con kernel 4.19

La rama `builtin` de SukiSU llamaba handlers `selinux_hide` que solo se incluyen en kernels >= 5.10.

Se añadieron guards:

    LINUX_VERSION_CODE >= KERNEL_VERSION(5, 10, 0)

alrededor de:

    ksu_selinux_hide_handle_post_fs_data()
    ksu_selinux_hide_handle_second_stage()

Resultado:

    kernel 4.19.325 compilado correctamente

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

    TARGET_KERNEL_SOURCE:
    kernel/xiaomi/sm8250_sukisu

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

- Publicar o hacer reproducible el commit modificado de SukiSU.
- Actualizar `.gitmodules` al origen reproducible.
- Commit del selector SukiSU y `KERNEL_JOBS` en el device tree.
- Build RisingOS completa con SukiSU.
- Validación física SukiSU en Mi 10.
- SukiSU + KPM.
- APatch / KernelPatch.
- Wild KSU.
- Perfil Infinitix.
