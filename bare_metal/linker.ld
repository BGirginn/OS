/* boot.o ve kernel.o bizim makine diline dönüşmüş object dosyalarımız. ama ikisi ayrı bu sebeple birleştirmemiz lazım 
bu yüzden birleştirmeye dair ayarlaru bu .ld dosyasının içinde ayarlıyoruz. ne nerede nereden başlar vesaire tüm config burada */

ENTRY(_start) /* bootloader in ilk bakacağı yer burasıdır sistem buradan başlar. _start ı boot.s içinde tanımlarız */


/* Bu kısım bizim kernel haritamızdır. Kernelin ramde hangi adresten başlayacağını vesaire burada belirleriz. .bss .data gibi bölümlerin nerede duracağını burada ayarlarız */
SECTIONS
{
    . = 2M;  /* burada eşitlikteki . işareti bizim anlık konum sayacımız. benim anlık konumumu 2MB olan yer yap anlamına geliyor */

.text BLOCK(4K) : ALIGN (4K)  /* buradaki BLOCK(4K) komutu verilerin 4kb lik paketler olmasını sağlar align ise başlangıcı 4ün katı yapar. .text ise özel section adıdır */
{
    *(.multiboot)  /* bootloader’ın kernel’i tanıyabilmesi için konulan özel header (kimlik kartı) ve en başa koy hep yoksa sorun yaşanır (genel en baş) */
    /* bu bizim zaten boot.s de tanımladığımız özel kimlik kartı olan section. boot.s de tanımladık tüm bilgileri ld ye çağırıyoruz oradan gibi düşün. func çağırma gibi */

    *(.text)  /* Bu komut tüm object dosyalarındaki çalıştırılabilir fonksiyonların (putchar tarzı) makine kodunun geldiği yer bu özeldir böyle tanımlanır */
    /* evet boot.s de .text de vardır ama bootloader bunu bilemez sadece multiboot u anlayabiliyor o. o yüzden üstteki mantık burada çalışmıyor 
    bu direkt tüm objectler yani .o uzantılı makine kodlarından çalıştırılabilir makine kodlarını buraya topluyor. */
}

	.rodata BLOCK(4K) : ALIGN(4K)
	{
		*(.rodata)
	}

    /* Read-only data: const olarak tanımlanan ve değiştirilmeyen veriler bu section'a yerleştirilir */



	/* Read-write data (initialized) */
	.data BLOCK(4K) : ALIGN(4K)
	{
		*(.data)  /* tüm .o lardan .data kısımlarını çeker */
	}

    /* başlangıç değeri verilmiş ve çalışma sırasında değiştirilebilen global/static değişkenlerin bulunduğu section’dır */

    /* Read-write data (uninitialized) and stack */
	.bss BLOCK(4K) : ALIGN(4K)
	{
		*(COMMON)
		*(.bss)
        /* ommon global olup birden fazla yerde kullanılmış değişkenleri alır (unint) sonra da bu birden çok kopyayı tek bir kopya yapar ve bss e verir 
        ama eğer global değilse zaten özel bir değişken olduğu için direkt bss e gider */
	}

    /* başlangıç değeri verilmemiş global/static değişkenlerin ve genelde stack alanının tutulduğu, dosyada yer kaplamayan section’dır */

/* eğer boot.s ya da kernel.c de tanımladığın ama linkerde yerini belirlemediğin sectionlar var ise bunlar kaybolmaz linker bunları otomatik olarak yerleştirir
 ama bu çok sağlıklı bir işlem değildir gereksiz buglara ve boyut büyümelerine sebep olabilir */

}