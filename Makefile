.PHONY: all build iso test clean

all: iso

build:
	@echo "Building rootfs..."
	cd iso && sudo bash build.sh

iso: build
	@echo "ISO built: drupe-0.1.iso"

test:
	@echo "Testing ISO in QEMU (512MB RAM)..."
	qemu-system-x86_64 -m 512 -cdrom drupe-0.1.iso -boot d -nographic -enable-kvm -snapshot

clean:
	sudo rm -rf rootfs iso/live/filesystem.squashfs drupe-0.1.iso
