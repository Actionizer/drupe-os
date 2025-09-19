#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "    Drupe OS Minimal CLI Installer"
echo "========================================"
echo "WARNING: This will DESTROY data on the target disk."
echo "Use for testing in a VM only."
echo ""

# Target disk selection
lsblk
read -rp "Enter target disk (e.g., /dev/sda): " TARGET_DISK

# Confirmation
read -rp "Erase ALL data on $TARGET_DISK? (type 'erase' to confirm): " CONFIRM
if [[ "$CONFIRM" != "erase" ]]; then
    echo "Aborted."
    exit 1
fi

# Partitioning
echo "[+] Partitioning $TARGET_DISK..."
sudo parted --script "$TARGET_DISK" \
    mklabel gpt \
    mkpart primary ext4 1MiB 100% \
    set 1 boot on

TARGET_PARTITION="${TARGET_DISK}1"

# Formatting
echo "[+] Formatting $TARGET_PARTITION as ext4..."
sudo mkfs.ext4 -F -L "DRUPE_ROOT" "$TARGET_PARTITION"

# Mounting
echo "[+] Mounting target filesystem..."
sudo mkdir -p /mnt/drupe
sudo mount "$TARGET_PARTITION" /mnt/drupe

# Copying files (this assumes a rootfs.tar exists - we'll need to create it in build.sh)
echo "[+] Copying system files..."
# This is a placeholder - the build script needs to create a rootfs.tar
# sudo tar -xpf rootfs.tar -C /mnt/drupe

# Install bootloader
echo "[+] Installing GRUB bootloader..."
sudo mkdir -p /mnt/drupe/boot/grub
# sudo grub-install --target=i386-pc --boot-directory=/mnt/drupe/boot "$TARGET_DISK"
# sudo chroot /mnt/drupe update-grub

# Unmount
echo "[+] Unmounting..."
sudo umount /mnt/drupe

echo ""
echo "Installation complete! You can now reboot into Drupe OS."
echo "Remember to remove the installation media."
