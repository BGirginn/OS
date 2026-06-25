# idtr dediğimiz şey idt için olan özel bir register'dır.

.global idt_load  # idt_load'un dış dosyalar (C kodları) tarafından çağrılabilmesini sağlar.

idt_load:
    lidt (idtp)   # idt.c içindeki idtp yapısının işaret ettiği adresi IDTR register'ına yükler.
    ret           # Fonksiyonu bitirip C koduna geri döner.
