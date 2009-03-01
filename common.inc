;;; *********************************************************************
;;; * Global defines
;;; *

;; I2C serial clock and data. Two pins for each function for the sake of 
;; software simplicity. The 'input' pins are directly connected, and the 
;; 'output' pins (SDAo, SCLo) are connected via diodes (anode toward the
;; output pin in question). See
;; http://www.sprut.de/electronic/pic/grund/i2c_soft.htm

#define SCLi    PORTB,5
#define SCLo    PORTB,0
#define SDAi    PORTB,4
#define SDAo    PORTB,3

#define BITBANG_ENABLED 0

#define TRISA_DATA	0x00
#define TRISB_DATA	0xB6

;;; *********************************************************************
;;; * Useful macros:
;;; *
;;; *
;;; * SKPWGT: skip if W greater than
;;; * SKPWLE: skip if W less than
;;; *
;;; * Usage: 
;;; *
;;; * movlw (value1)
;;; * sublw (value2)
;;; * skpwgt            ; will skip if (value1) > (value2)
;;; *

#define SKPWGT  SKPNC
#define skpwgt  skpnc
#define SKPWLE SKPC
#define skpwle skpc
