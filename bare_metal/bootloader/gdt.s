gdt_start:
    dd 0x0    ; 4 baytlık sıfır
    dd 0x0    ; 4 baytlık sıfır daha (Toplam 8 bayt sıfır)

gdt_code:
    dw 0xffff    ; Limit (0-15. bitler): 4 GB için maksimum sınır
    dw 0x0       ; Base (0-15. bitler): Segment 0x0000 adresinden başlıyor
    db 0x0       ; Base (16-23. bitler): 0
    db 0x9a      ; Access byte: Ring 0 (Kernel) ve Kod segmenti ayarı
    db 0xcf      ; Flags + Limit (16-19. bitler): 32-bit modu aktif etme ayarı
    db 0x0       ; Base (24-31. bitler): 0