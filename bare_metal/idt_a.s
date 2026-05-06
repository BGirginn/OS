/* IDTR dediğimiz şey idt için olan özel bir register. */
[GLOBAL idt_load]  /* idt_load ın harici dosyalar tarafından erişilebilir olmasını sağlar */
extern idtp           /* C'deki 'idtp' değişkenini buradan görebilelim. idt.c dosyasındaki idt_ptr olarak tanımlanan şey */

idt_load:
    lidt [idtp]       /* Köşeli parantez varsa idtp'nin kendisini değil, tuttuğu adresin gösterdiği yerdeki bilgiyi getirir.  */
    /* lidt komutu ise bu idt yani hataların bulunduğu tablo defter her ne ise onu onun başladığı adresi ve boyutunu idtr adlı özel register a yükler  */
    ret               /* C'ye geri dön */


%macro ISR_NOERRCODE 1  /* macro türünde bir kod bloğu ve ismi. isr_noerrcode dan başka bir şey de yapabilirdik. sondaki 1 de 1 adet değişkeni olacak demek (hata kodu sayısı burada)  */
    /* macro ile tanımlarsan ISR_ERRCODE 1 deki 1 onun kaç parametre alacağı olur. ISR_ERRCODE 1 dersen bu ilk parametre yerine 1 yazarak kodu kullan demek olur  */
    [GLOBAL isr%1]      /* değişkeni lgobal yapar. %1 dediğimiz şey ise bir değişken özel parametredir. bir tür placeholder gibi düşün */
    isr%1:
    cli               /* Yeni bir hata gelmesin, hattı meşgule al */
    push byte 0       /* Sahte hata kodu (C yapısı için) */
    push byte %1      /* Hata numarası (Örn: 0) */
    jmp isr_common_stub
%endmacro


ISR_NOERRCODE 0   /* üstte tanımlı makroyu dış parametre 0 olarak çağırıyoruz */
ISR_NOERRCODE 3   /* 3: Debug Kesmesi */
ISR_NOERRCODE 8   /* 8: Double Fault (Büyük sistem hatası) */

extern isr_handler    /* C tarafındaki asıl yönetici fonksiyon */

isr_common_stub:
    pusha             /* İşlemcinin o anki tüm register'larını pushlayıp verilerin kaybolmamasını sağlıyor    */
    
    mov ax, ds        /* bu komut sayesinde eski ds anahtar değerini kaybetmeyiz  */
    push eax          /* eax in içinde AX: EAX in son yarısı (16 bit). AH: AX'in üst yarısı (High). AL: AX'in alt yarısı (Low). var bunları pushlar */

    mov ax, 0x10      /* GDT'deki Kernel Veri Segmentine (0x10) geçiş yap. zaten data segmentte değil miyiz dersen de biz kernel data segmentteyiz  */
        /* ama sonrasında user data segment ekleneceği için (ya da eklendiği) doğru data segmentte olduğumuzdan emin olmamız lazım */
    mov ds, ax
    mov es, ax        /* yedekleme için extra data segment register */
    mov fs, ax        /* işlemcinin "belki lazım olur" diye koyduğu ekstra yardımcı gözlükler. */
    mov gs, ax        /* işlemcinin "belki lazım olur" diye koyduğu ekstra yardımcı gözlükler. */

    call isr_handler  /* C tarafındaki isr_handler(struct regs *r) fonksiyonuna git */

    pop eax           /* Orijinal veri segmentini geri yükle */
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    popa              /* Tüm genel register'ları (EAX, EBX...) geri yükle */
    add esp, 8        /* Stack'teki hata kodu ve numarasını temizle (2 adet 4 byte) */
    sti               /* Kesmeleri tekrar serbest bırak */
    iret              /* Kesme Öncesi Ana Programa Geri Dön! */
