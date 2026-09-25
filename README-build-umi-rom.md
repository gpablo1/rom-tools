# build-umi-rom.sh

Manual de uso del orquestador de compilaciones para Xiaomi Mi 10 (`umi`).

Ruta del script:

    /home/pablo/rom-tools/build-umi-rom.sh

## 1. Finalidad

`build-umi-rom.sh` prepara y compila ROMs completas para `umi`, seleccionando
automáticamente la ROM, la variante de root, el árbol del kernel, los fragments,
las variables de entorno, el paralelismo, las validaciones, los logs y los
artefactos finales.

Estado actual de ROMs:

    RisingOS   operativa
    Infinitix  reservada; todavía no configurada

Variantes de root disponibles:

    magisk    kernel limpio / Magisk-ready
    resukisu  ReSukiSU Manual Hook
    susfs     ReSukiSU + SUSFS 2.3.0 Inline Hook
    sukisu    SukiSU Ultra + SUSFS 2.3.0 Inline Hook

## 2. Sintaxis recomendada

    /home/pablo/rom-tools/build-umi-rom.sh ROM ROOT ROM_JOBS KERNEL_JOBS [--dry-run]

Ejemplo recomendado para ServerHive:

    /home/pablo/rom-tools/build-umi-rom.sh risingos sukisu 96 32

Interpretación:

    ROM          RisingOS
    ROOT         SukiSU Ultra + SUSFS
    ROM_JOBS     96
    KERNEL_JOBS  32

En ServerHive se recomienda actualmente:

    ROM_JOBS=96
    KERNEL_JOBS=32

## 3. Menú interactivo

También puede ejecutarse sin argumentos:

    /home/pablo/rom-tools/build-umi-rom.sh

El script mostrará un menú para elegir ROM y root.

ROMs:

    1) RisingOS
    2) Infinitix [todavía no configurada]

Root:

    1) Magisk-ready
    2) ReSukiSU
    3) ReSukiSU + SUSFS
    4) SukiSU Ultra + SUSFS

Valores predeterminados actuales:

    ROM_JOBS     nproc
    KERNEL_JOBS  32

En ServerHive `nproc` devuelve actualmente 96.

## 4. RisingOS

Source tree:

    /home/pablo/rising

Preparación:

    . build/envsetup.sh
    riseup umi userdebug

Build completa:

    rise b -j<ROM_JOBS>

Ejemplo:

    rise b -j96

El kernel recibe además su propio límite mediante `KERNEL_JOBS`.

## 5. Variante magisk

Comando:

    /home/pablo/rom-tools/build-umi-rom.sh risingos magisk 96 32

Esta variante genera una ROM con kernel limpio:

    KernelSU  OFF
    ReSukiSU  OFF
    SukiSU    OFF
    SUSFS     OFF

Kernel:

    kernel/xiaomi/sm8250

Fragment:

    vendor/xiaomi/umi-no-resukisu.config

Variables:

    WITH_SUKISU=<unset>
    WITH_RESUKISU=<unset>
    WITH_RESUKISU_SUSFS=<unset>

`magisk` no instala Magisk. Su finalidad es producir una ROM con un `boot.img`
sin KSU para parchearlo posteriormente con Magisk.

Debe utilizarse el `boot.img` final del packaging, procedente de
`target_files/.../IMAGES/boot.img`, no un `boot.img` intermedio.

## 6. Variante resukisu

Comando:

    /home/pablo/rom-tools/build-umi-rom.sh risingos resukisu 96 32

Configuración:

    ReSukiSU
    Manual Hook
    SUSFS OFF

Kernel:

    kernel/xiaomi/sm8250

Fragment:

    vendor/xiaomi/umi-resukisu.config

Variable:

    WITH_RESUKISU=true

Estado:

    Compilación     PASS
    Hardware Mi 10  PASS

## 7. Variante susfs

Comando:

    /home/pablo/rom-tools/build-umi-rom.sh risingos susfs 96 32

Configuración:

    ReSukiSU
    SUSFS 2.3.0
    Inline Hook

Kernel:

    kernel/xiaomi/sm8250

Fragment:

    vendor/xiaomi/umi-resukisu-susfs.config

Variable:

    WITH_RESUKISU_SUSFS=true

Configuración esperada:

    CONFIG_KSU=y
    CONFIG_KSU_SUSFS=y
    CONFIG_KSU_MANUAL_HOOK no debe estar activo

