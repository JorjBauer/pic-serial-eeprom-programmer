;;; *********************************************************************
;;; * Global defines
;;; *

;; I2C serial clock and data. Two pins for each function for the sake of 
;; software simplicity. The 'input' pins are directly connected, and the 
;; 'output' pins (SDAo, SCLo) are connected via diodes (cathode toward the
;; output pin in question). See
;; http://www.sprut.de/electronic/pic/grund/i2c_soft.htm

#define SCLi    PORTB,4
#define SCLo    PORTB,6
#define SDAi    PORTB,5
#define SDAo    PORTB,7

#define BITBANG_ENABLED 0

#define TRISA_DATA	0x00 ; all outputs
#define TRISB_DATA	0x36 ; B[45] inputs; others outputs. B[21] USART.

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

;;; * fcall <subroutine>
;;; *
;;; * sets up pagesel appropriately for subroutine (using 'lcall'), and 
;;; * sets pagesel properly on return. Note that gpasm will properly 
;;; * do nothing on a 16f628a, which has only one page. This may also be 
;;; * true of other processors and compilers but is unconfirmed.
;;; *
fcall macro subroutine_name
      local dummy_fcall
      lcall subroutine_name
      pagesel $
      endm
