# PaceGuard - Proyek Akhir Sistem Embedded Kelompok 11

![PGBanner](https://i.imgur.com/G5uq6lu.png)

## i. Pendahuluan
### Nama dan NPM anggota
- Anthonius Hendhy Wirawan / 2306161795
- Javana Muhammad Dzaki / 2306161826
- Maxwell Zefanya Ginting / 2306221200
- Ruben Kristanto / 2306214624
### Latar belakang
Dalam dunia olahraga lari, presisi waktu adalah faktor krusial. Perbedaan satu milidetik dapat menentukan kemenangan atau kekalahan seorang atlet. Sistem pencatatan waktu yang akurat bukan hanya pelengkap, melainkan komponen vital dalam evaluasi performa atletik

Sayangnya, teknologi pengukuran waktu yang tersedia sering kali mahal, kompleks, atau tidak cocok untuk pelatihan mandiri. Banyak pelari terutama untuk jarak jauh atau marathon, bergantung pada strategi pacing untuk mengoptimalkan energi. Tanpa sistem yang akurat untuk mengukur waktu secara real-time, pelari sulit mengetahui apakah mereka mempertahankan kecepatan ideal

PaceGuard oleh kelompok kami hadir sebagai solusi atas tantangan ini. Sistem yang kami buat menggunakan Microcontroller ATMega238P ini memungkinkan pelari memantau waktu tempuh di titik-titik tertentu secara otomatis sehingga membantu mereka melatih konsistensi kecepatan. Namun dengan simplisitanya, kami berharap PaceGuard tidak hanya untuk atlet profesional, tapi juga dapat dijangkau oleh pelatih, komunitas lari, dan individu yang ingin meningkatkan performa larinyadengan cara yang terukur dan terjangkau

Teknologi utama untuk fungsionalitas PaceGuard terletak di  sensor IR dan  Microcontroller ATMega238P pada arduino yang diprogram dengan Assembly AVR. Oleh karena itu, PaceGuard menawarkan akurasi tinggi, respons cepat, dan kinerja bagus bahkan dalam kondisi outdoor. PaceGuard menjadikan waktu sebagai sahabat, karena bahkan hitungan milidetik sangat berharga untuk dunia lari profesional.

## ii. Desain dan Implementasi Hardware
### Alat dan Bahan
| Komponen                  | Jumlah |
|---------------------------|--------|
| Breadboard small          | 1x     |
| Arduino UNO R3            | 1x     |
| KY-032 Infrared Sensor    | 1x     |
| 16x2 LCD with I2C adapter | 1x     |
| LED                       | 3x     |
| Button                    | 3x     |
| Resistor                  | 7x     |
| Kabel jumper              | Secukupnya |

### Desain & Implementasi
![](https://i.imgur.com/NtRtTbe.png)  

PaceGuard terdiri atas sebuah komponen utama, yaitu Arduino, yang mengendalikan 5 komponen pembantu lainnya, yaitu komponen LED, button, LCD Display, serial display, serta sensor. Sistem ini akan mendapatkan daya listriknya melalui power supply independen dengan tegangan 5V yang perlu dihubungkan kepada Arduino serta breadboard menggunakan kabel jumper. Selain daripada kedua hal itu, power supply tidak perlu dihubungkan ke komponen lainnya.  

#### 1. Arduino
Arduino akan menjadi komponen utama yang mengendalikan keenam komponen lainnya. Arduino akan dihubungkan kepada power supply menggunakan kabel jumper melalui pin 5V yang berada pada sejajar dengan pin RESET dan perlu juga menghubungkan ground ke pin GND yang berada tepat di-samping pin 5V.  

#### 2. Button
Sistem PaceGuard memerlukan 3 button untuk bekerja secara optimal. Ketiga button memiliki konfigurasi pull-down. Satu button digunakan sebagai tombol enable/disable, dan dihubungkan kepada Arduino melalui pin 2/PD2/INT0. Dua button digunakan sebagai selector jarak, dan dihubungkan kepada Arduino melalui pin PC1 dan PC2.  

#### 3. LED
Terdapat 3 buah LED yang diperlukan untuk kebutuhan countdown pada saat baru memulai lari. Warna LED tidak begitu penting, namun disarankan untuk memakai LED merah, kuning, hijau, masing-masing 1 buah. LED dihubungkan secara seri dengan urutan Arduino-Resistor-LED-Ground. LED merah dihubungkan kepada arduino melalui pin 8/PB0, kuning melalui pin 9/PB1, dan hijau melalui pin 10/PB2.  

#### 4. Sensor
Sistem PaceGuard bisa bekerja secara otomatis berkat sensor KY-032 yang bisa mendeteksi objek, dalam kasus ini pelari, di depannya. Sensor memiliki 3 pin utama, yaitu ground, Vcc, dan OUT. Pin ground dan Vcc masing-masing dihubungkan kepada baris ground dan Vcc pada breadboard. Pin OUT dihubungkan kepada pin 3/PD3/INT1 pada Arduino dan menggunakan konfigurasi pull-down.  

#### 5. Serial display
Display serial akan menampilkan seluruh laptime dan pace dari pelari. Display memiliki 2 pin utama, yaitu RXD dan TXD. Kedua pin dihubungkan kepada Arduino masing-masing dengan pin 1/PD1/TXD, serta pin 0/PD0/RXD.  

#### 6. LCD Display
Display LCD akan menampilkan berbagai pesan informasi yang diperlukan kepada pelari. Perlu dipastikan bahwa LCD sudah dihubungkan kepada modul adaptor I2C, yang memiliki 4 buah pin. LCD akan dihubungkan kepada sistem melalui adaptor tersebut, dimana pin yang perlu diperhatikan ada 4, yaitu pin SDA, SCL, VSS dan VDD. Pin SDA dihubungkan kepada Arduino melalui pin PC4/SDA. Pin SCL dihubungkan melalui pin PC5/SCL. VSS disambungkan kepada baris Vcc breadboard dan VDD kepada baris ground pada breadboard.  


## iii. Desain dan Implementasi Software
### Prasyarat
- Proteus 8 Professional
    - Rangkaian sama persis dengan implementasi Hardware
    - Library
        - Arduino UNO Library
            - Ditemukan pada: https://www.theengineeringprojects.com/2021/03/arduino-uno-library-for-proteus-v2.html
        - Infrared Sensor Library
            - Ditemukan pada: https://www.theengineeringprojects.com/2018/07/infrared-sensor-library-for-proteus.html
        - DISPLAY Library
        - ACTIVE Library
        - DEVICE Library
- Arduino IDE

### Desain & Implementasi
![overall_flowchart](https://i.imgur.com/ZYDZrjp.png)

Note: Kode yang direferensikan pada README ini seluruhnya terletak pada **./Kode/Kode.S**  

PaceGuard memiliki program software yang dibuat secara khusus untuk keperluan pacing. Software tersebut ditulis sepenuhnya dalam bahasa assembly, dan ditargetkan untuk microprocessor ATMega328P yang terdapat pada Arduino UNO R3. Alur kerja program bisa dibagi menjadi 7 bagian utama, sesuai dengan gambar flowchart di atas. Arduino yang ada pada sistem bisa mendapatkan program dengan pertama mengcompile (verify) kode kemudian menguploadnya menggunakan software Arduino IDE.  


#### 1. Setup
Fase setup dilakukan untuk memastikan Arduino bisa berkomunikasi dengan komponen eksternal secara benar dan efisien. Kode pada fase ini sebagian besar terdapat pada label `main`. Hal-hal yang diatur pada fase setup adalah sebagai berikut  

- Penyetelan stack pointer, diarahkan kepada bagian paling akhir RAM. Dilakukan karena program akan banyak melakukan operasi push dan pop
- Penyetelan semua button dan sensor sebagai input, dan semua LED sebagai output.
- Memastikan bahwa register yang dipakai untuk menyimpan waktu lap user sudah kosong.
- Mengaktifkan fungsionalitas interrupt untuk INT0 dan INT1.
- Mengaktifkan serial communication dengan baud rate 9600.
- Menyetel konfigurasi Two-Wire Interface (I2C) agar Arduino bekerja sebagai Master Transmitter. I2C akan digunakan untuk menampilkan pesan pada LCD.
- Print welcome message pada LCD menggunakan I2C. Penjelasan selengkapnya ada pada fase *Display*  

Kode setup sebagian besar distruktur secara *in-line*, yang berarti isi kode berada satu disamping yang lainnya. Bagian kode yang tidak in-line hanya terdapat pada saat menyetel I2C, dimana penyetelan dilakukan dengan instruksi `CALL`, yang akan memanggil function.  

#### 2. Select
Setelah segala aspek program berhasil disetel, maka program akan diam menunggu button press dari user. Fase ini bersifat opsional, karena dari kedua button, terdapat 3 opsi yang bisa dipilih oleh user. Bila user tidak menekan tombol select dan langsung menekan start, maka secara default program akan menggunakan jarak lari sepanjang 500m. Bila menekan, maka jarak lari yang digunakan sesuai dengan apa yang dipilih oleh user, baik 1000m atau 2000m.  

Implementasi fase select berkaitan erat dengan fase start. Hal ini adalah karena meskipun seleksi menggunakan polling, button start akan memanggil start sequence menggunakan interrupt. Oleh karena itu, user bisa langsung start (default 500m) tanpa perlu menekan button seleksi.  

#### 3. Start
Fungsi utama dari fase start adalah untuk memberikan aba-aba awal kepada pelari. Aba-aba diimplementasikan dalam bentuk LED sekuensial, dimana awalnya LED merah akan menyala, kemudian yang kuning, lalu yang hijau menyala untuk menandakan bahwa pelari bisa mulai berlari. Implementasi dari fase start cukup sederhana. Program hanya akan selang-seling mengubah register PORTB dan memanggil delay saja. Register PORTB diubah untuk menyalakan LED secara sekuensial, dan delay diimplementasikan menggunakan polling.  

#### 4. Run
Mulainya fase run ditandai dengan menyalanya LED hijau. Fase ini memiliki 2 bagian utama, yaitu bagian timer, dan bagian counter. Kode inti untuk fase run terdapat pada label ``loop``, dimana loop akan memanggil timer dan menambah register X sebanyak 1. Instruksi BRTC berhubungan dengan fase record, dimana fase run akan terus berjalan selama fase record belum berjalan.  

Implementasi timer dilakukan dengan melakukan polling. Caranya adalah program akan pertama menyetel TCNT (Timer Counter Register) sedemikian rupa sehingga timer akan overflow tepat pada saat waktu 1 detik. Artinya, timer akan mengeluarkan flag overflow setiap 1 detik. Flag inilah yang ditunggu program menggunakan polling, dimana setelah muncul baru lanjut ke penambahan counter detik.  

Sesuai dengan namanya, counter detik bertugas untuk mencatat sudah berapa detik lamanya sejak awal lampu LED hijau menyala. Counter untuk detik berukuran 16-bit, dan disimpan pada register R26-R27, atau bisa disebut sebagai register X. Counter ini akan bertambah 1 angka setiap detiknya. Secara teori, timer bisa menghitung sampai 18 jam setiap lap. Rentang waktu tersebut dianggap sudah cukup, melihat PaceGuard hanya menerima jarak lari maksimum sepanjang 2000m.  

#### 5. Record
Fase record akan aktif secara bersamaan fase run mulai. Namun, fase ini hanya akan ada pada mode standby. Fase record baru mulai saat sensor infrared KY-032 mendeteksi adanya pelari yang melewati sensor tersebut. Sinyal yang datang dari KY-032 akan menyebabkan terjadinya interrupt pada Arduino. Program handler interrupt yang diimplementasikan akan melakukan 2 hal. Pertama, handler akan mematikan timer yang sedang berjalan, dimana hasil akan terdapat pada register X. Kedua, handler akan menyetel bit T pada SREG menjadi 1. Bit T disetel dengan tujuan program bisa keluar dari fase run, dan bisa mulai melakukan kalkulasi pace. Implementasi lengkap untuk  handler dapat dilihat pada label ``__vector_2``.  

Kalkulasi pace perlu dilakukan karena pace akan ditampilkan dalam format `menit:detik`, dimana format ini berlawanan dengan format register X yang hanya menyimpan waktu dalam detik. Kalkulasi pace terdapat pada label ``hitung``, dimana luarannya adalah register yang menyimpan menit (R17), dan yang menyimpan detik (R18). Kalkulasi diimplementasikan dengan mengurangi register X dengan angka 60. Bila hasil X tidak negatif, maka R17 akan ditambah 1, bila iya, maka X akan ditambah 60 dan dipindahkan kedalam R18.  

#### 6. Display
Fase display sebenarnya banyak dijalankan, bukan hanya setelah record saja. Namun, fase display yang ditampilkan pada flowchart merujuk kepada display hasil pace dan laptime, yang akan menggunakan Serial Monitor. Meskipun begitu, fase ini tetap juga menggunakan LCD dengan I2C module. Oleh karena itu, fase display bisa dibagi menjadi 2 bagian, yaitu bagian Serial Monitor dan bagian LCD.  


<u>**Serial Monitor**</u>  
Fase yang ada pada flowchart merujuk kepada bagian Serial Monitor. Fase ini dimulai setelah program selesai mengonversi counter menjadi menit dan detik. Hasil yang ada pada register R17 dan R18 masih dalam bentuk biner, bukan format ASCII. Oleh karena itu, perlu dilakukan semacam konversi untuk mengubah angka biner menjadi format ASCII.  

Program mengubah biner ke ASCII dengan pertama mengubah biner ke desimal. Caranya mirip seperti kalkulasi pace, dengan perbedaan register dikurangi dengan angka 10. Konversi akan menghasilkan 2 luaran, yaitu desimal puluhan dan satuan. Setelah konversi berlangsung, barulah semua hasil desimal dikonversikan menjadi ASCII dengan menambahkan nilai dengan 48.  

Barulah setelah konversi selesai dilakukan kedua angka tersebut di-print ke serial monitor. Implementasinya adalah dengan menggunakan register UDR0, dimana data ASCII yang didapatkan dikirimkan ke UDR0 untuk kemudian dikirimkan ke serial monitor dan akhirnya di-print.  

<u>**LCD**</u>  
LCD hanya digunakan untuk mengirimkan beberapa informasi penting saja kepada pelari. Pesan yang ingin dikirimkan sudah ada dari awal sebagai data pada program. Pesannya sendiri berupa null-terminated string, dimana setiap kalimat diakhiri dengan karakter null. Program akan terus mengirimkan data string tersebut kepada LCD sampai ketemu nilai 0.  

LCD bisa bekerja menggunakan modul I2C yang sudah ditempelkan. Secara garis besar, komunikasi I2C terjadi atas 4 tahap, yaitu setup, start, write & acknowledge, dan stop. Tahap setup sudah terjadi pada fase setup. Tahap start dilakukan dengan mengisi bit ``TWINT, TWSTA, TWEN`` dan ``TWEA`` kedalam ``TWCR``. Tahap write dilakukan dengan mengisi ``TWDR`` dengan data yang diinginkan, dalam kasus ini string message. Terakhir, tahap stop dilakukan dengan mengisi ``TWINT, TWSTO, TWEN`` kedalam TWCR.  

Perlu diketahui juga bahwa terdapat pola pengiriman sekuensial khusus yang perlu dilakukan saat ingin berinteraksi dengan LCD. Pola ini dilakukan supaya LCD bisa disetel dengan benar dan proses pengiriman data string bisa terjadi tanpa masalah.  

#### 7. Reset
Fase reset hanya akan berjalan bila tombol enable dipencet setelah fase start berlangsung. Fase ini adalah fase yang paling sederhana, dimana secara implementasi hal yang dilakukan hanyalah mengubah lap-time menjadi 0 dan menambahkan 1 kedalam lap counter.  


#### Interrupt handling
![](https://i.imgur.com/ictMoF9.png)


## iv. Hasil dan Evaluasi Pengujian


## v. Kesimpulan

