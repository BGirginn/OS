; IDTR dediğimiz şey idt için olan özel bir register
[GLOBAL idt_load]  ; idt_load ın harici dosyalar tarafından erişilebilir olmasını sağlar
extern idtp           ; C'deki 'idtp' değişkenini buradan görebilelim. idt.c dosyasındaki idt_ptr olarak tanımlanan şey

idt_load:
    lidt [idtp]       ; Köşeli parantez varsa idtp'nin kendisini değil, tuttuğu adresin gösterdiği yerdeki bilgiyi getirir. 
    /* lidt komutu ise bu idt yani hataların bulunduğu tablo defter her ne ise onu onun başladığı adresi ve boyutunu idtr adlı özel register a yükler
    ret               ; C'ye geri dön