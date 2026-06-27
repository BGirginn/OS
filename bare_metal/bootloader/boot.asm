[org 0x7c00]         ; Donanımsal Zorunluluk: BIOS bizi RAM'de bu adrese yükler. Biz de o yüzden yazma işleminin bu adresten başlamasını sağlıyoruz
                    ; Kod içindeki tüm etiketlerin (labels) adresi buna göre hesaplanır.

bits 16              ; İşlemci ilk açıldığında 16-bit Real Mode'dadır. Donanımı buna göre uyarıyoruz.

start:
    ; --- EN BAŞTAKİ ZORUNLULUK: BIOS'UN VERDİĞİ SÜRÜCÜ NUMARASINI KORUMA ---
    ; BIOS'un bilgisayarı açarken DL register'ına koyduğu "Boot Sürücü Numarasını" kaybetmemek için 
    ; daha hiçbir işlem yapmadan RAM'deki BOOT_DRIVE odamıza saklıyoruz.
    mov [BOOT_DRIVE], dl

    ; --- PARÇA 1: DONANIM TEMİZLİĞİ VE GARANTİYE ALMA ---
    ; BIOS bizi başlattığında CS (Code Segment) dahil segment register'larında çöp değerler olabilir.
    ; CS register'ını temizlemenin tek yolu bir "Far Jump" (Uzak Atlama) yapmaktır.
    jmp 0x0000:init_segments  ; code segment registerini 0 yap temizle sonra da init_segments e atla

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
    mov si, boot_msg  ; si bir adresi işaret etmek için kullanılan ana okuyucudur
    call print_string

    ; --- YENİ EKLENEN PARÇA: KERNEL'I DİSKTEN RAM'E ÇAĞIRMA ---
    ; MBR alanı dolmak üzere olduğu için diskimizin 2. sektöründen itibaren duracak olan 
    ; asıl Kernel kodlarımızı RAM'in güvenli bir bölgesi olan 0x8000 adresine yüklüyoruz.
    mov bx, 0x8000        ; Diskten okunacak veriler RAM'de 0x8000 adresine yazılacak (Kernel Başlangıcı)
    mov dh, 2             ; Diskten peş peşe 2 sektör (1024 bayt) okumak istediğimizi belirtiyoruz
    mov dl, [BOOT_DRIVE]  ; Sakladığımız orijinal disk numarasını DL register'ına geri yüklüyoruz
    call disk_load        ; Disk okuma fonksiyonumuzu çağırıyoruz

    ; Eğer disk başarıyla okunduysa, şimdilik test amaçlı işlemciyi burada kilitleyip çıktıyı görelim.
    ; Bir sonraki aşamada buraya 32-bit ve 64-bit vites yükseltme kodları gelecek.
    jmp hang

hang:
    jmp hang         ; Sonsuz Döngü: İşlemcinin çöp kodları yürütüp çökmesini (Triple Fault)
                    ; engellemek için onu burada güvenli bir şekilde kilitliyoruz.

; --- PARÇA 4: BIOS EKRAN FONKSİYONU (YARDIMCI KOD) ---
; BIOS'un bize sunduğu ekran kesmesini (Interrupt 0x10) kullanarak ekrana karakter basan fonksiyon.
print_string:
    mov ah, 0x0e     ; AH = 0x0E -> BIOS Teletype (Ekrana karakter basma modu)  ah acc in high 8 bitidir
.loop:
    lodsb            ; SI'nin işaret ettiği adresteki 1 baytı AL'ye yükle ve SI'yi 1 arttır.
    cmp al, 0        ; Karakter 0 mı? (String sonu - Null Terminator kontrolü)  al acc nin low 8 bitidir
    je .done         ; Eğer 0 ise metin bitmiştir, fonksiyondan çık.  je jump if equal
    int 0x10         ; BIOS ekran kesmesini tetikle (AL içindeki karakteri ekrana basar).
    jmp .loop        ; Sonraki karakter için döngüye devam et.
.done:
    ret              ; Çağrılan yere geri dön.

