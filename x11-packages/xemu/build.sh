TERMUX_PKG_HOMEPAGE=https://xemu.app/
TERMUX_PKG_DESCRIPTION="A free and open-source emulator for the original Xbox console."
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@yewgamer"
TERMUX_PKG_VERSION=0.8.5
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL="https://github.com/xemu-project/xemu.git"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_SKIP_SRC_EXTRACT=true

TERMUX_PKG_DEPENDS="libandroid-shmem, libc++, sdl2, mesa, zlib, freetype, glib, fontconfig, harfbuzz, pango, libpng, libjpeg-turbo"
TERMUX_PKG_BUILD_DEPENDS="ninja, vulkan-headers, xorgproto, libglvnd-dev, sdl2, llvm, libllvm"

# ---------------- SOURCE ----------------
termux_step_get_source() {
    mkdir -p "$TERMUX_PKG_SRCDIR"
    cd "$TERMUX_PKG_SRCDIR"
	git clone --recurse-submodules https://github.com/xemu-project/xemu.git
	cd xemu
}

# ---------------- PRE-CONFIGURE ----------------
termux_step_pre_configure() {
    # aarch64 setjmp workaround
    if [ "$TERMUX_ARCH" = "aarch64" ]; then
        rm -f "$TERMUX_PKG_BUILDDIR/_lib"
        mkdir -p "$TERMUX_PKG_BUILDDIR/_lib"

        cd "$TERMUX_PKG_BUILDDIR"
        mkdir -p _setjmp-aarch64
        pushd _setjmp-aarch64
        mkdir -p private
        local s
        for s in $TERMUX_PKG_BUILDER_DIR/setjmp-aarch64/{setjmp.S,private-*.h}; do
            local f=$(basename "$s")
            cp "$s" "./${f/-//}"
        done
        $CC $CFLAGS $CPPFLAGS -I. setjmp.S -c
        $AR cru "$TERMUX_PKG_BUILDDIR/_lib/libandroid-setjmp.a" setjmp.o
        popd

        LDFLAGS+=" -L$TERMUX_PKG_BUILDDIR/_lib -l:libandroid-setjmp.a"
    fi

    termux_setup_meson
    termux_setup_ninja

    if [ "$TERMUX_ON_DEVICE_BUILD" = "true" ]; then
        termux_setup_python_pip
        pip install pyyaml
    else
        pip install --break-system-packages pyyaml
    fi
}

# ---------------- CONFIGURE (MESON) ----------------
termux_step_configure() {
    CPPFLAGS+=" -Wno-alloca"
    CFLAGS+=" $CPPFLAGS"
    CXXFLAGS+=" $CPPFLAGS"

    MESON_COMMON_FLAGS="\
        --prefix=$TERMUX_PREFIX \
        -Ddefault_targets=i386-softmmu \
        -Dopengl=enabled \
        -Degl=enabled \
        -Dglx=enabled \
        -Dsdl=enabled \
        -Dgtk=disabled \
        -Dvte=disabled \
        -Dvnc=disabled \
        -Dxen=disabled \
        -Dxen_pci_passthrough=disabled \
        -Dhvf=disabled \
        -Dwhpx=disabled \
        -Dsnappy=disabled \
        -Dlzfse=disabled \
        -Dseccomp=disabled \
        -Dvhost_user=disabled \
        -Dvhost_user_blk_server=disabled \
        -Dguest_agent=disabled \
        -Dtrace_backends=nop \
        -Dstack_protector=disabled \
        -Dwerror=false \
        -Db_c_args=-DXBOX=1,-DANDROID \
        -Db_cpp_args=-DXBOX=1,-DANDROID"

    if [ "$TERMUX_ON_DEVICE_BUILD" = "true" ]; then
        # On-device build: no cross file
        LDFLAGS+=" -landroid-shmem -llog"
        meson setup build $MESON_COMMON_FLAGS
    else
        # Host/cross build
        meson setup build $MESON_COMMON_FLAGS --cross-file=$TERMUX_MESON_CROSSFILE
    fi
}

# ---------------- BUILD ----------------
termux_step_make() {
    ninja -C build -j$(nproc) qemu-system-i386

    mkdir -p dist
    mv build/qemu-system-i386 dist/xemu

    # Download BIOS/HDD images
    termux_download \
        "https://archive.org/download/xemustarter/XEMU%20FILES.zip/XEMU%20FILES%2FBoot%20ROM%2Fmcpx_1.0.bin" \
        dist/mcpx_1.0.bin \
        e99e3a772bf5f5d262786aee895664eb96136196e37732fe66e14ae062f20335

    termux_download \
        "https://archive.org/download/xemustarter/XEMU%20FILES.zip/XEMU%20FILES%2FBIOS%2FComplex_4627v1.03.bin" \
        dist/4627v1.03.bin \
        1de4c87effe40d44f95581d204f9fa0600fbd5fe2171692316dcf97af0f4113f

    termux_download \
        "https://github.com/xemu-project/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip" \
        dist/xbox_hdd.qcow2.zip \
        d9f5a4c1224ff24cf9066067bda70cc8b9c874ea22b9c542eb2edbfc4621bb39

    unzip -o dist/xbox_hdd.qcow2.zip -d dist
}

# ---------------- INSTALL ----------------
termux_step_make_install() {
    install -Dm755 dist/xemu "$TERMUX_PREFIX/bin/xemu"
    install -Dm644 dist/*.bin "$TERMUX_PREFIX/share/xemu"
    install -Dm644 dist/xbox_hdd.qcow2 "$TERMUX_PREFIX/share/xemu"
}
