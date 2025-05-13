#define __SFR_OFFSET 0x00
#include "avr/io.h"

;==============================================================
    ; Pin Directives
    ; Digital: use in PORTD
    .def BTN_ENA 0
    .def BTN_RES 1

    ; LED: use in PORTB
    .def LED_RED 0
    .def LED_YEL 1
    .def LED_GRE 2

    ; Sensor: use in PORTD
    .def SENSOR_PIN 7

    ; Display: use in PORTC (LCD)
    .def LCD_SDA 4
    .def LCD_SCL 5

;==============================================================
; Pre-defined data
.global main
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
    ; All: Setup DDR
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
    STS   TWDR, R27       ;copy SLA+W into data register
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