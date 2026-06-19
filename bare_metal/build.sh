#!/bin/bash
set -e

# 1. Klasöre Giriş
cd "$(dirname "$0")"

ARCH_DIR="kernel/arch/x86_64"
KERNEL_DIR="kernel"

# 2. Temizlik (Eskiler gitsin)
rm -f *.o myos myos.iso
rm -rf isodir

# 3. Assembly Dosyalarını Derle
i686-elf-as "$ARCH_DIR/crti.s" -o crti.o
i686-elf-as "$ARCH_DIR/crtn.s" -o crtn.o
i686-elf-as "$ARCH_DIR/boot.s" -o boot.o
i686-elf-as "$ARCH_DIR/gdt_flush.s" -o gdt_flush.o
i686-elf-as "$ARCH_DIR/idt_a.s" -o idt_a.o

# 4. C Dosyalarını Derle
i686-elf-gcc -c "$KERNEL_DIR/kernel.c" -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
i686-elf-gcc -c "$KERNEL_DIR/gdt.c" -o gdt.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
i686-elf-gcc -c "$KERNEL_DIR/idt.c" -o idt.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

# 5. Linkleme (Hiyerarşik Birleştirme)
i686-elf-gcc -T "$ARCH_DIR/linker.ld" -o myos -ffreestanding -O2 -nostdlib \
    crti.o \
    $(i686-elf-gcc -print-file-name=crtbegin.o) \
    boot.o \
    gdt.o \
    gdt_flush.o \
    idt.o \
    idt_a.o \
    kernel.o \
    $(i686-elf-gcc -print-file-name=crtend.o) \
    crtn.o \
    -lgcc

# 6. ISO ve QEMU
mkdir -p isodir/boot/grub
cp myos isodir/boot/myos
cp grub.cfg isodir/boot/grub/grub.cfg

i686-elf-grub-mkrescue -o myos.iso isodir
qemu-system-i386 -cdrom myos.iso
