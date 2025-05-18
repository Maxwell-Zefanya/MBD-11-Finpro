# PaceGuard - Proyek Akhir Sistem Embedded Kelompok 11
## i. Pendahuluan
### Nama dan NPM anggota
- Anthonius Hendhy Wirawan / 2306161795
- Javana Muhammad Dzaki / 2306161826
- Maxwell Zefanya Ginting / 2306221200
- Ruben Kristanto / 2306214624
### Latar belakang
Pada proyek ini, masalah yang ingin dipecahkan adalah bagaimana pelaksanaan kegiatan lari bisa dilakukan dengan lebih mudah, murah, serta lebih akurat. Sebagai konteks, kegiatan lari memerlukan 3 komponen utama supaya kegiatan bisa berjalan dengan lancar. Pertama, diperlukan sebuah metode untuk mengendalikan alur kegiatan lari. Artinya, diperlukan sebuah komponen yang bisa memulai dan memberhentikan kegiatan tersebut. Kedua, diperlukan juga metode untuk mencatat seberapa cepat pelari bisa menempuh jarak tertentu. Komponen yang bisa memenuhi keperluan ini harus bisa mengukur jarak lari dengan akurat serta mencatat waktu yang ditempuh oleh pelari untuk melewati jarak tersebut. Terakhir, pelari tersebut perlu mengetahui seberapa cepat ia lari, sehingga bisa mengatur kecepatannya supaya tidak terlalu kelelahan. Keperluan ini bisa diraih menggunakan komponen yang bisa menampilkan kecepatan sang pelari.  

Berdasarkan konteks yang diberikan, dapat dilihat bahwa kegiatan lari memerlukan banyak komponen berbeda supaya kegiatan bisa berjalan dengan lancar. Terlebih lagi, semua komponen tersebut perlu bekerja sama satu dengan yang lainnya agar tidak saling mengganggu dan mengurangi kinerja tiap komponen. Hal ini menyebabkan kegiatan lari membutuhkan biaya yang tidak murah. Kelompok kami membuat proyek ini dengan tujuan menyelesaikan permasalahan biaya dengan tetap mempertahankan kualitas tiap komponen kegiatan lari. Solusi yang didapatkan adalah dengan membuat sebuah sistem berbasis Arduino yang mengintegrasikan komponen pengendalian, pencatatan dan penampilan waktu menjadi satu solusi yang lebih mudah, murah, serta akurat ketimbang solusi yang tidak melakukan integrasi.  

## ii. Desain dan Implementasi Hardware
### Alat dan Bahan
- 1x Breadboard small
- 1x Arduino UNO R3
- 1x KY-032 Infrared Sensor
- 1x 16x2 LCD with I2C adapter
- 3x LED
- 3x Button
- 7x Resistor
- Kabel jumper

### Desain & Implementasi
![](https://i.imgur.com/PgDKn8w.png)  

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