El script espera 10 opciones `CONFIG_KSU_SUSFS*=y`:

    1 padre + 9 features

Estado:

    Compilación     PASS
    Hardware Mi 10  PASS

## 8. Variante sukisu

Comando:

    /home/pablo/rom-tools/build-umi-rom.sh risingos sukisu 96 32

Configuración actual:

    SukiSU Ultra
    SUSFS 2.3.0
    Inline Hook
    KPM OFF

Kernel:

    kernel/xiaomi/sm8250_sukisu

Fragment:

    vendor/xiaomi/umi-sukisu-susfs.config

Variable:

    WITH_SUKISU=true

Configuración esperada:

    CONFIG_KSU=y
    CONFIG_KSU_FEATURE_ADBROOT=y
    CONFIG_KSU_SUSFS=y
    # CONFIG_KPM is not set

Identificación ya comprobada:

    SukiSU Ultra v4.2.0
    kernel 4.19
    Non-GKI
    SUSFS_INLINE_HOOK
    SUSFS 2.3.0

Estado actual:

    kernelconfig          PASS
    Image                 PASS
    auditoría binaria     PASS
    ROM completa          PENDIENTE
    hardware Mi 10        PENDIENTE

## 9. Alias aceptados

Nombres recomendados:

    magisk
    resukisu
    susfs
    sukisu

Alias adicionales:

    magisk:
      none
      noroot
      stock

    resukisu:
      manual

    susfs:
      resukisu-susfs
      resukisu_susfs

    sukisu:
      sukisu-susfs
      sukisu_susfs

Para evitar errores conviene usar siempre los cuatro nombres cortos.

## 10. ROM_JOBS

`ROM_JOBS` controla la compilación Android/Soong/Ninja.

Ejemplo:

    ROM_JOBS=96

produce:

    rise b -j96

## 11. KERNEL_JOBS

`KERNEL_JOBS` controla específicamente el `make` interno del kernel.

Ejemplo:

    KERNEL_JOBS=32

Se propaga desde `BoardConfig.mk` mediante:

    ifneq ($(KERNEL_JOBS),)
    TARGET_KERNEL_ADDITIONAL_FLAGS += -j$(KERNEL_JOBS)
    endif

Esto es necesario porque `m -j32 kernel` no garantiza por sí solo que el
`make` interno del kernel utilice 32 jobs.

La configuración recomendada actualmente es:

    ROM_JOBS=96
    KERNEL_JOBS=32

## 12. Ayuda integrada

El script dispone de ayuda rápida desde terminal:

    /home/pablo/rom-tools/build-umi-rom.sh --help

También puede utilizarse:

    /home/pablo/rom-tools/build-umi-rom.sh -h

Ambas opciones muestran exactamente la misma ayuda.

La ayuda incluye:

- Sintaxis completa.
- ROMs disponibles.
- Variantes de root.
- Significado de `ROM_JOBS`.
- Significado de `KERNEL_JOBS`.
- Valores recomendados para ServerHive.
- Ejemplos.
- Uso de `--dry-run`.
- Ruta de este README.

La ejecución de `-h` o `--help` termina después de mostrar la ayuda.

No:

- entra en el menú de ROM;
- entra en el menú de root;
- carga `build/envsetup.sh`;
- ejecuta `riseup`;
- limpia outputs;
- inicia ninguna compilación.

---

## 13. Dry-run

Ejemplo:

    /home/pablo/rom-tools/build-umi-rom.sh risingos sukisu 96 32 --dry-run

El dry-run NO:

    compila ROM
    compila kernel
    elimina KERNEL_OBJ
    elimina boot.img
    elimina target_files

Sirve para comprobar:

    ROM
    root
    source tree
    kernel tree
    fragment
    variables
    ROM_JOBS
    KERNEL_JOBS
    estado Git

Debe utilizarse antes de probar una nueva configuración o después de modificar
el orquestador.

## 14. Comandos rápidos

RisingOS + Magisk-ready:

    /home/pablo/rom-tools/build-umi-rom.sh risingos magisk 96 32

RisingOS + ReSukiSU Manual:

    /home/pablo/rom-tools/build-umi-rom.sh risingos resukisu 96 32

RisingOS + ReSukiSU + SUSFS:

    /home/pablo/rom-tools/build-umi-rom.sh risingos susfs 96 32

