        Processor       16f627
        Radix           DEC
        EXPAND

        include         "p16f627.inc"

;; Constants specific to this processor - what pins are the serial pins? Do we 
;; want serial to auto-echo? At what baud rate? (see serial.asm)
#define USART_TX_TRIS PORTB, 2
#define USART_RX_TRIS PORTB, 1
#define USART_ECHO 0
#define USART_HIGHSPEED 0
#define USART_BAUD_INITIALIZER 12
