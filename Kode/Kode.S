#include <avr/io.h>

;==============================================================

;   Register Usage Documentation
;   R16: Setup, distance state
;   R17: conversion result (minute)
;   R18: conversion result (second)
;   R19: conversion to bcd result (puluhan)
;   R20: conversion to bcd result (satuan)
;   R21: I2C
;   R22: I2C
;   R23: counter for bcd conversion
;   R24: pembanding dalam bcd comnversion
;   R25: 
;   R26: Total Time Output Low
;   R27: Total Time Output High
;   R28: Pace Timer
;   R29: 
;   R30: 
;   R31: 

;==============================================================
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
                        .byte 10,13,0
    message_ready:      .ascii "Ready to Start"
                        .byte 10,13,0
    message_disabled:   .ascii "System Disabled"
                        .byte 10,13,0
    message_running:    .asciz "Running: "
    message_lap:        .asciz "Lap: "
    message_time:       .asciz "Time: "
    message_pace:       .asciz "Pace: "

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

    ; Display: Setup I2C as Master
    RCALL I2C_init

    ; Timer: Clear register
    CLR R26
    CLR R27

    ; All: Enable interrupt
    LDI R16, (0<<ISC11) || (0<<ISC10) || (0<<ISC01) || (0<<ISC00)
        STS EICRA, R16      ;Interrupts on low
    LDI R16, (1<<INT0) || (1<<INT1)
        OUT EIMSK, R16      ;Enable INT0 and INT1
    CLR R16

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

    ;convert waktu (seconds/kilometers)
    RCALL convert_disctance
    RCALL convert_to_minute
    RCALL convert_to_BCD        ;ubah detik ke bentuk BCD
    MOV R18, R17
    RCALL convert_to_BCD        ;ubah menit ke bentuk BCD
    ;tampilin pace ke lcd dan serial monitor
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
__vector_2:
    ;Disable clock
    LDI R28, 0b00000000
    STS TCCR1B, R28
    LDI R28, 1<<TOV1

    ;Clear TOV1 flag
    OUT TIFR1, R28
    LDI R28, 0b00000000
    SET 

    RETI

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_init:
    LDI   R21, 0
    STS   TWSR, R21       ;prescaler = 0
    LDI   R21, 12         ;division factor = 12
    STS   TWBR, R21       ;SCK freq = 400kHz
    LDI   R21, (1<<TWEN)
    STS   TWCR, R21       ;enable TWI
    RET

; ========= Button Selection =========
select_button:
    ; in r19, PINC

    ; lds   r16, PINC      ; Load PINC into r16
    ; sbrs  r16, 0         ; Skip if PC0 is high
    ; rjmp  set_500

    ; lds   r16, PINC
    ; sbrs  r16, 1
    ; rjmp  set_1000

    ; lds   r16, PINC
    ; sbrs  r16, 2
    ; rjmp  set_2000

    LDI R16, 0          ;default jarak = 500m
    LDS R5, PINC
    SBRC R5, 0
    ;SBIC PINC, 0
    LDI R16 , 0
    ;SBIC PINC, 1
    SBRC R5, 1
    LDI R16 , 1
    ;SBIC PINC, 2
    SBRC R5, 2
    LDI R16 , 2

    RET
;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_write:
    STS   TWDR, R22       ;copy SLA+W into data register
    LDI   R21, (1<<TWINT)|(1<<TWEN)
    STS   TWCR, R21       ;transmit SLA+W
    ;----------------------------------------------------------
wt2:LDS   R21, TWCR
    SBRS  R21, TWINT
    RJMP  wt2             ;wait for end of transmission
    RET

; ========= Set Distance Values =========
set_500:
    ldi r17, hi8(0x01F4)
    ldi r16, lo8(0x01F4)
    rjmp wait_start

set_1000:
    ldi r17, hi8(0x03E8)
    ldi r16, lo8(0x03E8)
    rjmp wait_start

set_2000:
    ldi r17, hi8(0x07D0)
    ldi r16, lo8(0x07D0)
    rjmp wait_start

; ========= Wait for Start Button (PD2) =========
wait_start:
    lds   r16, PIND
    sbrs  r16, 2
    rjmp wait_start
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
    rjmp main

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
    MOV R19, R23            ;puluhan = counter
    MOV R20, R18
    PUSH R20
    PUSH R19                ;masukkan hasil ke stack
    RET
;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
