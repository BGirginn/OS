[org 0x7c00]         ; Donanımsal Zorunluluk: BIOS bizi RAM'de bu adrese yükler.
                    ; Kod içindeki tüm etiketlerin (labels) adresi buna göre hesaplanır.

bits 16              ; İşlemci ilk açıldığında 16-bit Real Mode'dadır. Donanımı buna göre uyarıyoruz.

start:
    ; --- PARÇA 1: DONANIM TEMİZLİĞİ VE GARANTİYE ALMA ---
    ; BIOS bizi başlattığında CS (Code Segment) dahil segment register'larında çöp değerler olabilir.
    ; CS register'ını temizlemenin tek yolu bir "Far Jump" (Uzak Atlama) yapmaktır.
    jmp 0x0000:init_segments

init_segments:
    xor ax, ax       ; AX register'ını sıfırla (AX = 0)
    mov ds, ax       ; Data Segment = 0 (Değişkenlerimizin RAM'de doğru okunması için)
    mov es, ax       ; Extra Segment = 0

    ; --- PARÇA 2: YIĞIN (STACK) KURULUMU ---
    ; İleride fonksiyon çağırabilmemiz (call/ret) veya veri saklayabilmemiz (push/pop) için
    ; RAM üzerinde güvenli ve çakışmayacak bir Yığın alanı kurmak zorundayız.
    mov ss, ax       ; Stack Segment = 0
    mov sp, 0x7c00   ; Stack Pointer = 0x7C00
                    ; Yığın (Stack) RAM'de aşağıya doğru (0x7C00 -> 0x0000) büyür.
                    ; Bizim bootloader kodumuz ise yukarıya doğru (0x7C00 -> 0x7E00) yer kaplar.
                    ; Böylece yığın alanı ile kodlarımız asla birbirini ezmez!

    ; --- PARÇA 3: EKRANA İLK YAZIYI BASMA ---
    ; Ekrana yazı basmak için SI (Source Index) register'ına metnimizin adresini veriyoruz.
    mov si, boot_msg
    call print_string

hang:
    jmp hang         ; Sonsuz Döngü: İşlemcinin çöp kodları yürütüp çökmesini (Triple Fault)
                    ; engellemek için onu burada güvenli bir şekilde kilitliyoruz.

; --- PARÇA 4: BIOS EKRAN FONKSİYONU (YARDIMCI KOD) ---
; BIOS'un bize sunduğu ekran kesmesini (Interrupt 0x10) kullanarak ekrana karakter basan fonksiyon.
print_string:
    mov ah, 0x0e     ; AH = 0x0E -> BIOS Teletype (Ekrana karakter basma modu)
.loop:
    lodsb            ; SI'nin işaret ettiği adresteki 1 baytı AL'ye yükle ve SI'yi 1 arttır.
    cmp al, 0        ; Karakter 0 mı? (String sonu - Null Terminator kontrolü)
    je .done         ; Eğer 0 ise metin bitmiştir, fonksiyondan çık.
    int 0x10         ; BIOS ekran kesmesini tetikle (AL içindeki karakteri ekrana basar).
    jmp .loop        ; Sonraki karakter için döngüye devam et.
.done:
    ret              ; Çağrılan yere geri dön.

; --- DATA (VERİ) ALANI ---
; db = Define Byte. 13 = Satır Başı (CR), 10 = Alt Satır (LF), 0 = Metin Sonu (Null)
boot_msg db "Bora OS 64-bit Bootloader Yukleniyor...", 13, 10, 0

; --- PARÇA 5: MBR ZORUNLULUKLARI ---
; $  = Şu anki satırın adresi
; $$ = Kodun başlangıç adresi (0x7C00)
; ($ - $$) = Yazdığımız kodun toplam bayt boyutu.
times 510 - ($ - $$) db 0   ; Dosyayı tam olarak 510. bayta kadar 0 ile doldurur.

dw 0xaa55                   ; 511 ve 512. baytlar. BIOS'un bu diski "Önklenebilir (Bootable)"
                            ; olarak tanıması için gereken sihirli imza (Magic Number).
