#ifndef IDT_H   /* "Include Guard" - Eğer bu dosya zaten dahil edildiyse tekrar etme. tek bir dosyada unutup birden fazla dahil ettiğimizde koruyucu */
#define IDT_H

/* 1. Şablonumuzu buraya koyuyoruz ki her yer bu yapıyı tanısın */
struct regs {
    unsigned int ds;                                     
    unsigned int edi, esi, ebp, esp, ebx, edx, ecx, eax; 
    unsigned int int_no, err_code;                       
    unsigned int eip, cs, eflags, useresp, ss;           
};

/* 2. Fonksiyonun "İmzasını" buraya koyuyoruz (Noktalı virgül ile!) */
void isr_handler(struct regs *r);

#endif