#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

.equ LCD_DPRT, PORTD
.equ LCD_DDDR, DDRD
.equ LCD_DPIN, PIND
.equ LCD_CPRT, PORTB
.equ LCD_CDDR, DDRB
.equ LCD_CPIN, PINB
.equ LCD_RS, 0
.equ LCD_RW, 1
.equ LCD_EN, 2

.equ IR_SENSOR_PORT, PORTC
.equ IR_SENSOR_DDR, DDRC
.equ IR_SENSOR_PIN, PINC
.equ IR_SENSOR_LEFT, 0
.equ IR_SENSOR_RIGHT, 1

.equ LED_PORT, PORTB
.equ LED_DDR, DDRB
.equ LED_GREEN, 3
.equ LED_YELLOW, 4
.equ LED_RED, 5

.equ BUTTON_PORT, PORTC
.equ BUTTON_DDR, DDRC
.equ BUTTON_PIN, PINC
.equ BUTTON_RESTART, 2
.equ BUTTON_ENABLE, 3

.section .data
lap_count:      .byte 0
timer_counter:  .byte 0
timer_seconds:  .byte 0
timer_minutes:  .byte 0
system_enabled: .byte 0
pace_target:    .byte 0
pace_current:   .byte 0
ir_state_prev:  .byte 0

message_welcome:   .asciz "PaceGuard System"
message_ready:     .asciz "Ready to Start"
message_running:   .asciz "Running: "
message_lap:       .asciz "Lap: "
message_time:      .asciz "Time: "
message_pace:      .asciz "Pace: "
message_disabled:  .asciz "System Disabled"

.section .text
main:
    CALL init_ports
    CALL init_lcd
    CALL init_timer
    CALL display_welcome
    
    LDI R16, 0
    STS system_enabled, R16
    STS lap_count, R16
    STS timer_counter, R16
    STS timer_seconds, R16
    STS timer_minutes, R16
    STS pace_target, R16
    STS pace_current, R16
    STS ir_state_prev, R16

main_loop:
    CALL check_buttons
    
    LDS R16, system_enabled
    CPI R16, 0
    BREQ system_is_disabled
    
    CALL check_sensors
    CALL update_display
    RJMP main_loop
    
system_is_disabled:
    CALL display_disabled
    RJMP main_loop

init_ports:
    LDI R16, 0xFF
    OUT LCD_DDDR, R16
    LDI R16, 0x07
    OUT LCD_CDDR, R16
    
    LDI R16, 0x00
    OUT IR_SENSOR_DDR, R16
    LDI R16, 0x03
    OUT IR_SENSOR_PORT, R16
    
    LDI R16, 0x38
    OUT LED_DDR, R16
    LDI R16, 0x00
    OUT LED_PORT, R16
    
    LDI R16, 0x00
    OUT BUTTON_DDR, R16
    LDI R16, 0x0C
    OUT BUTTON_PORT, R16
    
    RET

init_lcd:
    CALL lcd_delay_ms
    CALL lcd_delay_ms
    
    LDI R16, 0x33
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x32
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x28
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x0E
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x01
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x06
    CALL lcd_command
    CALL lcd_delay_ms
    
    RET

init_timer:
    LDI R16, 0
    OUT TCNT0, R16
    LDI R16, 0b00000010
    OUT TCCR0B, R16
    LDI R16, 0b00000001
    STS TIMSK0, R16
    SEI
    RET

check_buttons:
    IN R16, BUTTON_PIN
    
    SBRS R16, BUTTON_RESTART
    CALL handle_restart
    
    SBRS R16, BUTTON_ENABLE
    CALL handle_enable
    
    RET

handle_restart:
    LDS R16, system_enabled
    CPI R16, 0
    BREQ restart_done
    
    LDI R16, 0
    STS lap_count, R16
    STS timer_counter, R16
    STS timer_seconds, R16
    STS timer_minutes, R16
    STS pace_current, R16
    
restart_done:
    CALL lcd_delay_ms
    RET

handle_enable:
    LDS R16, system_enabled
    COM R16
    ANDI R16, 0x01
    STS system_enabled, R16
    
    CPI R16, 0
    BRNE system_now_enabled
    
    LDI R16, 0x00
    OUT LED_PORT, R16
    
system_now_enabled:
    CALL lcd_delay_ms
    RET

check_sensors:
    IN R16, IR_SENSOR_PIN
    ANDI R16, 0x03
    
    LDS R17, ir_state_prev
    
    CP R16, R17
    BREQ no_ir_change
    
    MOV R18, R17
    OR R18, R16
    CPI R18, 0x03
    BRNE no_lap_counted
    
    EOR R17, R16
    CPI R17, 0x03
    BRNE no_lap_counted
    
    LDS R17, lap_count
    INC R17
    STS lap_count, R17
    
    LDS R17, timer_seconds
    LDS R18, lap_count
    CP R18, 0
    BREQ no_lap_counted
    
    MOV R19, R17
    LDI R20, 0
    
pace_calc_loop:
    CP R19, R18
    BRLO pace_calc_done
    SUB R19, R18
    INC R20
    RJMP pace_calc_loop

pace_calc_done:
    STS pace_current, R20
    
    LDS R17, pace_target
    LDS R18, pace_current
    
    CP R18, R17
    BRLO pace_too_fast
    
    CPI R18, 0
    BREQ no_pace_data
    
    MOV R19, R17
    LSR R19
    LSR R19
    LSL R19
    ADD R19, R17
    CP R18, R19
    BRSH pace_too_slow
    
    LDI R19, (1 << LED_GREEN)
    OUT LED_PORT, R19
    RJMP update_ir_state
    
