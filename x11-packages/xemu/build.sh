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
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686, x86_64"

TERMUX_PKG_DEPENDS="at-spi2-core, brotli, fontconfig, freetype, fribidi, gdk-pixbuf, glib, harfbuzz, libandroid-shmem, libandroid-support, libbz2, libc++, libcairo, libdecor, libepoxy, libexpat, libffi, libgraphite, libiconv, libjpeg-turbo, libpcap, libpixman, libpng, libsamplerate, libslirp, libwayland, libx11, libxau, libxcb, libxcomposite, libxcursor, libxdamage, libxdmcp, libdecor, libxext, libxfixes, libxi, libxinerama, libxkbcommon, libxrandr, libxrender, libxss, mesa, openssl, pango, pcre2, sdl2, zlib"

TERMUX_PKG_BUILD_DEPENDS="gtk3, libepoxy, libglvnd-dev, libpcap, libpixman, libsamplerate, libslirp, libtasn1, sdl2, vulkan-headers, xorgproto"

# ---------------- SOURCE ----------------
termux_step_get_source() {
	mkdir -p "$TERMUX_PKG_SRCDIR"
	cd "$TERMUX_PKG_SRCDIR"
	git clone https://github.com/xemu-project/xemu
	cd xemu
	git submodule update --init --recursive
	mv * .* ../
}
# ---------------- PRE-CONFIGURE ----------------
termux_step_pre_configure() {
	termux_setup_meson
	termux_setup_ninja
	termux_setup_python_pip
	pip install --upgrade pyyaml
}

# ---------------- CONFIGURE (MESON) ----------------
termux_step_configure() {
	CFLAGS+=" -DANDROID -DEGL_NO_X11 -DXBOX=1"
	CXXFLAGS+=" $CFLAGS"
	LDFLAGS+=" -llog -landroid-shmem"

	meson setup build \
		--prefix=$TERMUX_PREFIX \
		--cross-file=$TERMUX_MESON_CROSSFILE \
		-Ddefault_targets=i386-softmmu \
		-Dopengl=enabled \
		-Degl=enabled \
		-Dglx=disabled \
		-Dsdl=enabled \
		-Dgtk=disabled \
		-Dvte=disabled \
		-Dvnc=disabled \
		-Dvnc_sasl=disabled \
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
		-Db_c_args="-DXBOX=1 -DANDROID -DEGL_NO_X11" \
		-Db_cpp_args="-DXBOX=1 -DANDROID -DEGL_NO_X11"
}

# ---------------- BUILD ----------------
termux_step_make() {
	ninja -C build qemu-system-i386

	mkdir -p dist
	mv build/qemu-system-i386 dist/xemu

	python3 scripts/gen-license.py > dist/LICENSE.txt

	sed "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
		"$TERMUX_PKG_BUILDER_DIR/iso2xiso.in" > dist/iso2xiso
	chmod +x dist/iso2xiso
}

# ---------------- INSTALL ----------------
termux_step_make_install() {
	install -Dm755 dist/xemu "$TERMUX_PREFIX/libexec/xemu-bin"

	cat > "$TERMUX_PREFIX/bin/xemu" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
export QEMU_GL=egl
export SDL_RENDER_DRIVER=vulkan
export VK_ICD_FILENAMES=$PREFIX/share/vulkan/icd.d/turnip_icd.json
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
exec $PREFIX/libexec/xemu-bin -vulkan "$@"
EOF
	chmod +x "$TERMUX_PREFIX/bin/xemu"

	install -Dm755 dist/iso2xiso "$TERMUX_PREFIX/bin/iso2xiso"
	install -Dm644 dist/*.bin "$TERMUX_PREFIX/share/xemu" || true
	install -Dm644 dist/xbox_hdd.qcow2 "$TERMUX_PREFIX/share/xemu" || true
}

termux_step_install_license() {
	install -Dm644 dist/LICENSE.txt \
		"$TERMUX_PREFIX/share/doc/xemu/LICENSE"
}		mkdir -p _lib _setjmp-aarch64/private

		pushd _setjmp-aarch64
		for s in $TERMUX_PKG_BUILDER_DIR/setjmp-aarch64/{setjmp.S,private-*.h}; do
			cp "$s" .
		done
		$CC $CFLAGS $CPPFLAGS -I. setjmp.S -c
		$AR cru ../_lib/libandroid-setjmp.a setjmp.o
		popd

		LDFLAGS+=" -L$PWD/_lib -l:libandroid-setjmp.a"
	fi

	termux_setup_meson
	termux_setup_ninja
	termux_setup_python_pip
	pip install pyyaml
}

# ---------------- CONFIGURE (MESON) ----------------

termux_step_configure() {
	CFLAGS+=" -DANDROID -DEGL_NO_X11 -DXBOX=1"
	CXXFLAGS+=" $CFLAGS"
	LDFLAGS+=" -llog -landroid-shmem"

	meson setup build \
		--prefix=$TERMUX_PREFIX \
		--cross-file=$TERMUX_MESON_CROSSFILE \
		-Ddefault_targets=i386-softmmu \
		-Dopengl=enabled \
		-Degl=enabled \
		-Dglx=disabled \
		-Dsdl=enabled \
		-Dgtk=disabled \
		-Dvte=disabled \
		-Dvnc=disabled \
		-Dvnc_sasl=disabled \
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
		-Db_c_args="-DXBOX=1 -DANDROID -DEGL_NO_X11" \
		-Db_cpp_args="-DXBOX=1 -DANDROID -DEGL_NO_X11"
}

# ---------------- BUILD ----------------

termux_step_make() {
	ninja -C build qemu-system-i386

	mkdir -p dist
	mv build/qemu-system-i386 dist/xemu

	python3 scripts/gen-license.py > dist/LICENSE.txt

	sed "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
		"$TERMUX_PKG_BUILDER_DIR/iso2xiso.in" > dist/iso2xiso
	chmod +x dist/iso2xiso

	termux_download \
	"https://archive.org/download/xemustarter/XEMU%20FILES.zip/XEMU%20FILES%2FBoot%20ROM%20Image%2Fmcpx_1.0.bin" \
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
	install -Dm755 dist/xemu "$TERMUX_PREFIX/libexec/xemu-bin"

	cat > "$TERMUX_PREFIX/bin/xemu" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
export QEMU_GL=egl
export SDL_RENDER_DRIVER=vulkan
export VK_ICD_FILENAMES=$PREFIX/share/vulkan/icd.d/turnip_icd.json
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
exec $PREFIX/libexec/xemu-bin -vulkan "$@"
EOF
	chmod +x "$TERMUX_PREFIX/bin/xemu"

	install -Dm755 dist/iso2xiso "$TERMUX_PREFIX/bin/iso2xiso"
	install -Dm644 dist/*.bin "$TERMUX_PREFIX/share/xemu"
	install -Dm644 dist/xbox_hdd.qcow2 "$TERMUX_PREFIX/share/xemu"
}

termux_step_install_license() {
	install -Dm644 dist/LICENSE.txt \
		"$TERMUX_PREFIX/share/doc/xemu/LICENSE"
}
