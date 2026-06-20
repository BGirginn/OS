AS = i686-elf-as
CC = i686-elf-gcc
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra
ARCH_DIR = kernel/arch/x86_64
KERNEL_DIR = kernel

myos: crti.o boot.o gdt.o gdt_flush.o idt.o idt_a.o kernel.o crtn.o
	$(CC) -T $(ARCH_DIR)/linker.ld -o myos -ffreestanding -O2 -nostdlib crti.o boot.o gdt.o gdt_flush.o idt.o idt_a.o kernel.o crtn.o -lgcc

kernel.o: $(KERNEL_DIR)/kernel.c
	$(CC) -c $(KERNEL_DIR)/kernel.c -o kernel.o $(CFLAGS)

gdt.o: $(KERNEL_DIR)/gdt.c
	$(CC) -c $(KERNEL_DIR)/gdt.c -o gdt.o $(CFLAGS)

idt.o: $(KERNEL_DIR)/idt.c
	$(CC) -c $(KERNEL_DIR)/idt.c -o idt.o $(CFLAGS)

boot.o: $(ARCH_DIR)/boot.s
	$(AS) $(ARCH_DIR)/boot.s -o boot.o

gdt_flush.o: $(ARCH_DIR)/gdt_flush.s
	$(AS) $(ARCH_DIR)/gdt_flush.s -o gdt_flush.o

idt_a.o: $(ARCH_DIR)/idt_a.s
	$(AS) $(ARCH_DIR)/idt_a.s -o idt_a.o

crti.o: $(ARCH_DIR)/crti.s
	$(AS) $(ARCH_DIR)/crti.s -o crti.o

crtn.o: $(ARCH_DIR)/crtn.s
	$(AS) $(ARCH_DIR)/crtn.s -o crtn.o

iso: myos
	mkdir -p isodir/boot/grub
	cp myos isodir/boot/myos
	cp grub.cfg isodir/boot/grub/grub.cfg
	i686-elf-grub-mkrescue -o myos.iso isodir

run: iso
	qemu-system-i386 -cdrom myos.iso

clean:
	rm -f *.o myos myos.iso
	rm -rf isodir