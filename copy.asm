; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc
include    kernel.inc

           org     8000h
           lbr     0ff00h
           db      'copy',0
           dw      9000h
           dw      endrom+7000h
           dw      2000h
           dw      endrom-2000h
           dw      2000h
           db      0

           org     2000h
           br      start

include    date.inc
include    build.inc
           db      'Written by Michael H. Riley',0

start:     lda     ra                  ; move past any spaces
           smi     ' '
           lbz     start
           dec     ra                  ; move back to non-space character
           ldn     ra                  ; get character
           lbnz    good                ; jump if non-zero
           sep     scall               ; otherwise display usage
           dw      f_inmsg
           db      '1Usage: copy source dest',10,13,0
           sep     sret                ; and return to os
good:      mov     rf,source           ; point to source filename
good1:     lda     ra                  ; get byte from argument
           plo     re                  ; save for a moment
           smi     33                  ; check for space or less
           lbnf    good2               ; jump if termination of filename found
           glo     re                  ; recover byte
           str     rf                  ; write to source buffer
           inc     rf
           lbr     good1               ; loop back for more characters
good2:     ldi     0                   ; need to write terminator
           str     rf                  ; source filename is now complete
           glo     re                  ; recover byte
           lbnz    good3               ; jump if not terminator
           sep     scall               ; otherwise display usage
           dw      f_inmsg
           db      '2Usage: copy source dest',10,13,0
           sep     sret                ; and return
good3:     lda     ra                  ; move past any space
           smi     ' '
           lbz     good3
           dec     ra                  ; move back to non-space character
           ldn     ra                  ; get character
           lbnz    good4               ; jump if not terminator
           sep     scall               ; otherwise display usage
           dw      f_inmsg
           db      '3Usage: copy source dest',10,13,0
           sep     sret                ; and return to os
good4:     mov     rf,dest             ; point to destination filename
good5:     lda     ra                  ; get byte from argument
           plo     re                  ; save for a moment
           smi     33                  ; check for space or less
           lbnf    good6               ; jump if terminator
           glo     re                  ; recover byte
           str     rf                  ; store into buffer
           inc     rf
           lbr     good5               ; loop back to copy rest of name
good6:     ldi     0                   ; need terminator
           str     rf
           mov     rf,source           ; point to source filename
           ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     0                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbnf    opened              ; jump if file was opened
           ldi     high errmsg         ; get error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           lbr     o_wrmboot           ; and return to os
opened:    ghi     rd                  ; make copy of descriptor
           phi     r7
           glo     rd
           plo     r7
           mov     rf,dest             ; point to destination filename
           ldi     high dfildes        ; get file descriptor
           phi     rd
           ldi     low dfildes
           plo     rd
           glo     r7                  ; save first descriptor
           stxd
           ghi     r7
           stxd
           ldi     3                   ; flags for open, create if nonexist
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbnf    opened2
           mov     rf,errmsg2          ; point to error message
           sep     scall               ; and display it
           dw      o_msg
           lbr     o_wrmboot
opened2:   irx                         ; recover first descriptor
           ldxa
           phi     r7
           ldx
           plo     r7
           ghi     rd                  ; make copy of descriptor
           phi     r8
           glo     rd
           plo     r8
mainlp:    ldi     0                   ; want to read 255 bytes
           phi     rc
           ldi     255
           plo     rc 
           ldi     high buffer         ; buffer to rettrieve data
           phi     rf
           ldi     low buffer
           plo     rf
           ghi     r7                  ; get descriptor
           phi     rd
           glo     r7
           plo     rd
           sep     scall               ; read the header
           dw      o_read
           lbnf    readgd
           sep     scall               ; display error on reading
           dw      f_inmsg
           db      'File read error',10,13,0
           lbr     done                ; return to OS
readgd:    glo     rc                  ; check for zero bytes read
           lbz     done                ; jump if so
           ldi     high buffer         ; buffer to rettrieve data
           phi     rf
           ldi     low buffer
           plo     rf
           ghi     r8                  ; get descriptor
           phi     rd
           glo     r8
           plo     rd
           sep     scall               ; write to destination file
           dw      o_write
           lbnf    mainlp              ; loop back if no errors
           sep     scall               ; otherwise display error
           dw      f_inmsg
           db      'File write error',10,13,0
done:      sep     scall               ; close the file
           dw      o_close
           ghi     r8                  ; get destination descriptor
           phi     rd
           glo     r8
           plo     rd
           sep     scall               ; and close it
           dw      o_close
           lbr     o_wrmboot
           sep     sret                ; return to os



           

errmsg:    db      'File not found',10,13,0
errmsg2:   db      'Could not open destination',10,13,0
fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0
dfildes:   db      0,0,0,0
           dw      ddta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

endrom:    equ     $

source:    ds      256
dest:      ds      256
dta:       ds      512
ddta:      ds      512
buffer:    db      0

