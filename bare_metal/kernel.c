#include <stdbool.h> /* true false yerine 1 0 yazma rahatlığı sadece */
#include <stddef.h>  /* pointer ve memory */
#include <stdint.h>  /* kesin veri boyutu için cünkü misal short dediğinde 8 de 16 bit de olabilir ve os de bu sorun */
/* bunları compiler sağlıyor bize stdio.h gibileri ise libc sağlıyor ama o henüz yok ortada os yok */

/* Check if the compiler thinks you are targeting the wrong operating system. */
#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

#if !defined(__i386__)
#error "This tutorial needs to be compiled with a ix86-elf compiler"  
#endif

/* Bu üstteki kısım bizim compile sistemimiz için. yanlışlıkla cross yerine farklı şey kullanırsak engellemesi için */

enum vga_color {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
}; /* ekrana gelecek olan renklerin sayı karşılığını tanımlıyoruz bunlar sabit */

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) 
{
	return fg | bg << 4;
}

/* static bir nevi private. inline dediği fonksiyon eğer çok büyük değilse çağırmak yerine direkt yapıştır (optimizasyon) uint8_t unsigned int 8 bit demek.
içerdeki return de ise dönecek veri 8 bit üst 4 bg, alt 4 fg. bg değerinin adresini üst 4 e atıyoruz fg alt 4 or kullanarak birleştiriyoruz. renk ataması daha sonra burası tanımlama*/

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) 
{
	return (uint16_t) uc | (uint16_t) color << 8;
}

/* uint16_t unsigned 16 bitlik sayı demek. unsigned char dediği harfin ascii a göre sayısal karşılığı. color dediği düz color. üst 8 renk, alt 8 harf. 
henüz renk ve harf ataması yapılmadı sadece kullanılacak denklemler tanımlanıyor. ekrana gelecek harf ve harfin rengininin denklemini tanımlıyoruz. */

size_t strlen(const char* str) 
{
	size_t len = 0;
	while (str[len])
		len++;
	return len;
}
/* bu normalde c kütüphanesinden gelen strlen fonksiyonunun elle yazılmış hali freestand yazdığımız için o tarz kütüphaneler yok biz de elle yazıyoruz muadilini */
/* herhangi bir string in uzunluğunu bulmak için kullanacağımız fonksiyonun tanımlanması. fonk ismi strlen biz koyduk onu. size_t denen uint8_t gibi bir değişken tipi boyut için özel */

#define VGA_WIDTH   100
#define VGA_HEIGHT  30
#define VGA_MEMORY  0xB8000 

/* sabit tanımlamaları. 80 25 di 100 30 yaptım ben not buraya  */

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer = (uint16_t*)VGA_MEMORY;  /* 0xB8000 adresinden itibaren olan RAM’i ekran gibi kullanacağım yazı yazma işleri tarzında tanımlaması */

void terminal_initialize(void) 
{
	terminal_row = 0;
	terminal_column = 0;
	terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
	
	for (size_t y = 0; y < VGA_HEIGHT; y++) { /* sütunlar */
		for (size_t x = 0; x < VGA_WIDTH; x++) { /* satırlar */
			const size_t index = y * VGA_WIDTH + x; /* iki boyutu tek boyuta çevirme kısmı */
			terminal_buffer[index] = vga_entry(' ',terminal_color);  /* ramin ekran olarak kullanılan adresinden yapılacak işlem (ekranı boş gösterme) */
		}
	}
}

/* başta cursor konumu ayarlandı sol en üst. sonrasında terminal colora vga_entry_color dan renk atandı. ilk for ile tüm sütunlar içindeki for ile tüm satırlar geziliyor
normalde yükseklik ve genişlik 2 boyuttur ama biz işlem yapmak için index değişkeni ile ikiden tek boyuta geçiyoruz. sonrasında da her bir kareye boşluk ve o boşluğa da renk atıyoruz
bu sayede ekran seçtiğimiz renkte ve boşmuş gibi gözüküyor*/

void terminal_setcolor(uint8_t color) 
{
	terminal_color = color;
}

/* varsayılan yazı rengini ayarlayan global değişken (static yazsa global olmaz private olur) */
/* terminal_setcolor(vga_entry_color(VGA_COLOR_RED, VGA_COLOR_BLACK)); yazarsan bu satırdan sonraki her şey kırmızı yazı siyah arka plan olur mesela ilki fg ikincisi bg */
/* bu fonksiyonu çağırırken zaten parametreye değeri veriyoruz o da bu değeri direkt fg ve bg olarak tüm terminal_color lara atıyor */

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y) 
{
	const size_t index = y * VGA_WIDTH + x;
	terminal_buffer[index] = vga_entry(c, color);
}

/* belirli bir koordinata karakter basar. dışarıdan karakter, renk, x ekseni konumu ve y ekseni konumu alır. */ 

void terminal_putchar(char c) 
{
	if (c == '\n') {
		terminal_column = 0;
		if (++terminal_row == VGA_HEIGHT)
			terminal_row = 0;
		return;
	}

	terminal_putentryat(c, terminal_color, terminal_column, terminal_row);

	if (++terminal_column == VGA_WIDTH) {
		terminal_column = 0;
		if (++terminal_row == VGA_HEIGHT)
			terminal_row = 0;
	}
}
/* tek char yazdırmak için kullanılır. eğer birden fazla char yazdırmak istersen bunu döngüye sokman gerekir o da zaten alttaki oluyor bu da alttakinin içi zaten */
/* burasının asıl olayı string yazdırmak ve alt satıra geçme destepinin ana mekanizması olması kalan özellikler bunun üstüne gelecek */


void terminal_write(const char* data, size_t size) 
{
	for (size_t i = 0; i < size; i++)
		terminal_putchar(data[i]);
}
/* birden fazla karakteri yazmak için kullanılır terminal_putchar ın döngüsel olarak çalıştığı versiyon */
/* terminal_write("ABC", 3); */

void terminal_writestring(const char* data) 
{
	terminal_write(data, strlen(data));
}

/* terminal_write ve terminal_putchar ın ikisini birleştirip tam çalışan bir mekanizma yaratır. terminal_write da data uzunluğunu elle girmelisin burada otomatik olarak buluyor
full bunu kullan */

void kernel_main(void) 
{

	terminal_initialize(); /* ekranı temizleme fonksiyonunu çağırdık */

	/* Newline support is left as an exercise. */ /* alt satıra geçme özelliğini ekle diyordu eklendi putchardaki ilk if döngüsü kullanılarak */
	terminal_writestring("Hello World from my first os.\n");
}

/* burada artık OS başlıyor ilk burası çalışır kalanlar özellikler için tanımlamalar ve fonksiyonlardı. */