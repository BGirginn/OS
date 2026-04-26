# Eski (GRUB'dan kalan) ayarları siler ve senin ayarlarını işlemcinin her hücresine yayar.

.global gdt_flush    # C kodundan bu fonksiyona ulaşabilmek için sessionu global yaptık
.extern gp           # C'de tanımladığımız 'gp' (kartvizit) burada kullanacağız. başka bir dosyada gp diye değişken tanımladım bu o değişken demek. 
/* Başka bir gp tanımlı olamaz mesela başka yerde bu bir tür hata olur o yüzden nereden bulacak diye merak etme */

gdt_flush:
    lgdt (gp)        # 1. ADIM: İşlemciye GDT'nin yerini (gp) bildir. Git bu gp ismindeki değişkenin olduğu adresteki veriyi (6 baytlık kartviziti) oku" der
    # Senin RAM'de hazırladığın gp yapısındaki adresi ve limiti alır, işlemcinin içine kilitler. Artık işlemci nereye bakacağını bilir.

    mov $0x10, %ax   # 0x demek 16 bitlik demek 0*8 gdt0, 1*8 gdt1 2*8 gdt 2 burada da 0x10 demek 16 demek ve ax i gdt2 ye yolladık ax genel amaçla kullandığımız bir register türü 
    mov %ax, %ds     # buradaki ds es fs gs ss leri direkt ax e yollayarak gdt2 ye gönderiyoruz direkt gdt2 ye yollayamayız çalışmaz. ds (Data Segment): Normal değişkenler için.
    mov %ax, %es     # es, fs, gs: Ekstra veri alanları için.
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss     # ss (Stack Segment): Fonksiyonların dönüş adresleri ve yerel değişkenler (Yığın) için.

    # 3. ADIM: Kodlarımızın bulunduğu segmenti (0x08) aktif etmek için "Uzak Zıplama" yap.
    # Bu satır işlemcinin içindeki CS kaydını 0x08 (1 * 8) yapar.
    ljmp $0x08, $.flush  # burada sistemi okunabilir ve yazılabilir alandan sadece okunabilir kural sistemine geçirip sonra da .flush kodunu sıraya alıyorsun
    # Git 0x08 segmentine bak ve oradaki .flush etiketinin bulunduğu adrese zıpla." 
    # Eğer $ koymasaydık, işlemci .flush etiketinin olduğu yerdeki kodu "adres" sanıp saçma bir yere zıplamaya çalışırdı. Yani $ burada "buraya git" emrinin koordinatını kesinleştirir

.flush:
    ret              # C koduna geri dön! 
    