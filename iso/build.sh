#!/usr/bin/env bash
set -euo pipefail

# Configuration
DEBIAN_RELEASE="bookworm"
MIRROR="http://deb.debian.org/debian"
OUTDIR="$(pwd)/rootfs"
ISODIR="$(pwd)/iso"
ISO_NAME="../drupe-0.1.iso"

echo "[+] Building Drupe OS rootfs for live ISO"

# Install dependencies if not present
if ! command -v debootstrap >/dev/null; then
    echo "Installing debootstrap..."
    sudo apt-get update
    sudo apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools
fi

# Clean previous build
sudo rm -rf "${OUTDIR}" "${ISODIR}/live"
mkdir -p "${OUTDIR}" "${ISODIR}/live"

# Bootstrap minimal Debian system
echo "[+] Running debootstrap..."
sudo debootstrap --arch=amd64 --variant=minbase \
    --include=systemd-sysv,live-boot \
    "${DEBIAN_RELEASE}" "${OUTDIR}" "${MIRROR}"

# Copy package list and install inside chroot
echo "[+] Installing packages from packages.txt..."
sudo cp ../packages.txt "${OUTDIR}/tmp/packages.txt"
sudo chroot "${OUTDIR}" /bin/bash -c \
    "apt-get update && xargs -a /tmp/packages.txt apt-get install -y --no-install-recommends && apt-get clean"

# Add Drupe-specific files
echo "[+] Configuring Drupe OS..."
sudo mkdir -p "${OUTDIR}/usr/share/drupe"
sudo cp ../docs/FIRST-STEPS.md "${OUTDIR}/usr/share/drupe/"

# Set up live user
sudo chroot "${OUTDIR}" /bin/bash -c \
    "useradd -m -s /bin/bash -G sudo live-user && \
     echo 'live-user:live' | chpasswd && \
     echo 'root:root' | chpasswd"

# Copy custom configurations (to be added later)
# sudo cp -r ../rootfs/etc "${OUTDIR}/"

# Create the filesystem.squashfs
echo "[+] Creating squashfs..."
sudo mksquashfs "${OUTDIR}" "${ISODIR}/live/filesystem.squashfs" -comp xz -e boot

# Build the ISO
echo "[+] Building bootable ISO..."
cd "${ISODIR}"

# Create GRUB configuration
cat > grub.cfg << 'EOF'
set default="0"
set timeout=5

menuentry "Drupe OS (Live)" {
    linux /live/vmlinuz boot=live components quiet splash
    initrd /live/initrd.img
}
EOF

# Build the ISO
sudo xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "DRUPE_LIVE" \
    -eltorito-boot boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-catalog boot/grub/boot.cat \
    -output "${ISO_NAME}" \
    -graft-points \
    live/filesystem.squashfs=/live/filesystem.squashfs \
    boot/grub/bios.img=/usr/lib/grub/i386-pc/boot_hybrid.img \
    boot/grub/efi.img=/usr/lib/grub/x86_64-efi/efi.img \
    grub.cfg=/grub.cfg

echo "[+] ISO built: ${ISO_NAME}"
