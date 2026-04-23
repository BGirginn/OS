/* GRUB bize geçici bir GDT verdi ama o emanet bir ev gibi. Kendi evimizi kurmak için 3 parçaya ihtiyacımız var:
GDT Kaydı (Entry): Her bir hafıza diliminin (Kod, Veri vb.) tanımı.
GDT İşaretçisi (Pointer): İşlemciye "GDT tablom tam olarak şurada" diyen özel bir yapı.
Assembly Yükleyici: İşlemciye bu yeni tabloyu kullanmasını emreden küçük bir kod. */


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