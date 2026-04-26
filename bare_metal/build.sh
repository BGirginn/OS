# 1. Klasöre Giriş
cd /Users/brgirgin/Desktop/OS/bare_metal

# 2. Temizlik (Opsiyonel: Eski .o dosyaları kafa karıştırmasın)
rm -f *.o crt/*.o myos myos.iso

# 3. Assembly Dosyalarını Derle
i686-elf-as crt/crti.s -o crt/crti.o
i686-elf-as crt/crtn.s -o crt/crtn.o
i686-elf-as boot.s -o boot.o
i686-elf-as gdt_flush.s -o gdt_flush.o      # <--- YENİ: GDT Assembly Tüneli

# 4. C Dosyalarını Derle
i686-elf-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
i686-elf-gcc -c gdt.c -o gdt.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra        # <--- YENİ: GDT C Mantığı

# 5. Linkleme (Büyük Birleştirme)
# Sıralama: crti -> crtbegin -> boot -> gdt -> kernel -> crtend -> crtn
i686-elf-gcc -T linker.ld -o myos -ffreestanding -O2 -nostdlib \
    crt/crti.o \
    $(i686-elf-gcc -print-file-name=crtbegin.o) \
    boot.o \
    gdt.o \
    gdt_flush.o \
    kernel.o \
    $(i686-elf-gcc -print-file-name=crtend.o) \
    crt/crtn.o \
    -lgcc

# 6. ISO Hazırlığı
mkdir -p isodir/boot/grub
cp myos isodir/boot/myos
cp grub.cfg isodir/boot/grub/grub.cfg

# 7. ISO Oluşturma ve QEMU Ateşleme
i686-elf-grub-mkrescue -o myos.iso isodir
qemu-system-i386 -cdrom myos.iso