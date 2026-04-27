/* IDT Giriş Yapısı: İşlemcinin "Telefon Çaldığında Nereye Bakayım?" dediği 8 baytlık kutu. */
/* mesela normalde sistem klavye çalışınca ne yapayım i bilmez biz ona öğretiyoruz bunları bu kısım sayesinde */
struct idt_entry {
    unsigned short base_lo;    // ISR fonksiyonun adresinin ilk yarısı (16 bit)
    unsigned short sel;        // Hangi kod segmentini kullanacağız? (Bizim GDT'deki 0x08)
    unsigned char  always0;    // Donanım böyle istiyor, her zaman 0.
    unsigned char  flags;      // Bu kapı kime açık? (Kullanıcıya mı, sadece çekirdeğe mi?)
    unsigned short base_hi;    // ISR fonksiyonun adresinin ikinci yarısı (16 bit)
} __attribute__((packed));

struct idt_ptr {
    unsigned short limit;      // Tablonun toplam uzunluğu boyutu
    unsigned int   base;       // Tablonun RAM'deki başlangıç adresi
} __attribute__((packed));

struct idt_entry idt[256];     // Bana RAM üzerinde peş peşe dizilmiş, her biri 8 bayt olan 256 tane kutu ayır. bunlara biz sonrasında hata kodlarını yazacağız bu bizim hata defterimiz
struct idt_ptr idtp;           // bu pointer bizi deftere götürecek olan adres pointerimiz

/* Bu fonksiyon, belirli bir kesme numarasına (num) hangi fonksiyonun (base) bakacağını ayarlar. */
void idt_set_gate(unsigned char num, unsigned long base, unsigned short sel, unsigned char flags) {
    // Adresi parçalayıp kutulara yerleştiriyoruz (GDT'deki mantığın aynısı)
    idt[num].base_lo = (base & 0xFFFF);
    idt[num].base_hi = (base >> 16) & 0xFFFF;

    idt[num].sel     = sel;
    idt[num].always0 = 0;
    idt[num].flags   = flags;
}

// Assembly dosyamızdaki (idt_a.s) o meşhur fonksiyonu içeri çağırıyoruz
extern void idt_load();

void idt_install() {
    /* 1. IDT İşaretçisini (idtp) hazırlayalım */
    // Limit: Tablonun toplam boyutu (Bayt cinsinden) - 1
    idtp.limit = (sizeof(struct idt_entry) * 256) - 1;
    // Base: Tablonun başladığı tam adres
    idtp.base  = (unsigned int)&idt;

    /* 2. Tüm tabloyu sıfırlayarak başlayalım (Temiz bir sayfa) */
    // Belleği manuel sıfırlamak yerine her gate'i 0 ile doldurabiliriz
    for (int i = 0; i < 256; i++) {
        idt_set_gate(i, 0, 0, 0);
    }

    /* 3. İleride buraya ISR (Hata yakalayıcı) kapılarını ekleyeceğiz */
    // Örnek: idt_set_gate(0, (unsigned)isr0, 0x08, 0x8E);

    /* 4. ŞİMDİ NE OLACAK? */
    // Hazırladığımız idtp yapısını işlemciye "yükle" (lidt) diyoruz.
    idt_load();
}