; --- YENİ EKLENEN PARÇA: DİSKTEN VERİ OKUYAN AMALE FONKSİYON ---
; Donanımın (Disk Denetleyicisinin) int 0x13 telefon numarasını tetikleyerek sektör okuyan fonksiyon.
disk_load:
    push dx          ; DH içindeki sektör sayısı bilgisini korumak adına tüm DX register'ını yığına (stack) saklıyoruz
    
    mov ah, 0x02     ; AH = 0x02 -> BIOS Disk Okuma Modu parametresidir
    mov al, dh       ; AL = Okunacak sektör sayısı (DH'deki 2 sektör talebini AL'ye kopyaladık)
    mov ch, 0x00     ; CH = Silindir 0 (Cylinder 0)
    mov dh, 0x00     ; DH = Kafa 0 (Head 0) - Sürücü numarası olan DL'yi ellemedik, o hala hazır duruyor
    mov cl, 0x02     ; CL = Sektör 2 (Sector 2) -> Sektör sayımı katı kural olarak 1'den başlar. 1'de biz varız, 2'den okuyoruz.

    int 0x13         ; BIOS Disk Kesmesini tetikle! Donanım çipi diski okuyup BX'deki 0x8000 adresine yazmaya başlar.

    ; --- DONANIMSAL HATA DENETİMLERİ ---
    jc disk_error    ; Eğer disk okunurken donanımsal bir arıza çıkarsa, BIOS işlemcinin gizli Carry Flag (CF) bitini 1 yapar.
                    ; jc (Jump if Carry) komutu hata varsa bizi doğrudan disk_error etiketine fırlatır.

    pop dx           ; Yığına (stack) sakladığımız orijinal DX değerimizi (DH = 2) geri kurtarıyoruz
    cmp dh, al       ; AL içinde BIOS'un gerçekten kaç sektör okuduğu yazar. İstediğimiz (DH) ile okunan (AL) eşit mi diye bakıyoruz.
    jne disk_error   ; Eğer eşit değilse (Jump if Not Equal) donanım eksik okumuştur, disk_error'a zıpla.
    ret

disk_error:
    mov si, error_msg
    call print_string
    jmp hang

; --- DATA (VERİ) ALANI ---
; db = Define Byte. 13 = Satır Başı (CR), 10 = Alt Satır (LF), 0 = Metin Sonu (Null)
BOOT_DRIVE db 0     ; Sürücü numarasını geçici olarak hafızada kilitleyeceğimiz 1 baytlık hücre
boot_msg db "Bora OS 64-bit Bootloader Yukleniyor...", 13, 10, 0
error_msg db "Hata: Disk Sektorleri Okunamadi!", 13, 10, 0

; --- PARÇA 5: MBR ZORUNLULUKLARI ---
; $  = Şu anki satırın adresi
; $$ = Kodun başlangıç adresi (0x7C00)
; ($ - $$) = Yazdığımız kodun toplam bayt boyutu.
times 510 - ($ - $$) db 0   ; Dosyayı tam olarak 510. bayta kadar 0 ile doldurur. bios kesin kural: bootloader 512 bayt olmak zorunda

dw 0xaa55                   ; 511 ve 512. baytlar BIOS'un bu diski "Önyüklenebilir (Bootable)" olarak tanıması için gereken sihirli imza 

; =========================================================================
; --- DISKTEKI 1. SEKTÖR (MBR) BİTTİ. ŞİMDİ SIFIRDAN YAZILAN 2. SEKTÖRDEYİZ ---
; =========================================================================
; İlerleyen aşamalarda buraya senin asıl C dilindeki Kernel binary kodun eklenecek.
; Şimdilik disk okumanın pürüzsüz çalıştığını kanıtlamak amacıyla buraya sahte bir imza (veri) koyuyoruz.
kernel_baslangic_testi:
    db "Eger bu sahte test verisi RAM'e yuklendiyse donanim disk okumayi basarmis demektir!", 0

times 512 db 0 ; Sahte olan bu 2. sektörü de tam 512 bayta tamamlıyoruz ki disk geometrimiz bozulmasın.