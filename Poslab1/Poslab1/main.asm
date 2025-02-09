//*********************************************************************
// Universidad del Valle de Guatemala
// IE2023: Programación de Microcontroladores
// Author : Thomas Solis
// Proyecto: PosLab1
// Descripción:Contador de 4 bits y Sumador.  
// Hardware: ATmega328p
// Created: 07/02/2025 14:20:18
//*********************************************************************
// Encabezado
//*********************************************************************
.include "M328PDEF.inc"  

.cseg
.org 0x0000
    rjmp SETUP  

// CONFIGURACIÓN DE LA PILA Y EL OSCILADOR
SETUP:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R17, HIGH(RAMEND)
    OUT SPH, R17
 //Configurar el oscilador interno a 1 MHz
    LDI R16, (1 << CLKPCE)  
    STS CLKPR, R16           ; Habilitar cambio de prescaler
    LDI R16, 0b00000011      ; Dividir 8 MHz entre 8 ? 1 MHz
    STS CLKPR, R16


//CONFIGURACIÓN DE PUERTOS
SETUP_IO:
    ; Configurar PB0-PB3 como salida (LEDs Contador 1)
    LDI R16, 0x0F
    OUT DDRB, R16
    OUT PORTB, R16  
    ; Configurar PD4-PD7 como salida (LEDs Contador 2)
    LDI R16, 0xF0
    OUT DDRD, R16
    OUT PORTD, R16  
    ; Configurar PC3-PC0 como salida (LEDs de resultado)
    LDI R16, 0x0F
    OUT DDRC, R16
    ; Configurar PB5 como salida (LED de carry)
    SBI DDRB, PB5
    ; Configurar PB4 como entrada con pull-up (Botón de suma)
    CBI DDRB, PB4
    SBI PORTB, PB4  
    ; Configurar PD2, PD3 como entrada con pull-up (Botones Contador 1)
    CBI DDRD, PD2
    CBI DDRD, PD3
    SBI PORTD, PD2  
    SBI PORTD, PD3  
    ; Configurar PC4, PC5 como entrada con pull-up (Botones Contador 2)
    CBI DDRC, PC4
    CBI DDRC, PC5
    SBI PORTC, PC4  
    SBI PORTC, PC5  
    ; Inicializar contadores
    LDI R17, 0x00   ; Contador 1
    LDI R18, 0x00   ; Contador 2

//LOOP PRINCIPAL
MAIN_LOOP:
    CALL CONTADOR1   ; Llamar al primer contador
    CALL CONTADOR2   ; Llamar al segundo contador

    ;Actualizar LEDs del Contador 1 en PB0-PB3 sin afectar otros pines
    IN R16, PORTB    
    ANDI R16, 0xF0   
    OR R16, R17      
    OUT PORTB, R16   

    ;Actualizar LEDs del Contador 2 en PD4-PD7 sin afectar otros pines
    IN R16, PORTD    
    ANDI R16, 0x0F   
    MOV R19, R18
    SWAP R19         
    OR R16, R19      
    OUT PORTD, R16   

    ;Verificar si se presionó el botón de suma (PB4)
    SBIC PINB, PB4   
    RJMP MAIN_LOOP   
    CALL MOSTRAR_SUMA  
    RJMP MAIN_LOOP   


//SUBRUTINA PARA MOSTRAR LA SUMA
MOSTRAR_SUMA:
    ; Sumar los contadores
    ADD R17, R18     
    MOV R16, R17     

    ; Mostrar el resultado en PC3-PC0
    ANDI R16, 0x0F   
    OUT PORTC, R16   

    ;Verificar si hay carry (suma > 15)
    BRCC NO_CARRY    
    SBI PORTB, PB5   
    RJMP FIN_SUMA
NO_CARRY:
    CBI PORTB, PB5   
FIN_SUMA:
    CALL DELAY       
    CALL ESPERAR_SUMA  
    RET


//SUBRUTINA CONTADOR 1

CONTADOR1:
    IN R19, PIND   
    SBRS R19, PD2  
    CALL INCREMENTO1
    SBRS R19, PD3  
    CALL DECREMENTO1
    RET            

//SUBRUTINA CONTADOR 2
CONTADOR2:
    IN R19, PINC   
    SBRS R19, PC5  
    CALL INCREMENTO2
    SBRS R19, PC4  
    CALL DECREMENTO2
    RET            


//FUNCIONES DE AUMENTO Y DECREMENTO PARA CONTADOR 1
INCREMENTO1:
    CALL DELAY
    INC R17
    ANDI R17, 0x0F  
    CALL ESPERAR1
    RET

DECREMENTO1:
    CALL DELAY
    DEC R17
    BRPL NO_UNDERFLOW1
    LDI R17, 15
NO_UNDERFLOW1:
    CALL ESPERAR1
    RET


//FUNCIONES DE AUMENTO Y DECREMENTO PARA CONTADOR 2
INCREMENTO2:
    CALL DELAY
    INC R18
    ANDI R18, 0x0F  
    CALL ESPERAR2
    RET

DECREMENTO2:
    CALL DELAY
    DEC R18
    BRPL NO_UNDERFLOW2
    LDI R18, 15

NO_UNDERFLOW2:
    CALL ESPERAR2
    RET


//RUTINA DE ANTIREBOTE (DELAY)
DELAY:
    LDI R20, 0xFF
DELAY_LOOP:
    DEC R20
    CPI R20, 0
    BRNE DELAY_LOOP
    RET


//ESPERAR1 A QUE SE SUELTE EL BOTÓN (CONTADOR 1)

ESPERAR1:
    IN R19, PIND
    SBRS R19, PD2  
    RJMP ESPERAR1
    SBRS R19, PD3  
    RJMP ESPERAR1
    CALL DELAY
    RET


//ESPERAR1 A QUE SE SUELTE EL BOTÓN (CONTADOR 2)

ESPERAR2:
    IN R19, PINC
    SBRS R19, PC5  
    RJMP ESPERAR2
    SBRS R19, PC4  
    RJMP ESPERAR2
    CALL DELAY
    RET


//ESPERAR1 A QUE SE SUELTE EL BOTÓN DE SUMA

ESPERAR_SUMA:
    SBIC PINB, PB4  
    RET
    RJMP ESPERAR_SUMA
