gdt_start:  /* Null Descriptor. x86 da mimari donanımsal olarak ilk kapının indeks 0 ın tamamen 0 olmasını zorunlu kılar. 
işlemci korumalı modda iken hatalı ya da boş bir pointer herhangi bir sebep ile gelirse 0. kapıya denk gelir ve donanım ile sistemi korur */
    dd 0x0    ; 4 baytlık sıfır
    dd 0x0    ; 4 baytlık sıfır daha (Toplam 8 bayt sıfır)

gdt_code:  /* code segment (cs) totalde 64 bit yani 8 byte tan oluşuyor ve hangi bitlerin ne olduğu alttaki sıraya göre yapılıyor */
    dw 0xffff    ; Bayt 0 ve 1 | Şeritteki 0 - 15. bitler: Limit'in 1. kısmıdır (Limitin alabileceği maksimum boyut sınırı).
    dw 0x0       ; Bayt 2 ve 3 | Şeritteki 16 - 31. bitler: Base'in 1. kısmıdır (0 - 15. bitleri tutar). segmentin ram üzerinde nereden başladığının adresinin ilk kısmı
    db 0x0       ; Bayt 4      | Şeritteki 32 - 39. bitler: Base'in 2. kısmıdır (16 - 23. bitleri tutar). başlama adresinin ikinci kısmı
    db 0x9a      ; Bayt 5      | Şeritteki 40 - 47. bitler: Erişim (Access) Byte'ıdır (Ring 0 ve Kod iznini açar). cs ye verilecek izinler ayarlanır
    db 0xcf      ; Bayt 6      | Şeritteki 48 - 51. bitler: Limit'in son kısmı (16-19) | 52 - 55. bitler: Mod Bayrakları (Flags). cpu modu ve çalışma karakteristiğini belirler
    db 0x0       ; Bayt 7      | Şeritteki 56 - 63. bitler: Base'in 3. ve son kısmıdır (24 - 31. bitleri tamamlar).