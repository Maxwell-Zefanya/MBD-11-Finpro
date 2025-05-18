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
Note: Kode yang direferensikan pada README ini seluruhnya terletak pada **./Kode/Kode.S**  




## iv. Hasil dan Evaluasi Pengujian


## v. Kesimpulan

