.section .init
    pop %ebp
    ret

.section .fini
    pop %ebp
    ret
    

    // bu ve crti.s dosyaları sabit datalar ve global değişkenleri kullanabilmek adına bu şekilde tanımlı olması lazım kodu dosya düzeni falan her şeyi bu şekilde