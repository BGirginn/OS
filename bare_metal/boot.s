/* gerekli sabitlerin tanımlandığı kısım */
.set ALIGN,    1<<0             /* verilerin düzenlenmiş adreslere yazılmasını sağlar. burası bit0 dır ve bu hep align ın on off olmasının yeridir.*/
.set MEMINFO,  1<<1             /* ram bilgilerini çeker. rezerve yer hangi iş hangi alanda olacak adresleme nereden başlayacak gibi. bit1 meminfodur hep.*/
.set FLAGS,    ALIGN | MEMINFO  /* burası da zorunlu bir alan. burada align ve meminfo gibi gereksinimlerin tamamı atanıyor or kullanarak. istek listesi gibi */
.set MAGIC,    0x1BADB002       /* bootloaderin kerneli tanıması için id gibi sabit bir sayı bu asla değişmez grub bootloaderde */
.set CHECKSUM, -(MAGIC + FLAGS) /* kontrol noktası burası */

/* buranın altındaki kısım kernel olarak işaretlenmesi için gerekli tanımlayıcı gibi ya da işaret fişeği gibi*/
.section .multiboot /* bir section yani bölüm oluşturuyorum bootloader için özel olacak */
.align 4   /* bulunduğum adresi 4ün katı olan bir yere getirir. mesela adres 3 de isem 1 byte boşluk ile beni adres 4 e getirir ve kalan yazma işlemleri 4 den devam eder.*/
.long MAGIC  /* .long ile 4byte yer açarsın sonra da oraya magic in karşılığını yazarsın */
.long FLAGS
.long CHECKSUM


.section .bss  /* ramden alan ayırmak için özel bir section adı. bu isimdeki sectionda dosya hafızada değil sadece ram de yer kaplar bir değeri yoktur. int b; gibi düşün
.align 16      /* adresi 16 ya çeker */
stack_bottom:  /* adres 16 yı oluşturacağımız boş stack in alt sınırı yapar başlama sınırı */
.skip 16384 # 16 KiB   /* 16 kb lik bir adresi atlar */
stack_top:     /* adres 16 + 16 kb in son adresini oluşturulan pasif stack in üst sınır adresi yapar (stack henüz kullanıma hazır değil) */

.section .text 
.global _start /* .global dediği public func etiketi. _start da c deki main gibi bir işlevi var kodların başladığı yere karşılık geliyor */
.type _start, @function /* üst satırda start ı public yaptık burada da start ın bir fonksiyon olduğunu söyledik. ortada bir os olmadığı için söylemek lazım. */
_start: 

mov $stack_top , %esp   /* esp denen şey stack in en üst adresini ataman için tanımlanmış özel bir cpu registeri */

call _init

call kernel_main

cli  /* kesmeleri kapatır (aka interrupt) */
1: hlt   /* cpu yu uyku moduna geçir (normalde cpu interrupt ile uyanırdı ama biz kapattık) */
jmp 1b   /* 1 e geri zıpla normalde jmp o işi yapar evet ama assembly de aynı labelden birden fazla olabilir b dersen yukarı f dersen aşağıdaki 1 labeline gider */
/* bu kısım cpuyu zorla bir uyku haline sokmak için kernel main in işi bittikten sonra bir nevi pc kapatma */

.size _start, . - _start  /* .size ile sembol boyutu ataması, _start (boyutu belirlenecek şey), . - _start (anlık adresimiz). anlık adresten boyut belirlemeyi çıkarır */