RisingOS + SukiSU + SUSFS:

    /home/pablo/rom-tools/build-umi-rom.sh risingos sukisu 96 32

Dry-run SukiSU:

    /home/pablo/rom-tools/build-umi-rom.sh risingos sukisu 96 32 --dry-run

## 15. Flujo de una build

    seleccionar ROM
          |
    seleccionar ROOT
          |
    seleccionar kernel y fragment
          |
    validar source tree y estado Git
          |
    limpiar outputs dependientes del kernel
          |
    cargar envsetup
          |
    configurar variables root y KERNEL_JOBS
          |
    riseup umi userdebug
          |
    guardar metadata
          |
    rise b -j<ROM_JOBS>
          |
    guardar log con tee
          |
    validar .config
          |
    localizar boot final
          |
    preservar artefactos y SHA256
          |
    resumen PASS/FAIL

## 16. Limpieza selectiva

Al cambiar de variante no se elimina todo `out/`.

Se invalidan principalmente:

    out/target/product/umi/obj/KERNEL_OBJ
    out/target/product/umi/kernel
    out/target/product/umi/boot.img
    out/target/product/umi/obj/PACKAGING/target_files_intermediates

Esto evita reutilizar un kernel o un `boot.img` perteneciente a otra variante.

## 17. Logs

Las compilaciones largas utilizan `tee`, por lo que el progreso debe verse en
tiempo real y conservarse simultáneamente en un archivo.

Ruta base:

    /home/pablo/rising/_audits/build_variants/

Ejemplo:

    /home/pablo/rising/_audits/build_variants/risingos_sukisu/

## 18. Metadata

Cada build registra, entre otros:

    ROM
    DEVICE
    BUILD_TYPE
    ROOT_MODE
    ROOT_FRAGMENT
    ROM_JOBS
    KERNEL_JOBS
    DATE
    ROM_TOP
    KERNEL_HEAD
    DEVICE_HEAD
    WITH_SUKISU
    WITH_RESUKISU
    WITH_RESUKISU_SUSFS

## 19. boot.img final

No debe asumirse que:

    out/target/product/umi/boot.img

sea idéntico al boot final incluido en la ROM.

El packaging puede modificar el ramdisk. El archivo correcto se toma de:

    out/target/product/umi/obj/PACKAGING/
    target_files_intermediates/.../IMAGES/boot.img

Para la variante Magisk-ready, ese es el boot que debe parchearse.

## 20. Qué NO hace el script

El script no:

    flashea el teléfono
    reinicia el teléfono
    instala Magisk
    parchea Magisk automáticamente
    instala managers root
    ejecuta repo sync
    actualiza firmware
    hace git push
    crea commits automáticamente

Su responsabilidad es:

    configurar
    compilar
    validar
    registrar
    preservar artefactos

## 21. Si falla una build

No volver a lanzar automáticamente otra build.

Conservar:

    RC
    log completo
    primer error real
    estado Git

Mensajes finales como `make: Error` o `ninja: build stopped` suelen ser
consecuencia de un error anterior. Debe localizarse el primer error real del
log.

## 22. Seguridad SSH

El script está pensado para ejecutarse desde una sesión SSH de ServerHive.

No debe contener comandos de nivel superior que puedan cerrar accidentalmente
la sesión interactiva.

Las compilaciones largas deben mantener salida visible mediante `tee`.

## 23. Estado actual

    Magisk-ready             compila: sí   hardware Magisk: pendiente
    ReSukiSU Manual          compila: sí   hardware: PASS
    ReSukiSU + SUSFS 2.3.0   compila: sí   hardware: PASS
    SukiSU + SUSFS 2.3.0     compila: sí   hardware: pendiente
    SukiSU + SUSFS + KPM     pendiente
    Infinitix                pendiente

Próximas extensiones previstas:

    SukiSU + KPM
    APatch / KernelPatch
    Wild KSU
    Infinitix

## 24. Chuleta

Forma recomendada:

    /home/pablo/rom-tools/build-umi-rom.sh risingos ROOT 96 32

Sustituir `ROOT` por uno de:

    magisk
    resukisu
    susfs
    sukisu

Antes de una configuración nueva:

    /home/pablo/rom-tools/build-umi-rom.sh risingos ROOT 96 32 --dry-run
