all: out/initramfs.cpio.gz out/vmlinuz-lts

clean:
	rm -rf ext
	rm -rf fs
	rm -rf out

run: all
	qemu-system-x86_64 -kernel out/vmlinuz-lts -initrd out/initramfs.cpio.gz -m 1G 


fs/init: init fs
	cp $< $@
	chmod +x $@

fs/bin/sh: fs
	ln -s /bin/busybox $@

fs/etc/passwd: fs
	touch $@


fs/bin/busybox: ext/busybox fs
	cp $< $@
	chmod +x $@

fs/bin/pwsh: ext/powershell.apk fs
	tar -zxvf $< -C fs/bin

fs/bin/icuinfo: ext/icu.apk fs
	tar -zxvf $< -C fs

fs/usr/share/icu: ext/icu-data-en.apk fs
	tar -zxvf $< -C fs

fs/usr/lib/libicudata.so.71: ext/icu-libs.apk fs
	tar -zxvf $< -C fs

fs/usr/lib/libgcc_s.so.1: ext/libgcc.apk fs
	tar -zxvf $< -C fs

fs/usr/lib/libstdc++.so.6: ext/libstdc++.apk fs
	tar -zxvf $< -C fs

fs/lib/libc.musl-x86_64.so.1: ext/musl.apk fs
	tar -zxvf $< -C fs


ext:
	mkdir ext

ext/busybox: ext
	wget -O $@ https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox

ext/powershell.apk: ext
	wget -O $@ https://github.com/PowerShell/PowerShell/releases/download/v7.2.6/powershell-7.2.6-linux-alpine-x64.tar.gz

ext/icu.apk: ext
	wget -O $@ https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/icu-71.1-r2.apk

ext/icu-data-en.apk: ext
	wget -O $@ https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/icu-data-en-71.1-r2.apk

ext/icu-libs.apk: ext
	wget -O $@ https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/icu-libs-71.1-r2.apk

ext/libgcc.apk: ext
	wget -O $@ https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/libgcc-11.2.1_git20220219-r2.apk

ext/libstdc++.apk: ext
	wget -O $@ https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/libstdc%2B%2B-11.2.1_git20220219-r2.apk

ext/musl.apk: ext
	wget -O $@ https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/musl-1.2.3-r0.apk


fs:
	mkdir -p fs/bin
	mkdir -p fs/etc
	mkdir -p fs/proc
	mkdir -p fs/sys
	mkdir -p fs/tmp


out:
	mkdir -p out

out/vmlinuz-lts: out
	wget -O $@ https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/x86_64/netboot/vmlinuz-lts

out/initramfs.cpio.gz: out/initramfs.cpio
	gzip < $< > $@

out/initramfs.cpio: out \
	fs/init \
	fs/etc/passwd \
	fs/bin/sh \
	fs/bin/busybox \
	fs/bin/pwsh \
	fs/bin/icuinfo \
	fs/usr/share/icu \
	fs/usr/lib/libicudata.so.71 \
	fs/usr/lib/libgcc_s.so.1 \
	fs/usr/lib/libstdc++.so.6 \
	fs/lib/libc.musl-x86_64.so.1
	cd fs; find . | cpio -o -H newc > ../out/initramfs.cpio
