#define __SFR_OFFSET 0x00
#include "avr/io.h"

;==============================================================

;   Register Usage Documentation
;   R16: Setup, distance state
;   R17: 
;   R18: 
;   R19: 
;   R20: 
;   R21: I2C
;   R22: I2C
;   R23: 
;   R24: 
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
    JMP     loop

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

    ;convert waktu (seconds/kilometers)
    RCALL convert_disctance
    RETI

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_init:
    LDI   R21, 0         
    -p 
    
    STS   TWSR, R21       ;prescaler = 0
    LDI   R21, 12         ;division factor = 12
    STS   TWBR, R21       ;SCK freq = 400kHz
    LDI   R21, (1<<TWEN)
    STS   TWCR, R21       ;enable TWI
    RET

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_startW:
    LDI   R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
    STS   TWCR, R21       ;transmit START condition
    ;----------------------------------------------------------
wtw:LDS   R21, TWCR
    SBRS  R21, TWINT      ;TWI interrupt = 1?
    RJMP  wtw             ;no, wait for end of transmission
    ;----------------------------------------------------------
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

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
I2C_stop:
    LDI   R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    STS   TWCR, R21       ;transmit STOP condition
    RET

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
    

;~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~;