pace_too_fast:
    LDI R19, (1 << LED_RED)
    OUT LED_PORT, R19
    RJMP update_ir_state
    
pace_too_slow:
    LDI R19, (1 << LED_YELLOW)
    OUT LED_PORT, R19
    RJMP update_ir_state
    
no_pace_data:
    LDI R19, 0
    OUT LED_PORT, R19
    
no_lap_counted:
no_ir_change:
update_ir_state:
    STS ir_state_prev, R16
    RET

display_welcome:
    LDI R16, 0x01
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x80
    CALL lcd_command
    
    LDI R30, lo8(message_welcome)
    LDI R31, hi8(message_welcome)
    CALL lcd_print_string
    
    LDI R16, 0xC0
    CALL lcd_command
    
    LDI R30, lo8(message_ready)
    LDI R31, hi8(message_ready)
    CALL lcd_print_string
    
    RET

display_disabled:
    LDI R16, 0x01
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x80
    CALL lcd_command
    
    LDI R30, lo8(message_disabled)
    LDI R31, hi8(message_disabled)
    CALL lcd_print_string
    
    RET

update_display:
    LDI R16, 0x01
    CALL lcd_command
    CALL lcd_delay_ms
    
    LDI R16, 0x80
    CALL lcd_command
    
    LDI R30, lo8(message_running)
    LDI R31, hi8(message_running)
    CALL lcd_print_string
    
    LDI R16, 0x88
    CALL lcd_command
    
    LDI R30, lo8(message_lap)
    LDI R31, hi8(message_lap)
    CALL lcd_print_string
    
    LDS R16, lap_count
    CALL lcd_print_byte
    
    LDI R16, 0xC0
    CALL lcd_command
    
    LDI R30, lo8(message_time)
    LDI R31, hi8(message_time)
    CALL lcd_print_string
    
    LDS R16, timer_minutes
    CALL lcd_print_byte
    
    LDI R16, ':'
    CALL lcd_data
    
    LDS R16, timer_seconds
    CALL lcd_print_byte
    
    LDI R16, ' '
    CALL lcd_data
    LDI R16, ' '
    CALL lcd_data
    
    LDI R30, lo8(message_pace)
    LDI R31, hi8(message_pace)
    CALL lcd_print_string
    
    LDS R16, pace_current
    CALL lcd_print_byte
    
    RET

lcd_print_string:
    LPM R16, Z+
    CPI R16, 0
    BREQ lcd_print_done
    CALL lcd_data
    RJMP lcd_print_string
lcd_print_done:
    RET

lcd_print_byte:
    MOV R17, R16
    LDI R18, 100
    LDI R19, 0
hundreds_loop:
    CPI R17, 100
    BRLO hundreds_done
    SUBI R17, 100
    INC R19
    RJMP hundreds_loop
hundreds_done:
    CPI R19, 0
    BREQ skip_hundreds
    SUBI R19, -48
    MOV R16, R19
    CALL lcd_data
skip_hundreds:

    MOV R18, R17
    LDI R19, 0
tens_loop:
    CPI R18, 10
    BRLO tens_done
    SUBI R18, 10
    INC R19
    RJMP tens_loop
tens_done:
    CPI R19, 0
    BRNE print_tens
    LDS R20, lap_count
    CPI R20, 10
    BRLO skip_tens
print_tens:
    SUBI R19, -48
    MOV R16, R19
    CALL lcd_data
skip_tens:

    MOV R16, R18
    SUBI R16, -48
    CALL lcd_data
    
    RET

lcd_command:
    CBI LCD_CPRT, LCD_RS
    CBI LCD_CPRT, LCD_RW
    OUT LCD_DPRT, R16
    SBI LCD_CPRT, LCD_EN
    CALL lcd_delay_us
    CBI LCD_CPRT, LCD_EN
    CALL lcd_delay_us
    RET

lcd_data:
    SBI LCD_CPRT, LCD_RS
    CBI LCD_CPRT, LCD_RW
    OUT LCD_DPRT, R16
    SBI LCD_CPRT, LCD_EN
    CALL lcd_delay_us
    CBI LCD_CPRT, LCD_EN
    CALL lcd_delay_us
    RET

lcd_delay_us:
    NOP
    NOP
    NOP
    NOP
    RET

lcd_delay_ms:
    LDI R20, 255
l1: LDI R21, 100
l2: DEC R21
    BRNE l2
    DEC R20
    BRNE l1
    RET

timer_overflow:
    PUSH R16
    IN R16, SREG
    PUSH R16
    
    LDS R16, timer_counter
    INC R16
    CPI R16, 122        
    BRNE store_timer
    
    LDI R16, 0
    STS timer_counter, R16
    
    LDS R16, timer_seconds
    INC R16
    CPI R16, 60
    BRNE store_seconds
    
    LDI R16, 0
    STS timer_seconds, R16
    
    LDS R16, timer_minutes
    INC R16
    STS timer_minutes, R16
    
    RJMP timer_done
    
store_seconds:
    STS timer_seconds, R16
    RJMP timer_done
    
store_timer:
    STS timer_counter, R16
    
timer_done:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

.global TIMER0_OVF_vect
TIMER0_OVF_vect:
    RJMP timer_overflow