;this code provides keyboard interface, and interrupt handler
;allows to block certain keys and provides decode table
;
;macros
;
;procedures
;	[B] keyboard_handler
;		argc: -
;		argv: -
;		desc: interrupt used to handle keys
;data
;	[B] key_to_hex_table
;	[B] keyboard_buffer
;	[B] keyboard_buffer_ind
;	[B] keyboard_buffer_new
;	[B] keyboard_enable_flag
;	[B] keyboard_panic_loc
;		desc: where to jump in case of panic key


align 16
key_to_hex_table:                                 ;start of line is
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x00 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x08 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x10 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x18 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x20 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x28 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x30 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x38 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x40 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x48 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x50 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x58 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x60 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x68 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x70 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0x78 
db  0x0,  0x80, '1',  '2',  '3',  '4',  '5',  '6' ;0x80  
 db '7',  '8',  '9',  '0',  0x0,  0x0,  0x0,  0x0 ;0x88 
db  'Q',  'W',  'F',  'P',  'G',  'J',  'L',  'U' ;0x90  
 db 'Y',  0x0,  0x0,  0x0,  0x0A, 0x0,  'A',  'R' ;0x98  
db  'S',  'T',  'D',  'H',  'N',  'E',  'I',  'O' ;0xA0  
 db 0x0,  0x0,  0x0,  0x0,  'Z',  'X',  'C',  'V' ;0xA8  
db  'B',  'K',  'M',  0x0,  0x0,  0x0,  0x0,  0x0 ;0xB0 
 db 0x0,  ' ',  0x08, 0x0,  0x0,  0x0,  0x0,  0x0 ;0xB8 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0xFF;0xC0 
 db 0xC0, 0x0,  0x0,  0xC1, 0x0,  0xC2, 0x0,  0x0 ;0xC8 
db  0xC3, 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0xD0 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0xD8 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0xE0 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0xE8 
db  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0xF0 
 db 0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0,  0x0 ;0xF8 

%define KEYBOARD_ENABLE_ARROWS   0b00000001
%define KEYBOARD_ENABLE_CONTROL  0b00000010
%define KEYBOARD_ENABLE_LETTERS  0b00000100
%define KEYBOARD_ENABLE_NUMBERS  0b00001000
%define KEYBOARD_ENABLE_PANIC    0b00010000

keyboard_buffer        dq  0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
                       dq  0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
keyboard_buffer_ind    dd  0x0
keyboard_buffer_new    db  0x0

keyboard_enable_flag   db  0x0

keyboard_panic_loc     dd  0x0

align 16
keyboard_handler:
	cli
	pushad

.load:
	in  	al, 0x60
	
	movzx 	eax, al
	mov 	dl, BYTE [key_to_hex_table + eax]
	test 	dl, dl
	jz 		.not_add
	mov 	dh, dl
	and 	dh, 0b11110000 ; used to determine whether we ignore it

.check0:
	test 	BYTE [keyboard_enable_flag], KEYBOARD_ENABLE_ARROWS
	jnz 	.check1
	cmp 	dh, 0xC0
	je 		.not_add
.check1:
	test 	BYTE [keyboard_enable_flag], KEYBOARD_ENABLE_CONTROL
	jnz 	.check2
	cmp 	dh, 0x80
	je 		.not_add
.check2:
	test 	BYTE [keyboard_enable_flag], KEYBOARD_ENABLE_LETTERS
	jnz 	.check3
	cmp 	dl, 'A' 
	jl 		.check3
	cmp 	dl, 'Z' 
	jg  	.check3

	jmp 	.not_add
.check3:
	test 	BYTE [keyboard_enable_flag], KEYBOARD_ENABLE_NUMBERS
	jnz  	.check4
	cmp 	dh, 0x30
	je 		.not_add
.check4:
	test 	BYTE [keyboard_enable_flag], KEYBOARD_ENABLE_PANIC
	jz  	.check5
	cmp 	dl, 0xFF 
	jne 	.check5
	jmp		DWORD [keyboard_panic_loc]

.check5:
.add:
	;yup this can override memory
	;i may cry somewhere in the future when it breaks 
	mov 	eax, DWORD [keyboard_buffer_ind]
	mov 	BYTE [keyboard_buffer + eax], dl
	inc 	DWORD [keyboard_buffer_ind]
	mov 	BYTE [keyboard_buffer_new], 0x1

.not_add:
	popad
	sti
	ret


