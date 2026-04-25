/* GRUB bize geçici bir GDT verdi ama o emanet bir ev gibi. Kendi evimizi kurmak için 3 parçaya ihtiyacımız var:
GDT Kaydı (Entry): Her bir hafıza diliminin (Kod, Veri vb.) tanımı.
GDT İşaretçisi (Pointer): İşlemciye "GDT tablom tam olarak şurada" diyen özel bir yapı.
Assembly Yükleyici: İşlemciye bu yeni tabloyu kullanmasını emreden küçük bir kod. */

struct gdt_entry gdt[3];  /* buradaki üç 0 1 2 den gelen 3 adet anlamına geliyor. 3 adet gdt_entry oluşturuyor 3 farklı gdt var.
gdt[0] = boş segment burası hep boş kalır.
gtd[1] = kod kısmı burası sadece okunabilir. 
gdt[2] = veri kısmı okunabilir yazılabilir. */

/* Sen fonksiyonun içinde gdt[num].limit_low yazdığında, işlemci ye num kutusunun içine hangi sayı gelirse, git o numaralı kata ve oradaki limit_low çekmecesini aç komutu verir */

/* base bizim ram bölgemizin başlangıcı limit ise ram bölgemizin ne kadar olacağıdır */
struct gdt_entry {
    unsigned short limit_low;    // Limit'in yani ram boyutunun sayısal değerinin ilk 16 biti (normalde 20 bittir toplam)
    unsigned short base_low;     // Başlangıç adresinin ilk 16 biti (en sağ yani en düşük 16 bit)
    unsigned char  base_middle;  // Başlangıç adresinin sonraki 8 biti (ortadaki 8 bit)
    unsigned char  access;       // Erişim hakları (En önemli kısım!)
    unsigned char  granularity;  // Limit'in geri kalanı (kalan 4 bit yani) ve ayarlar
    unsigned char  base_high;    // Başlangıç adresinin son 8 biti (en soldaki yani en yüksek değerlikli 8 bit)
} __attribute__((packed));
/*__attribute__((packed)) demezsen, derleyici (GCC) hızı artırmak için bu değişkenlerin arasına gizli boşluklar koyabilir.
Ama işlemci bu veriyi tam olarak 8 bayt (boşluksuz) bekler. Bu yüzden "paketle" diyoruz.*/

void gdt_set_gate(int num, unsigned long base, unsigned long limit, unsigned char access, unsigned char gran) 
{
    
    /* 1. Base (Adres) Parçalama: 32 bitlik adresi 3 çekmeceye bölüyoruz */
    gdt[num].base_low    = (base & 0xFFFF);        // İlk 16 bit (Maske ile kes-al)
    gdt[num].base_middle = (base >> 16) & 0xFF;    // Orta 8 bit (16 it, sonra kes-al)
    gdt[num].base_high   = (base >> 24) & 0xFF;    // Son 8 bit (24 it, sonra kes-al)

    /* 2. Limit (Boyut) Parçalama: Toplam 20 bitlik limitin ilk 16'sı buraya */
    gdt[num].limit_low   = (limit & 0xFFFF);

    /* 3. Granularity: Hem limitin kalan 4 bitini hem de ayarları buraya sıkıştırıyoruz */
    gdt[num].granularity = ((limit >> 16) & 0x0F); // Limitin son 4 bitini aldık
    gdt[num].granularity |= (gran & 0xF0);         // Üstüne gran ayarlarını "OR" ile yapıştırdık

    /* 4. Erişim Hakları */
    gdt[num].access      = access;
}

struct gdt_ptr {
    unsigned short limit; // Tablonun toplam boyutu (Bayt cinsinden - 1). Bu yukardaki limitten farklı buradaki boyut tutuyor yukardaki ise ilk 16 biti.
    unsigned int   base;  // Tablonun başladığı tam adres
} __attribute__((packed));

struct gdt_ptr gp; // Bu bizim işlemciye vereceğimiz "kartvizit" olacak. structtan eleman üretmek için bu gp yerine gp1 dersen gp1.limit, gp2.limit gibi birden fazla üretebilirsin.    

void gdt_install() {
    /* 1. GDT İşaretçisini (gp) hazırlayalım */
    gp.limit = (sizeof(struct gdt_entry) * 3) - 1;
    gp.base  = (unsigned int)&gdt;

    /* 2. Kapıları tek tek inşa edelim */
    
    // 0. Kapı: Boş (Zorunlu)
    gdt_set_gate(0, 0, 0, 0, 0);

    // 1. Kapı: Kod Segmenti (0'dan başla, 4GB, Kod erişimi, 32-bit sayfalama)
    gdt_set_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF);

    // 2. Kapı: Veri Segmenti (0'dan başla, 4GB, Veri erişimi, 32-bit sayfalama)
    gdt_set_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF);

    /* standardı bu şekilde ondan bir nevi sabit bu */

    /* 3. ŞİMDİ NE OLACAK? */
    // Buraya kadar her şey C dilindeydi. 
    // Ama işlemciye "Bu GDT'yi yükle" demek için 
    // Assembly dilinde 'lgdt' komutunu kullanmamız gerekecek.
}