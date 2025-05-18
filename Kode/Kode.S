;  ____                 ____                      _ 
; |  _ \ __ _  ___ ___ / ___| _   _  __ _ _ __ __| |
; | |_) / _` |/ __/ _ \ |  _ | | | |/ _` | '__/ _` |
; |  __/ (_| | (_|  __/ |_| || |_| | (_| | | | (_| |
; |_|   \__,_|\___\___|\____| \__,_|\__,_|_|  \__,_|
;    

;==============================================================
; PaceGuard - Proyek Akhir Sistem Embedded Kelompok 11
;==============================================================
; Anggota Kelompok:
; - Anthonius Hendhy Wirawan / 2306161795
; - Javana Muhammad Dzaki / 2306161826
; - Maxwell Zefanya Ginting / 2306221200
; - Ruben Kristanto / 2306214624
;==============================================================
;   Register Usage Documentation
;   R16: Setup, distance state
;   R17: conversion result (minute)
;   R18: conversion result (second)
;   R19: conversion to bcd result (puluhan)
;   R20: conversion to bcd result (satuan)
;   R21: I2C setup
;   R22: I2C write
;   R23: counter for bcd conversion, serial communication
;   R24: pembanding dalam bcd conversion, serial communication
;   R25: 
;   R26: Total Time Output Low
;   R27: Total Time Output High
;   R28: Pace Timer
;   R29: 
;   R30: Serial communication, I2C load message
;   R31: Serial communication, I2C load message

;==============================================================
#include <avr/io.h>

    ; Pin Directives
    ; Digital: use in PORTD
    .equ BTN_ENA, 0
    .equ BTN_RES, 1

    ; LED: use in PORTB
    .equ LED_RED, 0
    .equ LED_YEL, 1
    .equ LED_GRE, 2

    ; Sensor: use in PORTD
    .equ SENSOR_PIN, 7

    ; Display: use in PORTC (LCD)
    .equ LCD_SDA, 4
    .equ LCD_SCL, 5

;==============================================================
; Pre-defined data
.global main
.global __vector_1      ; INT0
.global __vector_2      ; INT1
.section .data
    lap_count:      .byte 0
    timer_counter:  .byte 0
    timer_seconds:  .byte 0
    timer_minutes:  .byte 0
    system_enabled: .byte 0
    pace_target:    .byte 0
    pace_current:   .byte 0
    ir_state_prev:  .byte 0

    message_welcome:    .ascii "PaceGuard System"
                        .byte 0
    message_ready:      .ascii "Ready to Start"
                        .byte 0
    message_running:    .ascii "Running..."
                        .byte 0
    message_lap:        .ascii "Lap: "
                        .byte 0

    message_time:       .ascii "Time: "
    message_pace:       .ascii "Pace: "

;==============================================================
; Code Segment
.section .text
main:
    ; Initialize Stack Pointer
    ldi r18, hi8(RAMEND)
    STS SPH, r18
    ldi r18, lo8(RAMEND)
    STS SPL, r18
    
    ; Digital: All as i/p
    LDI     R16, (0<<BTN_ENA) || (0<<BTN_RES)
    OUT     DDRD, R16

    ; LED: All as o/p
    LDI     R16, (1<<LED_RED) || (1<<LED_YEL) || (1<<LED_GRE)
    OUT     DDRB, R16

    ; Sensor: All as i/p
    LDI     R16, (0<<SENSOR_PIN)
    OUT     DDRD, R16

    ; Timer: Clear register
    CLR R26
    CLR R27

    ; All: Enable interrupt
    LDI R16, (0<<ISC11) || (0<<ISC10) || (0<<ISC01) || (0<<ISC00)
        STS EICRA, R16      ;Interrupts on low
    LDI R16, (1<<INT0) || (1<<INT1)
        OUT EIMSK, R16      ;Enable INT0 and INT1
    CLR R16

    ; initialization of serial com
    CLR   R24
    STS   UCSR0A, R24               ;clear UCSR0A register
    STS   UBRR0H, R24               ;clear UBRR0H register
    LDI   R24, 103                  ;& store in UBRR0L 103 value
    STS   UBRR0L, R24               ;to set baud rate 9600
    LDI   R24, 1<<RXEN0 | 1<<TXEN0  ;enable RXB & TXB
    STS   UCSR0B, R24
    LDI   R24, 1<<UCSZ00 | 1<<UCSZ01;asynch, no parity, 1 stop, 8 bits
    STS   UCSR0C, R24

    ; Display: Setup I2C as Master
    RCALL I2C_init

    ; Display: Print welcome message
    LDI   R30, lo8(message_welcome)
    LDI   R31, hi8(message_welcome)
    CALL  lcd_print
    RCALL start_timer
    LDI   R30, lo8(message_ready)
    LDI   R31, hi8(message_ready)
    CALL  lcd_print

    SEI

waitbtn:
    RCALL   select_button

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
loop:
    RCALL   start_timer
    ADIW    X, 1        ; Add 1 to R27:R26
    BRTC loop

hitung:
    RCALL convert_to_minute
    RCALL convert_to_BCD        ;ubah detik ke bentuk BCD
    MOV R18, R17
    RCALL convert_to_BCD        ;ubah menit ke bentuk BCD
    //tampilin waktu per lab ke serial monitor
    LDI   R30, lo8(message_time)
    LDI   R31, hi8(message_time)
agn1:
    LPM   R23, Z+                   ;load char of string onto R23
    CPI   R23, 0                    ;check if R23=0 (end of string)
    BREQ  ext1                      ;if yes, exit

l5: LDS   R24, UCSR0A
    SBRS  R24, UDRE0                ;test data buffer if data can be sent
    RJMP  l5
    STS   UDR0, R23                 ;send char in R23 to serial monitor
    ;--------------------------------------------------------------------
    RJMP  agn1                       ;loop back & get next character
    ;--------------------------------------------------------------------

ext1:   
    POP R23
    STS UDR0, R23               ;Kirimkan bcd puluhan menit ke serial monitor   
    LDI R23, 0x3A               ;ascii dari  `:`
    STS UDR0, R23           
    POP R23                     ;kirimkan bcd satuan menit ke serial monitor
    STS UDR0, R23
    LDI R23, 10               
    STS UDR0, R23
    LDI R23, 13               
    STS UDR0, R23
    
    ;convert waktu (seconds/kilometers)
    RCALL convert_disctance
    RCALL convert_to_minute
    RCALL convert_to_BCD        ;ubah detik ke bentuk BCD
    MOV R18, R17
    RCALL convert_to_BCD        ;ubah menit ke bentuk BCD
    ;tampilin pace ke lcd dan serial monitor
    LDI   R30, lo8(message_pace)
    LDI   R31, hi8(message_pace)

agn2:
    LPM   R23, Z+                   ;load char of string onto R23
    CPI   R23, 0                    ;check if R23=0 (end of string)
    BREQ  ext2                      ;if yes, exit

l6: LDS   R24, UCSR0A
    SBRS  R24, UDRE0                ;test data buffer if data can be sent
    RJMP  l6
    STS   UDR0, R23                 ;send char in R23 to serial monitor
    ;--------------------------------------------------------------------
    RJMP  agn2                       ;loop back & get next character
    ;--------------------------------------------------------------------

ext2:   
    POP R23
    STS UDR0, R23               ;Kirimkan bcd puluhan detik ke serial monitor   
    LDI R23, 0x3A               ;ascii dari  `:`
    STS UDR0, R23           
    POP R23                     ;kirimkan bcd satuan detik ke serial monitor
    STS UDR0, R23
    LDI R23, 10               
    STS UDR0, R23
    LDI R23, 13               
    STS UDR0, R23

    CLT
    JMP loop

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
start_timer:
    .EQU value, 49910   ;value to give 1 sec delay
    LDI R28, hi8(value)
    STS TCNT1H, R28
    LDI R28, lo8(value)
    STS TCNT1L, R28     ;initialize counter TCNT1 = value

    LDI R28, 0b00000000
    STS TCCR1A, R28
    LDI R28, 0b00000101
    STS TCCR1B, R28     ;normal mode, prescaler = 1024

    l2: IN R28, TIFR1   ;get TIFR1 byte & check
    SBRS R28, TOV1      ;if TOV1=1, skip next instruction
    RJMP l2             ;else, loop back & check TOV1 flag
    LDI R28, 1<<TOV1
    OUT TIFR1, R28      ;clear TOV1 flag
    LDI R28, 0b00000000
    STS TCCR1B, R28     ;stop timer1
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
; Interrupt for sensor
; Purpose: stop timer
__vector_1:
    ;Disable clock
    LDI R28, 0b00000000
    STS TCCR1B, R28
    LDI R28, 1<<TOV1

    ;Clear TOV1 flag
    OUT TIFR1, R28
    LDI R28, 0b00000000
    SET 

    RETI

;========================= I2C & LCD ==========================
lcd_print:
    RCALL I2C_start
    LDI   R22, 0x20                             ; Set slave address
    RCALL I2C_write

    LDI   R22, 0b10000000                       ; Step 0: Initialization
    RCALL I2C_write
    LDI   R22, 0b00111100
    RCALL I2C_write
    CALL  delay_4200us

    LDI   R22, 0b10000000                       ;         Initialization
    RCALL I2C_write
    LDI   R22, 0b00111100
    RCALL I2C_write
    CALL  delay_120us

    LDI   R22, 0b10000000                       ; Step 1: Function set
    RCALL I2C_write
    LDI   R22, 0b00110000                       ; 1-line mode, display ON
    RCALL I2C_write

    LDI   R22, 0b10000000                       ; Step 2: Display ON
    RCALL I2C_write
    LDI   R22, 0b00001100                       ; Display ON, cursor ON, blink OFF
    RCALL I2C_write

    LDI   R22, 0b10000000                       ; Step 3: Screen CLR
    RCALL I2C_write
    LDI   R22, 0b00000001
    RCALL I2C_write

    LDI   R22, 0b10000000                       ; Step 4: Entry mode
    RCALL I2C_write
    LDI   R22, 0b00000110                       ; Increment & shift
    RCALL I2C_write

wrt:LDI   R22, 0b11000000                       ; Begin transmit chars
    RCALL I2C_write
    LPM   R22, Z+                               ; Load char of string onto R22
    CPI   R22, 0                                ; Check if R22=0 (end of string)
    BREQ  fin                                   ; If yes, exit
    RCALL I2C_write                             ; If no, print char
    RJMP  wrt                                   ; Loop back & get next character
fin:
    RCALL I2C_stop
    RET
    
;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_init:
    LDI   R21, 0
    STS   TWSR, R21       ;prescaler = 0
    LDI   R21, 12         ;division factor = 12
    STS   TWBR, R21       ;SCK freq = 400kHz
    LDI   R21, (1<<TWEN)
    STS   TWCR, R21       ;enable TWI
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_write:
    STS   TWDR, R22       ;copy SLA+W into data register
    LDI   R21, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
    STS   TWCR, R21       ;transmit SLA+W
wt2:LDS   R21, TWCR
    SBRS  R21, TWINT
    RJMP  wt2             ;wait for end of transmission
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_start:
    LDI   R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)|(1<<TWEA)
    STS   TWCR, R21       ;transmit START condition
wtw:LDS   R21, TWCR
    SBRS  R21, TWINT      ;TWI interrupt = 1?
    RJMP  wtw             ;no, wait for end of transmission
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;

I2C_stop:
    LDI   R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    STS   TWCR, R21       ;transmit STOP condition
    RET

;==============================================================
; ========= Button Selection =========
select_button:

    LDI R16, 0          ;default jarak = 500m
    LDS R5, PINC
    SBRC R5, 1
    JMP set1000
    SBRC R5, 2
    JMP set2000
    JMP select_button

set500:
    LDI R16 , 0
    JMP wait1

set1000:
    LDI R16 , 1
    JMP wait1


set2000:
    LDI R16 , 2
    JMP wait1

wait1:
    lds   r16, PIND
    sbrs  r16, 2
    rjmp wait1
    rcall delay_short

    ; LED Sequence
    ldi r18, (1<<PB0)
    out PORTB, r18
    rcall delay_long

    ldi r18, (1<<PB1)
    out PORTB, r18
    rcall delay_long

    ldi r18, (1<<PB2)
    out PORTB, r18
    rcall delay_long

    clr r18
    out PORTB, r18

    LDI   R30, lo8(message_running)
    LDI   R31, hi8(message_running)
    CALL  lcd_print
    JMP loop

; ; ========= Set Distance Values =========
; set_500:
;     ldi r17, hi8(0x01F4)
;     ldi r16, lo8(0x01F4)
;     rjmp wait_start

; set_1000:
;     ldi r17, hi8(0x03E8)
;     ldi r16, lo8(0x03E8)
;     rjmp wait_start

; set_2000:
;     ldi r17, hi8(0x07D0)
;     ldi r16, lo8(0x07D0)
;     rjmp wait_start

; ========= Wait for Start Button (PD2) =========
; wait_start:
;     lds   r16, PIND
;     sbrs  r16, 2
;     rjmp wait_start
;     rcall delay_short

;     ; LED Sequence
;     ldi r18, (1<<PB0)
;     out PORTB, r18
;     rcall delay_long

;     ldi r18, (1<<PB1)
;     out PORTB, r18
;     rcall delay_long

;     ldi r18, (1<<PB2)
;     out PORTB, r18
;     rcall delay_long

;     clr r18
;     out PORTB, r18

;     LDI   R30, lo8(message_running)
;     LDI   R31, hi8(message_running)
;     CALL  lcd_print
;     rjmp main

; ========= Delay Subroutines =========

delay_short:
    ldi r21, 50
ds1:
    ldi r22, 200
ds2:
    dec r22
    brne ds2
    dec r21
    brne ds1
    ret

delay_long:
    ldi r23, 100
dl1:
    ldi r24, 250
dl2:
    dec r24
    brne dl2
    dec r23
    brne dl1
    ret

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;

;=============================================================;
;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
convert_disctance:
    CPI R16, 0
    BREQ dis_500m
    CPI R16, 1
    BREQ dis_1000m
    CPI R16, 2
    BREQ dis_2000m

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
dis_500m:
    CLC
    ROL R26
    ROL R27
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
dis_1000m:
    RET
;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
dis_2000m:
    CLC
    ROR R27
    ROR R26
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
;=============================================================;


;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
convert_to_minute:
    ; pastikan R17 dan R18 kosong
    CLR R17
    CLR R18
A1:
    SBIW x, 60
    //cek jika negatif
    //masalah : SBIW itu unsigned, jadi jika isi dari MSB R26 1, bisa langsung loncat ke l2
    //anggap saja timer ga mungkin mencapai nilai tersebut
    BRMI A2 //jika negatif jump ke l2
    INC R17
    JMP A1
A2: 
    ;SBIW x, -30
    ADIW x, 60
    MOV R18, R27

    ; CLR R26
    ; CLR R27
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
; ````````````````````````````````````````````````````````````;
;Mengubah nilai menit dan detik (R17:R18) ke BCD untuk ditampilkan di LCD dan serial monitor
; ````````````````````````````````````````````````````````````;
; PUSH R18
; CALL convert_to_BCD

convert_to_BCD: 
    ;R19 digunakan untuk menyimpan hasil puluhan
    ;R20 digunakan untuk menyimpan hasil satuan
    ;R23 digunakan untuk counter
    ;R24 digunakan untuk pembanding 
    CLR R23
    LDI R24, 10
    CLR R19
    CLR R20
l3:
    ; POP R18
    SUB R18, R24            ;kurangi detik dengan 10
    BRMI l4                 ;jika negatif jump ke l4
    INC R23                 ;increment counter
    SUBI R24, -10           ;tambahin pembanding dengan 10
    JMP l3                  ;loop ke l3

l4: 
    ADD R18, R24
    SUBI R18, -48           ;ubah jadi ascii
    SUBI R23, -48           ;ubah jadi ascii
    MOV R19, R23            ;puluhan = counter
    MOV R20, R18
    PUSH R20
    PUSH R19                ;masukkan hasil ke stack
    CLR R23
    CLR R24
    RET
;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;

delay_120us:
    ; ~~ Delay 120 us  ~~
        ldi  r18, 4
        ldi  r19, 82
    d1: dec  r19
        brne d1
        dec  r18
        brne d1
        nop
    ; ~~ ~~ ~~ ~ ~~ ~~ ~~

delay_4200us:
    ; ~~ Delay 4200 us ~~
        ldi  r18, 88
        ldi  r19, 69
    d2: dec  r19
        brne d2
        dec  r18
        brne d2
        ret
    ; ~~ ~~ ~~ ~ ~~ ~~ ~~
    
delay_1535us:
    ; ~~ Delay 1535 us ~~
        ldi  R21, 32
        ldi  R22, 229
    d3: dec  R22
        brne d3
        dec  R21
        brne d3
        ret
    ; ~~ ~~ ~~ ~ ~~ ~~ ~~