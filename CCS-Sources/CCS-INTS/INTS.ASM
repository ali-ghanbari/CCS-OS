;ATTENTION! PAY ATTENTION TO <<DS>> AND <<ES>> RELATIONS IN CHECK_PATH AND FILL_ARRAY_WITH_ZERO FUNCTIONS!!!

;INTS.asm
.model tiny
.586

NORMAL     equ 0
READONLY   equ 1
HIDDEN     equ 2
FOLDER     equ 4
V_FOLDER   equ 8 ;not supported by CCS 10 
DELETED    equ 10h
PROTECTED  equ 20h
IS_FILE    equ 0f1h

.code
org 100h
prog_entry:
jmp start_code
nop
         fdd_check_error: db 0ah, 0dh, "There is not installed F.D.Drive on your system.", 0
         ccs_security_sys_msg: db 0ah, 0dh, "CCS-OS Security System", 0
         the_msg: db 0ah, 0dh, "The ", 0
         the_file_msg: db "file '", 0
         the_folder_msg: db "folder '", 0
         next_part_of_ss_msg: db "' which you want to access is protected.", 0ah, 0dh
                             db "You must enter a valid password to access it.", 0 
         password_msg: db 0ah, 0dh, "Password: ", 0
         invalid_pass_msg: db 0ah, 0dh, "Invalid Password.", 0
         valid_pass_msg: db 0ah, 0dh, "Password Accepted.", 0
         fatal_err_msg: db 0ah, 0dh, "CCS-OS", 0ah, 0dh
                     db "fatal error 1 : an error detected during delete operation that may damage your file system."
                     db 0ah, 0dh, "We are sorry that we couldn't help you we try to solve this problem in other versions"
                     db " of CCS-OS.", 0ah, 0dh, 0
         read_only_msg: db 0ah, 0dh, "CCS-OS", 0ah, 0dh
                     db "Info : If you say NO; CCS-OS will cancel delete operation and user interface will "
                     db "show an error; that is not important.", 0ah, 0dh 
                     db "One of entries is read only, do you want continue [y/n] ? ", 0
         
         welcome_msg: db 0ah, 0dh, "CCS-OS 10 Basic I/O Interrupt Services", 0ah, 0dh
                      db "Copyright (C) 2001-2006 by Ali Ghanbari.", 0
         install_int20h_msg: db 0ah, 0dh, "Configuring service #20h at (0x0000:0x0080)...", 0ah, 0dh, 0
         
         root_dir: db "(root)", 0
         viewing_msg: db 0ah, 0dh, "Viewing directory '", 0
         view_msg_0: db "' inside:", 0ah, 0dh, 0
         hidden_msg: db 0ah, 0dh, "[HIDDEN]", 0
         
         dir_err: db 0ah, 0dh, "An error detected;", 0
    
         pass_msg_0: db "  ][", 0
         pass_msg_1: db "  []", 0
         
         w0: dw ?
         w1: dw ?
         w2: dw ?
         w3: dw ?
         w4: dw ?
         w5: dw ?
         w6: dw ?
         w7: dw ?
         
         active_page: db ?
         
         b0: db ?
         b1: db ?
         b2: db ?
         b3: db ?
         b4: db ?
         b5: db ?
         b6: db ?
         b7: db ?
         
         current_file_entry_sec_ptr: db ?
         current_file_entry_ptr: dw ?
         dsm: dw ?
         st_pt1: dw ? ;for listing
         st_pt2: dw ? ;for pathing 
         
         file_entry_sec: db 512 dup (?)
         file_pt_table: dw 256 dup (?)
         file_entry: db 32 dup (?)
         
         fn0: db 16 dup (?)
         fn1: db 16 dup (?)
         fn2: db 16 dup (?)
         eop0: db 5 dup (?)
         eop1: db 5 dup (?)
         eop2: db 5 dup (?)
         eop3: db 5 dup (?)
         eop4: db 5 dup (?)
         fdate0: db 9 dup (?)
         fp: db 52 dup (?) 
         st_val: dw 4 dup (?)
         ;ATTENTION st_val must be valued follow this model:
         ;0 - 1 : c_fe_sp (word)
         ;2 - 3 : c_fe_p (word)
         ;4 - 5 : dsm_n (word)
         st_dat1: dw 512 dup (?) ;for listing
         st_dat2: dw 512 dup (?) ;for pathing

         _ip_val: dw ?
         _cs_val: dw ?
         _sp_val: dw ?
         _flags: dw ?     
start_code:

call _main ;Jump to main function
retf ;Exit ints(sse)

;al = the character
put_char proc near
         push ax
         push bx
         mov ah, 0eh
         mov bx, 7
         int 10h
         pop bx
         pop ax
         ret
put_char endp

;address of string = ds:si
print_str proc near
         push ax
         push si
         pushf
         cld
print_ch:
         lodsb
         cmp al, 0
         je exit_print_str_func
         call put_char
         jmp print_ch
exit_print_str_func:
         popf          
         pop si
         pop ax
         ret
print_str endp

;str addr = ds:si
;cx = str len
str_len proc near
         push si
         xor cx, cx
         jmp check_str_first_time
check_str:
         inc si
         inc cx
check_str_first_time:
         cmp byte ptr [si], 0
         jne check_str
         pop si
         ret
str_len endp

;al = got ch
getch proc near
         xor ah, ah
         int 16h
         ret
getch endp

;al = got ch
getche proc near
         xor ah, ah
         int 16h
         call put_char
         ret
getche endp

;first string address = ds:si
;second str address = es:di
;ah = 1 str is match, 0 str is not match
str_comp proc near
         push cx
         push si
         push di
         ;ds:si is set
         call str_len
         ;cx is set
         inc cx
         repe cmpsb
         je str_comp_is_match
         xor ah, ah
         jmp end_str_comp_func
str_comp_is_match:
         mov ah, 1
end_str_comp_func:        
         pop di
         pop si
         pop cx
         ret
str_comp endp

;address of buffers = es:di
get_str proc near
         push ax
         push cx
         push di
         or cx, cx
get_str_loop:
         call getch
         cmp al, 13
         je exit_get_str_loop
         cmp al, 8
         jne get_str_not_bs
         cmp cx, 0
         jle get_str_cx_le0
         dec cx
         dec di
         mov byte ptr es:[di], 0
         call put_char
         mov al, 20h
         call put_char
         mov al, 8
         call put_char
get_str_cx_le0:
         jmp get_str_loop
get_str_not_bs:
         mov byte ptr es:[di], al
         call put_char
         inc di
         inc cx    
         jmp get_str_loop
exit_get_str_loop:
         mov byte ptr es:[di], 0
         pop di
         pop cx
         pop ax
         ret
get_str endp

;address of buffers = es:di
get_pass proc near
         push ax
         push cx
         push di
         xor cx, cx
get_pass_loop:
         call getch
         cmp al, 13
         je exit_get_pass_loop
         cmp al, 8
         jne get_pass_not_bs
         cmp cx, 0
         jle get_pass_cx_le0
         dec cx
         dec di
         mov byte ptr es:[di], 0
         call put_char
         mov al, 20h
         call put_char
         mov al, 8
         call put_char
get_pass_cx_le0:
         jmp get_pass_loop
get_pass_not_bs:
         mov byte ptr es:[di], al
         mov al, '*'
         call put_char
         inc di
         inc cx    
         jmp get_pass_loop
exit_get_pass_loop:
         mov byte ptr es:[di], 0
         pop di
         pop cx
         pop ax
         ret
get_pass endp

;pass str addr = ds:si
;ah = 1  the pass is valid, 0 if the pass is invalid
;WARNING THE ARRAY DATA <<eop0>> WILL BE LOST!
get_comp_pass proc near
         push bp
         push di
         xor bp, bp
get_comp_pass_ring:
         call getch         
         cmp al, 13
         je get_comp_pass_enter_pressed
         cmp al, 8
         jne not_bs
         cmp bp, 0
         jle get_comp_pass_bp_le0
         dec bp
         mov cs:[eop0][bp], 0
         call put_char
         mov al, 20h
         call put_char
         mov al, 8
         call put_char
get_comp_pass_bp_le0:
         jmp get_comp_pass_ring
not_bs:
         mov byte ptr cs:[eop0][bp], al 
         mov al, '*'
         call put_char
         inc bp
         cmp bp, 4
         je get_comp_pass_enter_pressed
         jmp get_comp_pass_ring
get_comp_pass_enter_pressed:
         ;ds and si are set
         push es
         push cs
         pop es             
         mov cs:[eop0][bp], 0
         mov di, eop0
         call str_comp         
         pop es                  
get_comp_pass_end_func:
         pop di                                
         pop bp
         ret
get_comp_pass endp

;ax = the integer number
disp_num proc near
          push bx
          push dx
          mov bx, 10000
          call to_deci
          mov bx, 1000
          call to_deci
          mov bx, 100
          call to_deci
          mov bx, 10
          call to_deci
          add al, 30h
          call put_char
          pop dx
          pop bx
          ret
to_deci:
          xor dx, dx
          div bx
          add al, 30h
          push dx
          call put_char
          pop ax
          ret
disp_num endp

;dl = first f.d.d
find_first_fdd proc near
          push ax
          push cx
          xor cx, cx
          jmp find_fdd_for_first_time
find_fdd:
          inc cl
          cmp cl, 7f
          je error_fdd_not_found
          jmp find_fdd_for_first_time
error_fdd_not_found:  
          push ds
          push cs
          pop ds            
          mov si, fdd_check_error
          call print_str
          pop ds
          call getch
          int 19h   ;reboot the system
find_fdd_for_first_time:
          mov ah, 15h
          mov dl, cl
          int 13h
          cmp ah, 1
          jne next_ah_check
          jmp fdd_found
next_ah_check:
          cmp ah, 2
          jne find_fdd
fdd_found:
          pop cx
          pop ax
          ret
find_first_fdd endp

;index = si
;di = new index
;w0 = sector
convert_fdd_fptt_index2sec proc near
          push ax
          push bx
          push cx
          push dx
          mov ax, si
          dec ax
          xor dx, dx
          mov cx, 256
          div cx
          mov bx, ax
          mov cx, 256
          mul cx
          mov di, si
          sub di, ax
          mov word ptr cs:[w0], bx
          inc word ptr cs:[w0]
          pop dx
          pop cx
          pop bx
          pop ax
          ret 
convert_fdd_fptt_index2sec endp

;sector number = cs:[w0]
;sectors count = cs:[b0]
;buffer's segment = es
;buffer's offset = bx
;ah = 0 success 1 fail
read_fdd_sector proc near
         push bx
         push cx
         push dx 
               
         mov ax, word ptr cs:[w0]
         mov cl, byte ptr cs:[b0]
         xor ch, ch
read_fdd_sector_main_loop:                 
         push cx
         push ax
         mov cl, 18                  
         div cl                      
         mov cl, ah                  
         inc cl                      
         xor ah, ah
         mov dl, 2                    
         div dl
                                                
         mov dh, ah
         xor dl, dl 
         mov ch, al            

         mov ax, 0201h
		 int 13h		 
		 ;jc read_fdd_sector_give_error
		 pop ax
		 pop cx
         inc ax                 
         dec cx
         jz read_fdd_sector_success
         add bx, 512
         jmp read_fdd_sector_main_loop
read_fdd_sector_success:
         xor ah, ah
         jmp read_fdd_sector_end_func
read_fdd_sector_give_error:
         pop cx
         pop cx   
         mov ah, 1               
read_fdd_sector_end_func:

         pop dx
         pop cx
         pop bx
         ret
read_fdd_sector endp

;sector number = cs:[w0]
;sectors count = cs:[b0]
;buffer's segment = es
;buffer's offset = bx
;ah = 0 success 1 fail
write_fdd_sector proc near
         push bx
         push cx
         push dx 
               
         mov ax, word ptr cs:[w0]
         mov cl, byte ptr cs:[b0]
         xor ch, ch
write_fdd_sector_main_loop:             
         push cx
         push ax
         mov cl, 18 
         cbw                 
         idiv cl                      
         mov cl, ah                  
         inc cl                      
         xor ah, ah
         mov dl, 2                    
         idiv dl
                                                
         mov dh, ah
         xor dl, dl 
         mov ch, al            

         mov ax, 0301h
                  
		 int 13h
		 jc write_fdd_sector_give_error
		 pop ax
		 pop cx
         inc ax                 
         dec cx
         jz write_fdd_sector_success
         add bx, 512
         jmp write_fdd_sector_main_loop
write_fdd_sector_success:
         xor ah, ah
         jmp write_fdd_sector_end_func               
write_fdd_sector_give_error:
         pop cx
         pop cx  
         mov ah, 1                
write_fdd_sector_end_func:

         pop dx
         pop cx
         pop bx
         ret
write_fdd_sector endp

;ah = status : 1 error 0 file got 2 EOFE
get_file_entry proc near
          push bx
          push cx
          push dx
          push si
          push di
          push word ptr cs:[w0]
          
          cmp word ptr cs:[current_file_entry_ptr], 512
          jne cfep_ne_512
          cmp word ptr cs:[dsm], 0ffffh
          jne get_file_entry_con001
          mov ah, 2
          jmp exit_func_get_file_entry
get_file_entry_con001:
          cmp word ptr cs:[dsm], 0ffeeh
          jne dsm_ne_ffee
          xor ah, ah
          mov al, byte ptr cs:[current_file_entry_sec_ptr]
          mov word ptr cs:[w0], ax
          mov byte ptr cs:[b0], 1
          ;setting es
          push es
          push cs
          pop es
          ;;;;;;;;;;;
          mov bx, file_entry_sec
          call read_fdd_sector
          pop es
          cmp ah, 0
          jne get_file_error
          mov word ptr cs:[current_file_entry_ptr], 0
          inc byte ptr cs:[current_file_entry_sec_ptr]
          jmp get_file_no_error
get_file_error:     
          mov ah, 1
          jmp exit_func_get_file_entry
get_file_no_error:
          jmp cfep_ne_512
dsm_ne_ffee:
          mov ax, word ptr cs:[dsm]
          mov word ptr cs:[w0], ax
          add word ptr cs:[w0], 35
          mov byte ptr cs:[b0], 1
          ;setting es
          push es
          push cs
          pop es
          ;;;;;;;;;;;
          mov bx, file_entry_sec
          call read_fdd_sector
          pop es
          cmp ah, 0
          jne get_file_error
          mov word ptr cs:[current_file_entry_ptr], 0
          mov si, word ptr cs:[dsm]
          call convert_fdd_fptt_index2sec
          mov byte ptr cs:[b0], 1
          ;setting es
          push es
          push cs
          pop es
          ;;;;;;;;;;;
          mov bx, file_pt_table
          call read_fdd_sector
          pop es
          cmp ah, 0
          jne get_file_error
          dec di
          
          mov ax, 2
          mul di
          mov di, ax
          
          push word ptr cs:[file_pt_table][di]
          pop word ptr cs:[dsm]
cfep_ne_512:
          mov si, word ptr cs:[current_file_entry_ptr]
          cmp cs:[file_entry_sec][si], 0
          jne fes_ne_0
          mov ah, 2
          jmp exit_func_get_file_entry
fes_ne_0:
          push es
          push ds
          push cs
          push cs
          pop es
          pop ds
          mov si, file_entry_sec
          add si, word ptr cs:[current_file_entry_ptr]
          mov di, file_entry
          mov cx, 32
          rep movsb
          pop ds
          pop es          
          add word ptr cs:[current_file_entry_ptr], 32
          xor ah, ah
exit_func_get_file_entry:
          pop word ptr cs:[w0] 
          pop di
          pop si
          pop dx
          pop cx
          pop bx
          ret            
get_file_entry endp

;no param
make_def_fids proc near
          mov word ptr cs:[dsm], 0ffeeh
          mov byte ptr cs:[current_file_entry_sec_ptr], 19
          mov word ptr cs:[current_file_entry_ptr], 512
          ret
make_def_fids endp

;file entry offset = si
;es:di = des buf address
get_file_name proc near  
          push cx
          push si
          push di
          push ds
          pushf
          
          mov si, file_entry
          push cs
          pop ds
          cld
          mov cx, 13
          rep movsb
                    
          popf
          pop ds
          pop di
          pop si
          pop cx 
          ret
get_file_name endp

;file entry offset = si
;es:di = des buf address
;ah = 0 entry(file/folder) has password, 1 if entry has not password 
get_file_password proc near
          push cx
          push si
          push di
          push ds
          
          push cs
          pop ds
          mov si, file_entry
          call get_file_attr
          and al, PROTECTED
          cmp al, PROTECTED
          jne get_file_password_file_has_not_password_1
          add si, 13
          mov al, byte ptr ds:[si]
          cmp al, 0
          je get_file_password_file_has_not_password_1
          cmp al, 0abh
          je get_file_password_file_has_not_password_1
          mov cx, 3
passwording:
          lodsb  
          cmp al, 0
          je exit_passwording
          xor al, 0abh ;password secret
          mov es:[di], al
          inc di
          loop passwording
exit_passwording:
          mov byte ptr es:[di], 0       
          xor ah, ah
          jmp get_file_password_end_func
get_file_password_file_has_not_password_1:
          mov ah, 1                               
get_file_password_end_func: 
          
          pop ds
          pop di
          pop si
          pop cx
          ret        
get_file_password endp

;file entry buf address = si
;es:di = des buf address
get_file_ext proc near
          push cx
          push si
          push di
          push ds
          pushf
          
          mov si, file_entry
          push cs
          pop ds
          cld
          add si, 16
          mov cx, 3
          rep movsb
          
          popf
          pop ds
          pop di
          pop si
          pop cx
          ret   
get_file_ext endp

;file entry buf address = si
;al = attrs
get_file_attr proc near
          mov si, file_entry
          mov al, cs:[si + 19]
          ret
get_file_attr endp

;file entry buf address = si
;es:di = fdate
get_file_date proc near
          push ax
          push cx
          push si
          push di
          push ds
          
          push cs
          pop ds
          mov si, file_entry
          add si, 20
          mov al, byte ptr ds:[si]
          xor ah, ah
          add ax, 2000
          mov es:word ptr [di], ax
          add di, 2
          inc si
          mov cx, 5
get_file_date_ring:
          mov al, byte ptr cs:[si]
          mov es:[di], al
          inc si
          inc di
          loop get_file_date_ring
          
          pop ds
          pop di
          pop si
          pop cx
          pop ax
          ret
get_file_date endp 

;file entry buf address = si
;cs:[w0] = file size
;cs:[w1] = next part
get_file_size proc near
          push ax
          mov si, file_entry    
          mov ax, word ptr cs:[si + 26]
          mov word ptr cs:[w0], ax
          mov ax, word ptr cs:[si + 28]
          mov word ptr cs:[w1], ax
          pop ax
          ret    
get_file_size endp

;file entry buf address = si
;ax = file starting block
get_file_starting_block proc near
          mov si, file_entry
          mov ax, word ptr cs:[si + 30]              
          ret              
get_file_starting_block endp

;character = al
;ah = 1 is valid, 0 is invalid
is_valid_char proc near 
      cmp al, 20h ;Space
      je is_valid_char_l
      cmp al, '_' ;UL
      je is_valid_char_l
      cmp al, 33
      jl is_not_valid_char
      cmp al, 39
      jle is_valid_char_l
      cmp al, 42
      jl is_not_valid_char
      cmp al, 45
      jle is_valid_char_l
      cmp al, 47
      jl is_not_valid_char
      cmp al, 126
      jle is_valid_char_l
is_valid_char_l:
      mov ah, 1
      jmp is_valid_char_end_func
is_not_valid_char:
      xor ah, ah        
is_valid_char_end_func:                 
      ret     
is_valid_char endp

;the array address = es:di
;count = cx
fill_array_with_zero proc near
          push cx           
          push di
          add cx, di
fill_array_wz_loop:
          mov byte ptr es:[di], 0
          inc di         
          cmp di, cx
          jne fill_array_wz_loop
          pop di
          pop cx           
          ret
fill_array_with_zero endp


;the path string addr = ds:si
;cs:[w3] = f_c
;cs:[w4] = dsm_n
;cs:[w5] = st_block
;cs:[b5] = other_attrs
;ah = 1 if error, 0 file is normal and valid, 3 file is valid and protected
;2 folder is normal, 4 folder is protected 
;WARNING ALL DATA IN THESE ARRAY'S WILL BE LOST <<fn0>>, <<fn1>>, <<eop0>>, <<eop1>>
check_path proc near
          push bx
          push cx
          push dx
          push si
          push di 
          pushf
          ;si is set
          call str_len
          cmp cx, 1
          jl check_path_give_error
          call make_def_fids
          mov word ptr cs:[w4], 0ffeeh
          cld
          ;si is set
check_path_main_loop:
          xor di, di
check_path_sub_loop_1:
          lodsb
          ;al is char
          call is_valid_char
          cmp ah, 0
          je exit_check_path_sub_loop_1
          mov byte ptr cs:[fn0][di], al
          inc di
          cmp di, 13
          jg check_path_give_error
          jmp check_path_sub_loop_1
exit_check_path_sub_loop_1: 
          mov byte ptr cs:[fn0][di], 0          
          cmp di, 0
          je check_path_give_error
          cmp al, 0
          je al_is_zero
          cmp al, '.'
          je al_is_dot
          cmp al, '('
          jne check_path_give_error
al_is_para:
          xor di, di
          ;si is incrised
check_path_sub_loop_2:
          lodsb
          ;al is char
          call is_valid_char
          cmp ah, 0
          je exit_check_path_sub_loop_2
          mov byte ptr cs:[eop0][di], al
          inc di
          cmp di, 3
          jg check_path_give_error
          jmp check_path_sub_loop_2
exit_check_path_sub_loop_2:
          mov byte ptr cs:[eop0][di], 0
          cmp di, 0
          je check_path_give_error
          cmp al, ')'
          jne check_path_give_error
          cmp byte ptr ds:[si], 0
          jne check_path_give_error
          mov word ptr cs:[current_file_entry_ptr], 512
          mov word ptr cs:[w3], 1 ;x = 1
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          ;we don't need to push si reg into the stack
          ;because here is the final step of this function
          mov si, file_entry
          ;setting es
          push es
          push cs
          pop es
          mov di, fn1
          call get_file_name
          ;si is set
          ;es is set
          mov di, eop1
          call get_file_ext
          ;si is set
          call get_file_attr
          pop es
          ;;;;;;;;;;;
          ;al is attrs
          ;attrs backups
          mov byte ptr cs:[b3], al
          mov byte ptr cs:[b4], al
          mov byte ptr cs:[b5], al ;other_attrs 
          mov byte ptr cs:[b6], al
check_path_sub_loop_3:
          ;setting es and ds            
          push ds
          push es
          push cs
          push cs
          pop es
          pop ds
                      
          mov si, fn0
          ;es is set
          mov di, fn1
          call str_comp
          
          pop es
          pop ds
          ;;;;;;;;;;;;;;;;;;
          cmp ah, 1
          jne check_path_sub_loop_3_invalid_file
check_path_sub_loop_3_ok1:
          ;setting es and ds            
          push ds
          push es
          push cs
          push cs
          pop es
          pop ds
                          
          mov si, eop0
          ;es is set
          mov di, eop1
          call str_comp
          
          pop es
          pop ds
          ;;;;;;;;;;;;;;;;;;
          cmp ah, 1
          jne check_path_sub_loop_3_invalid_file
check_path_sub_loop_3_ok2:
          and byte ptr cs:[b3], DELETED
          cmp byte ptr cs:[b3], DELETED
          je check_path_sub_loop_3_invalid_file
check_path_sub_loop_3_ok3:
          and byte ptr cs:[b4], FOLDER
          cmp byte ptr cs:[b4], FOLDER
          jne exit_check_path_sub_loop_3
check_path_sub_loop_3_invalid_file:
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error          
          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn1
          call get_file_name
          ;si is set
          mov di, eop1
          call get_file_ext
          ;si is set
          call get_file_attr
          
          pop es
          ;;;;;;;;;;;
          ;al is attrs
          mov byte ptr cs:[b3], al
          mov byte ptr cs:[b4], al
          mov byte ptr cs:[b5], al ;other attrs
          mov byte ptr cs:[b6], al
          inc word ptr cs:[w3] ;x ++
          jmp check_path_sub_loop_3
exit_check_path_sub_loop_3:           
          ;cs:[w3] is set
          ;cs:[b5] is set
          mov si, file_entry
          call get_file_starting_block
          ;ax is file starting block
          mov word ptr cs:[w5], ax
          and byte ptr cs:[b6], PROTECTED             
          cmp byte ptr cs:[b6], PROTECTED
          jne check_path_file_is_not_pro
check_path_file_is_pro:
          mov ah, 3
          jmp check_path_end_func
check_path_file_is_not_pro:
          xor ah, ah
          jmp check_path_end_func                 
al_is_zero:
          mov word ptr cs:[current_file_entry_ptr], 512
          mov word ptr cs:[w3], 1
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          ;we don't need to push si reg into the stack
          ;because here is the final step of this function
          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          
          pop es
          ;;;;;;;;;;;
          ;al is attrs
          ;attrs backups
          mov byte ptr cs:[b3], al
          mov byte ptr cs:[b4], al
          mov byte ptr cs:[b5], al ;other_attrs 
          mov byte ptr cs:[b6], al
check_path_sub_loop_4:
          ;setting es and ds            
          push ds
          push es
          push cs
          push cs
          pop es
          pop ds

          mov si, fn0
          ;es is set
          mov di, fn1
          call str_comp
          
          pop es
          pop ds
          ;;;;;;;;;;;;;;;;;;
          
          cmp ah, 1
          jne check_path_sub_loop_4_invalid_fold
check_path_sub_loop_4_ok1:
          and byte ptr cs:[b3], DELETED
          cmp byte ptr cs:[b3], DELETED
          je check_path_sub_loop_4_invalid_fold
check_path_sub_loop_4_ok2:
          and byte ptr cs:[b4], FOLDER
          cmp byte ptr cs:[b4], FOLDER
          je exit_check_path_sub_loop_4
check_path_sub_loop_4_invalid_fold:
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          
          pop es
          ;;;;;;;;;;;
          ;al is attrs
          ;attrs backups
          mov byte ptr cs:[b3], al
          mov byte ptr cs:[b4], al
          mov byte ptr cs:[b5], al ;other_attrs 
          mov byte ptr cs:[b6], al
          inc word ptr cs:[w3] ;x++
          jmp check_path_sub_loop_4 
exit_check_path_sub_loop_4:
          ;cs:[w3] is set
          ;cs:[b5] is set
          mov si, file_entry
          call get_file_starting_block
          ;ax is starting block
          mov word ptr cs:[w5], ax
          and byte ptr cs:[b6], PROTECTED
          cmp byte ptr cs:[b6], PROTECTED
          jne check_path_fold_is_not_pro
check_path_fold_is_pro:
          mov ah, 4
          jmp check_path_end_func
check_path_fold_is_not_pro:
          mov ah, 2
          jmp check_path_end_func                                                                        
al_is_dot:
          cmp byte ptr ds:[si], 0
          je check_path_give_error
          mov word ptr cs:[current_file_entry_ptr], 512
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          ;ATTENTION
          ;WE NEED TO push si into the stack
          ;because here is not final step and there is some folders and sub folders and files after this
          push si
          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          
          pop es
          ;;;;;;;;;;;
          ;al is attrs
          ;attrs backups
          mov byte ptr cs:[b3], al
          mov byte ptr cs:[b4], al
          ;we don't need b5, in this version of CCS 
          mov byte ptr cs:[b6], al
check_path_sub_loop_5:
          ;setting es and ds            
          push ds
          push es
          push cs
          push cs
          pop es
          pop ds
          
          mov si, fn0
          ;es is set
          mov di, fn1
          call str_comp
          
          pop es
          pop ds
          ;;;;;;;;;;;;;;;;;;
          cmp ah, 1
          jne check_path_sub_loop_5_invalid_fold
check_path_sub_loop_5_ok1:
          and byte ptr cs:[b3], DELETED
          cmp byte ptr cs:[b3], DELETED
          je check_path_sub_loop_5_invalid_fold
check_path_sub_loop_5_ok2:
          and byte ptr cs:[b4], FOLDER
          cmp byte ptr cs:[b4], FOLDER
          je exit_check_path_sub_loop_5
check_path_sub_loop_5_invalid_fold:
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error2
          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          
          pop es
          ;;;;;;;;;;;
          ;al is attrs
          ;attrs backups
          mov byte ptr cs:[b3], al
          mov byte ptr cs:[b4], al
          ;we don't need b5, in this version of CCS 
          mov byte ptr cs:[b6], al
          jmp check_path_sub_loop_5
exit_check_path_sub_loop_5:

          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, eop1
          call get_file_password
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 1
          je check_path_fold_has_not_password
          
          ;setting ds
          push ds
          push cs
          pop ds
                    
          mov si, ccs_security_sys_msg
          call print_str
          mov si, the_msg
          call print_str
          mov si, the_folder_msg
          call print_str
          mov si, fn1
          call print_str
          mov si, next_part_of_ss_msg
          call print_str
          mov si, password_msg
          call print_str
          
          pop ds
          ;;;;;;;;;;;
          ;pushing eop0 into the stack
          mov ah, byte ptr cs:[eop0][0]
          mov al, byte ptr cs:[eop0][1]
          push ax
          mov ah, byte ptr cs:[eop0][2]
          mov al, byte ptr cs:[eop0][3]
          push ax
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          push ds
          push cs
          pop ds
          mov si, eop1
          call get_comp_pass
          pop ds
          mov bh, ah
          ;taking cs:eop0 from stack
          pop ax
          mov byte ptr cs:[eop0][3], al
          mov byte ptr cs:[eop0][2], ah
          pop ax
          mov byte ptr cs:[eop0][1], al
          mov byte ptr cs:[eop0][0], ah
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          cmp bh, 1
          je check_path_valid_password
          ;setting ds
          push ds
          push cs
          pop ds
          
          mov si, invalid_pass_msg
          call print_str
          
          pop ds
          ;;;;;;;;;;;
          jmp check_path_give_error2
check_path_valid_password:
          ;setting ds
          push ds
          push cs
          pop ds
          
          mov si, valid_pass_msg
          call print_str
          
          pop ds
          ;;;;;;;;;;;    
check_path_fold_has_not_password:
          mov si, file_entry
          call get_file_starting_block
          mov word ptr cs:[dsm], ax
          mov word ptr cs:[w4], ax
          pop si
          cmp ax, 0
          je check_path_give_error
          jmp check_path_main_loop
check_path_give_error2:
          pop si                   
check_path_give_error:
          mov word ptr cs:[w3], 0
          mov word ptr cs:[w4], 0ffeeh
          mov word ptr cs:[w5], 0
          mov byte ptr cs:[b5], 0ffh
          mov ah, 1
check_path_end_func:
          popf
          pop di
          pop si
          pop dx
          pop cx
          pop bx
          ret 
check_path endp

;no param
new_line proc near
          push ax
          mov al, 0ah
          call put_char
          mov al, 0dh
          call put_char
          pop ax
          ret
new_line endp

;no param
insert_tab proc near
          push ax
          push cx
          mov cx, 8
ins_tab_loop:
          mov al, 20h
          call put_char
          loop ins_tab_loop    
          pop cx
          pop ax
          ret
insert_tab endp

;file path buf addr = ds:si
;file io handle buf addr = es:di
;WARNING ALL DATA IN THESE ARRAY'S WILL BE LOST <<fn0>>, <<fn1>>, <<eop0>>, <<eop1>>
openfile proc near
          push ax
          push si
          push di
          ;si and ds are set
          call check_path
          push ax
          mov ax, word ptr cs:[w3]
          mov word ptr es:[di], ax ;f_c
          mov ax, word ptr cs:[w4]
          mov word ptr es:[di + 2], ax ;dsm_n
          mov ax, word ptr cs:[w5]
          mov word ptr es:[di + 4], ax ;st_block
          mov al, byte ptr cs:[b5]
          mov byte ptr es:[di + 6], al ;other attrs
          pop ax
          cmp ah, 0
          je open_file_end_func  
open_file_ah_test_1:
          cmp ah, 3
          jne set_invalid_fh
          push di
          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn1
          call get_file_name
          mov di, eop4
          call get_file_ext
          ;es is set
          mov di, eop1
          call get_file_password
          
          pop es
          ;;;;;;;;;;;
          pop di
          
          cmp ah, 1
          je open_file_end_func
          
          ;setting es and ds
          push ds
          push es
          push cs
          push cs
          pop es
          pop ds
          
          mov si, ccs_security_sys_msg
          call print_str
          mov si, the_msg
          call print_str
          mov si, the_file_msg
          call print_str
          mov si, fn1
          call print_str
          mov al, '('
          call put_char
          mov si, eop4
          call print_str
          mov al, ')'
          call put_char
          mov si, next_part_of_ss_msg
          call print_str
          mov si, password_msg
          call print_str
          mov si, eop1
          call get_comp_pass
          
          pop es
          pop ds
          ;;;;;;;;;;;;;;;;;;
          cmp ah, 1
          je open_file_valid_password
          
          ;setting ds
          push ds
          push cs
          pop ds
          mov si, invalid_pass_msg
          call print_str
          pop ds
          ;;;;;;;;;;;
          jmp set_invalid_fh
open_file_valid_password:
          ;setting ds
          push ds
          push cs
          pop ds
          mov si, valid_pass_msg
          call print_str
          pop ds
          ;;;;;;;;;;;
          jmp open_file_end_func               
set_invalid_fh:
          mov word ptr es:[di], 0ffffh
          mov word ptr es:[di + 2], 0ffffh
          mov word ptr es:[di + 4], 0ffffh
          mov byte ptr es:[di + 6], 0ffh    
open_file_end_func:
          pop di
          pop si         
          pop ax
          ret
openfile endp

;file io handle buf addr = ds:si
;buffer addr = es:bx
;ah = 1 if file is empty (des buf will fill by 0xff), 0xff if eof, 0 if no error, 2 if read error 
readfile proc near
          push bx
          push cx
          cmp word ptr ds:[si + 4], 0
          jne read_file_f_input_nt
          mov cx, 512
read_file_loop:
          mov byte ptr es:[bx], 0ffh
          inc bx     
          loop read_file_loop
          mov ah, 1
          jmp read_file_end_func     
read_file_f_input_nt:
          cmp word ptr ds:[si + 4], 0ffffh
          je read_file_is_eof
          mov cx, word ptr ds:[si + 4]
          add cx, 35          
          mov word ptr cs:[w0], cx
          mov byte ptr cs:[b0], 1
          ;bx is set
          call read_fdd_sector
          cmp ah, 0
          jne read_file_error          
          ;;;;;;;;;;;
          mov cx, word ptr ds:[si + 4]
          push di
          push si
          mov si, cx
          call convert_fdd_fptt_index2sec
          mov byte ptr cs:[b0], 1
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          ;cs:w0 is set
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          pop si
          cmp ah, 0
          jne read_file_error
          ;converting byte to word
          dec di
          mov ax, 2
          mul di
          mov di, ax
          mov cx, word ptr cs:[file_pt_table][di]
          mov word ptr ds:[si + 4], cx
          pop di
          xor ah, ah 
          jmp read_file_end_func
read_file_error:
          mov ah, 2 
          jmp read_file_end_func     
read_file_is_eof:
          mov ah, 0ffh       
read_file_end_func:
          pop cx
          pop bx                    
          ret
readfile endp

;index = si
;di = new index
;cs:[w0] = sector
convert_fdd_dirt_index2sec proc near
          push ax
          push bx 
          push dx 
          push si           
          mov ax, 16
          mul si
          mov si, ax
          dec ax
          xor dx, dx
          mov bx, 512
          div bx
          xor dx, dx
          mov bx, 16
          div bx
          mov word ptr cs:[w0], ax
          mov bx, 16
          mul bx
          push ax
          xor dx, dx
          mov bx, 16
          mov ax, si
          div bx
          xor dx, dx
          mov bx, 32
          div bx
          mov di, ax
          pop ax
          sub di, ax 
          pop si           
          pop dx
          pop bx
          pop ax
          ret             
convert_fdd_dirt_index2sec endp

;file starting block = ax
;di = new index
;cs:[w0] = sector and status: 0xffff if error
find_eof proc near
          push ax
          push bx
          push si
          push word ptr cs:[w1]
          mov si, ax
          call convert_fdd_fptt_index2sec
          ;di = new index
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne find_eof_give_error
find_eof_main_loop:
          ;convert byte ptr 2 word ptr
          dec di
          mov ax, 2
          mul di
          mov di, ax 
          mov cx, word ptr cs:[file_pt_table][di] ;cx = j
          cmp cx, 0ffffh
          je exit_find_eof_main_loop
          push word ptr cs:[w0]
          mov si, cx
          call convert_fdd_fptt_index2sec
          push word ptr cs:[w0]
          pop word ptr cs:[w1]
          pop word ptr cs:[w0]
          mov bx, word ptr cs:[w1]
          cmp word ptr cs:[w0], bx
          je find_eof_main_loop
          push word ptr cs:[w1]
          pop word ptr cs:[w0]
          mov byte ptr cs:[b0], 1
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne find_eof_give_error
exit_find_eof_main_loop:
          cmp cx, 0ffffh
          jne find_eof_main_loop
          jmp find_eof_end_func
find_eof_give_error:
          mov word ptr cs:[w0], 0ffffh          
find_eof_end_func:
          pop word ptr cs:[w1]        
          pop si
          pop bx
          pop ax
          ret
find_eof endp

;no param
;di = new index
;cs:[w0] = sector and status: 0xffff is error
find_blank_block proc near
          push ax
          push bx
          push cx
          push si       
          push word ptr cs:[w1]
          mov word ptr cs:[w0], 0
          mov bx, 1 ;i = 1 first block
          mov cx, 4352 ;17 * 256
find_blank_block_main_loop:
          mov si, bx
          push word ptr cs:[w0]
          call convert_fdd_fptt_index2sec
          ;di = new index
          dec di
          mov ax, 2
          mul di
          mov di, ax
          ;cs:[w0] is set
          push word ptr cs:[w0]
          pop word ptr cs:[w1]
          pop word ptr cs:[w0]
          mov ax, word ptr cs:[w0]
          cmp word ptr cs:[w1], ax
          je w0_is_e2w1
          push word ptr cs:[w1]
          pop word ptr cs:[w0]
          push bx
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          pop bx
          cmp ah, 0
          jne find_blank_block_give_error
w0_is_e2w1:
          cmp word ptr cs:[file_pt_table][di], 0
          je find_blank_block_end_func
          inc bx                           
          loop find_blank_block_main_loop 
          jmp find_blank_block_give_error                     
exit_find_blank_block_main_loop:
          jmp find_blank_block_end_func                      
find_blank_block_give_error:
          mov word ptr cs:[w0], 0ffffh
find_blank_block_end_func:
          pop word ptr cs:[w1]
          pop si
          pop cx
          pop bx
          pop ax       
          ret       
find_blank_block endp

;file io handle addr = ds:si
;buffer addr = es:di
;next part = cs:[w2]
;ah = 0 if successful
writefile proc near
          push bx
          push cx
          push si
          push di
          push word ptr cs:[w0]
          push word ptr cs:[w1]
          push word ptr cs:[w2]
          push word ptr cs:[w3]
          push word ptr cs:[w4]
          cmp word ptr ds:[si], 0ffffh ;checking f_output
          je write_file_give_error
          push si
          push di
          mov bx, word ptr ds:[si]
          mov ax, 32
          mul bx
          mov si, ax
          call convert_fdd_dirt_index2sec
          mov word ptr cs:[w1], di
          inc word ptr cs:[w0]
          ;cs:[w0] is set          
          pop di
          pop si
                    
          ;cs:[w1] = di = new index
          cmp word ptr ds:[si + 2], 0ffeeh ;checking f_dsm
          jne write_file_f_dsm_is_not_ffee
          add word ptr cs:[w0], 18
          jmp write_file_l_1
write_file_f_dsm_is_not_ffee:
          dec word ptr cs:[w0]
          mov ax, word ptr ds:[si + 2]
          add word ptr cs:[w0], ax
          add word ptr cs:[w0], 35
write_file_l_1:
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_entry_sec
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          
          ;TIP: we don't need to give value to cs:[dsm] and cs:[current_file_entry_sec_ptr] because get_file_entry function
          ;doesn't read the disk and remember that we have read the sector.
          mov word ptr cs:[current_file_entry_ptr], 0
          mov cx, word ptr cs:[w1]
write_file_loop_1:
          call get_file_entry        
          loop write_file_loop_1
          
          sub word ptr cs:[current_file_entry_ptr], 32
          mov ax, word ptr cs:[current_file_entry_ptr]
          mov word ptr cs:[w1], ax ;j = cs:[w1] = cs:[current_file_entry_ptr] - 32;
          push si
          mov si, file_entry
          call get_file_attr
          pop si
          and al, READONLY
          cmp al, READONLY
          je write_file_give_error
          ;cs:[w3] = old_s
          push si
          push word ptr cs:[w0]
          push word ptr cs:[w1]
          mov si, file_entry
          call get_file_size
          push word ptr cs:[w0]
          pop word ptr cs:[w3]
          pop word ptr cs:[w1]
          pop word ptr cs:[w0] 
          pop si
          inc word ptr cs:[w3]
          mov ax, word ptr cs:[w3] ;new size
          mov bx, word ptr cs:[w1]
          mov byte ptr cs:[file_entry_sec][bx + 26], al
          mov byte ptr cs:[file_entry_sec][bx + 27], ah
          mov ax, word ptr cs:[w2] ;next part
          mov byte ptr cs:[file_entry_sec][bx + 28], al
          mov byte ptr cs:[file_entry_sec][bx + 29], ah
          dec word ptr cs:[w3]
          cmp word ptr cs:[w3], 0
          jne write_file_old_s_is_not_zero
          inc word ptr cs:[w3]
          push word ptr cs:[w0]
          push di
          call find_blank_block
          mov word ptr cs:[w3], di
          push word ptr cs:[w0]
          pop word ptr cs:[w4]
          pop di
          pop word ptr cs:[w0]
          ;cs:[w3] blank block's new index
          ;cs:[w4] blank block's sector
          
          push bx
          mov cx, 2
          xor dx, dx
          mov ax, word ptr cs:[w3]
          add ax, 2
          div cx
          mov bx, ax
          mov ax, word ptr cs:[w4]
          dec ax
          mov cx, 256
          mul cx
          add ax, bx
          pop bx
          
          mov word ptr cs:[file_entry_sec][bx + 30], ax
          ;mov byte ptr cs:[file_entry_sec][bx + 31], 7
          mov cx, ax
          ;cs:[w0] is set
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_entry_sec
          mov byte ptr cs:[b0], 1
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          mov word ptr cs:[w0], cx
          add word ptr cs:[w0], 35
          
          ;es is set         
          mov bx, di
          mov byte ptr cs:[b0], 1
          call write_fdd_sector
          cmp ah, 0
          jne write_file_give_error
          push word ptr cs:[w4]
          pop word ptr cs:[w0]
          
          ;setting es
          push es
          push cs
          pop es
          
          mov byte ptr cs:[b0], 1
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          mov bx, word ptr cs:[w4]
          dec bx
          mov ax, 256
          mul bx
          mov bx, cx
          sub bx, ax
          dec bx
          mov ax, 2
          mul bx
          mov bx, ax
          mov word ptr cs:[file_pt_table][bx], 0ffffh
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1

          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          mov word ptr ds:[si + 4], cx
          jmp write_file_end_func
write_file_old_s_is_not_zero:   
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_entry_sec
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          push si
          mov si, file_entry
          call get_file_starting_block
          pop si
          ;ax is file's starting block
          push di
          call find_eof
          mov word ptr cs:[w1], di ;cs:[w1] = di = new index
          pop di
          cmp word ptr cs:[w0], 0ffffh
          je write_file_give_error
          ;cs:[w0] is sector # in eof
          ;cs:[w1] is new index
          push di
          push word ptr cs:[w0]
          call find_blank_block
          mov ax, word ptr cs:[w0]
          mov word ptr cs:[w4], di
          pop word ptr cs:[w0]
          pop di
          cmp ax, 0ffffh
          je write_file_give_error
          push word ptr cs:[w4]
          pop word ptr cs:[w2]
          ;cs:[w2] is green blank block
          mov word ptr cs:[w3], ax
          inc word ptr cs:[w4]
          mov ax, word ptr cs:[w4]
          add ax, 2
          mov word ptr cs:[w4], 2
          xor dx, dx
          div word ptr cs:[w4]
          mov word ptr cs:[w4], ax
          ;now cs:[w3] is blank block's sector # & cs:[w4] is index #
          mov cx, word ptr cs:[w3]
          dec cx
          mov ax, 256
          mul cx
          add ax, word ptr cs:[w4]
          mov cx, ax
          ;inc cx
          ;cx is user understandable blank block's index #
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          mov bx, word ptr cs:[w1]
          mov word ptr cs:[file_pt_table][bx], cx
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          push word ptr cs:[w3]
          pop word ptr cs:[w0]
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          mov bx, word ptr cs:[w3]
          dec bx
          mov ax, 256
          mul bx
          mov bx, cx
          sub bx, ax
          dec bx
          mov ax, 2
          mul bx
          mov bx, ax
          mov word ptr cs:[file_pt_table][bx], 0ffffh
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne write_file_give_error
          mov word ptr cs:[w0], cx
          add word ptr cs:[w0], 35
          mov byte ptr cs:[b0], 1
          ;es is set
          xchg di, bx
          call write_fdd_sector
          cmp ah, 0
          jne write_file_give_error                            
          jmp write_file_end_func
write_file_give_error:
          mov ah, 1
write_file_end_func:
          pop word ptr cs:[w4]
          pop word ptr cs:[w3]            
          pop word ptr cs:[w2]
          pop word ptr cs:[w1]
          pop word ptr cs:[w0]
          pop di
          pop si
          pop cx
          pop bx
          ret
writefile endp

;st_block = cs:[w2]
;next_block = cx
;ax = preview block and status if zero error
;WARNING ALL DATA IN ARRAY'S <<file_pt_table>> WILL BE LOST!!!
find_prev_block proc near
          xor ah, ah
          mov al, byte ptr cs:[current_file_entry_sec_ptr]
          push bx
          push ax
          push word ptr cs:[current_file_entry_ptr]
          push word ptr cs:[dsm]
          push word ptr cs:[w0] 
          push word ptr cs:[w1]
          push word ptr cs:[w2]
          push cx
          push si
          push di
          mov si, word ptr cs:[w2]
          call convert_fdd_fptt_index2sec
          ;cs:[w0] is sector #
          ;di is new index
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1 
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne find_prev_block_give_error
          dec di
          mov ax, 2
          mul di
          mov di, ax
          push word ptr cs:[file_pt_table][di]
          pop word ptr cs:[w1]
          cmp word ptr cs:[w1], cx
          jne st_b_isnot_e2nb
          mov ax, word ptr cs:[w2]
          jmp find_prev_block_end_func
st_b_isnot_e2nb:
find_prev_block_main_loop:
          push word ptr cs:[w0]
          mov si, word ptr cs:[w1]
          call convert_fdd_fptt_index2sec
          push word ptr cs:[w0]
          pop word ptr cs:[w2]
          pop word ptr cs:[w0]
          ;cs:[w2] is sector #
          ;di is new index  
          mov bx, word ptr cs:[w2]
          cmp word ptr cs:[w0], bx
          je find_prev_block_w0e2w2_1
          push word ptr cs:[w2]
          pop word ptr cs:[w0]
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne find_prev_block_give_error
find_prev_block_w0e2w2_1:
          dec di
          mov ax, 2
          mul di
          mov di, ax
          push word ptr cs:[file_pt_table][di]
          pop word ptr cs:[w3]
          cmp word ptr cs:[w3], cx
          jne find_prev_block_w3_isnot_e2cx
          mov ax, word ptr cs:[w1]
          jmp find_prev_block_end_func
find_prev_block_w3_isnot_e2cx:
          mov si, word ptr cs:[w3]
          call convert_fdd_fptt_index2sec
          ;di is new index
          ;cs:[w0] is set
          mov bx, word ptr cs:[w2]
          cmp bx, word ptr cs:[w0]
          je find_prev_block_w0e2w2_2
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne find_prev_block_give_error
find_prev_block_w0e2w2_2:
          dec di
          mov ax, 2
          mul di
          mov di, ax
          push word ptr cs:[file_pt_table][di]
          pop word ptr cs:[w1]
          cmp word ptr cs:[w1], cx
          jne find_prev_block_main_loop
          mov ax, word ptr cs:[w3]      
          jmp find_prev_block_end_func              
find_prev_block_give_error:
          xor ax, ax                 
find_prev_block_end_func:
          pop di
          pop si               
          pop cx
          pop word ptr cs:[w2]
          pop word ptr cs:[w1]
          pop word ptr cs:[w0]               
          pop word ptr cs:[dsm]
          pop word ptr cs:[current_file_entry_ptr]
          pop bx
          mov byte ptr cs:[current_file_entry_sec_ptr], bl
          pop bx                 
          ret
find_prev_block endp

;path starting addr = ds:si
;cs:[w1] = dsm_n
;cs:[w2] = p_f_c
;cs:[w3] = p_dsm_n
;cs:[b1] = is file ?
;cs:fn2 = fn
;cs:eop2 = fe
;ah = status 1 if error
;ATTENTION, ALL DATA IN ARRAY'S <<eop0->eop2>> and <<fn0->fn2>> 
file_name_delim proc near
          push bx
          push cx
          push bp
          push si
          push di
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, eop2
          mov cx, 3
          call fill_array_with_zero
          mov di, eop1
          call fill_array_with_zero
          mov di, fn2
          mov cx, 13
          call fill_array_with_zero
          mov di, fn1
          call fill_array_with_zero
          
          pop es
          ;;;;;;;;;;;
          xor bx, bx
          xor bp, bp
file_name_delim_loop_1:
          mov word ptr cs:[w0], bx
file_name_delim_loop_2:
          mov al, byte ptr ds:[si + bp]
          call is_valid_char
          cmp ah, 1
          jne exit_file_name_delim_loop_2
          mov byte ptr cs:[fp][bx], al
          inc bx
          inc bp
          jmp file_name_delim_loop_2
exit_file_name_delim_loop_2:
          cmp word ptr cs:[w0], bx
          je file_name_delim_give_error
          cmp al, '('
          je file_name_delim_path_ok_1
          cmp al, '.'
          je file_name_delim_path_ok_1
          cmp al, 0
          jne file_name_delim_give_error
file_name_delim_path_ok_1:
          mov byte ptr cs:[fp][bx], al
          inc bx
          mov byte ptr cs:[fp][bx], 0
          inc bp
          cmp al, '.' ;or ds:[si][bp - 1] = al
          je file_name_delim_loop_1
          mov byte ptr cs:[fp][bp - 1], 0
          mov bx, bp
          dec bx
file_name_delim_loop_3:
          cmp byte ptr cs:[fp][bx], '.'
          je file_name_delim_sub_dir
          cmp bx, 0
          je file_name_delim_root_dir
          dec bx
          jmp file_name_delim_loop_3
file_name_delim_root_dir:
          dec bp ;we need i - 1
          xor bx, bx
file_name_delim_loop_4:
          mov al, byte ptr cs:[fp][bx]
          mov byte ptr cs:[fn2][bx], al
          inc bx
          cmp bx, bp
          jle file_name_delim_loop_4
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, eop2
          mov cx, 3
          call fill_array_with_zero
          
          pop es
          ;;;;;;;;;;;
          xor bx, bx
          cmp byte ptr ds:[si + bp], '('
          jne file_name_delim_pathbp_isnot_e2opara_1
          inc bp
file_name_delim_loop_5:
          mov al, byte ptr ds:[si + bp]
          call is_valid_char
          cmp ah, 1
          jne exit_file_name_delim_loop_5
          mov byte ptr cs:[eop2][bx], al
          inc bx
          inc bp
          cmp bx, 3
          jg file_name_delim_give_error
          jmp file_name_delim_loop_5
exit_file_name_delim_loop_5:
          cmp bx, 0
          je file_name_delim_give_error
          cmp al, ')'
          jne file_name_delim_give_error
          mov byte ptr cs:[eop2][bx], 0
          mov byte ptr cs:[b1], IS_FILE
          jmp file_name_delim_root_dir_final_works
file_name_delim_pathbp_isnot_e2opara_1:
          mov byte ptr cs:[b1], 0ffh
file_name_delim_root_dir_final_works:
          mov byte ptr cs:[fp][0], 0
          mov word ptr cs:[w1], 0ffeeh
          jmp file_name_delim_sub_dir_final_works
file_name_delim_sub_dir:
          inc bx
          dec bp ;we need i - 1
          mov di, bx
file_name_delim_loop_6:
          mov al, byte ptr cs:[fp][di]
          push di
          sub di, bx
          mov byte ptr cs:[fn2][di], al
          pop di
          inc di
          cmp di, bp
          jle file_name_delim_loop_6
          mov byte ptr cs:[fp][bx - 1], 0
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, eop2
          mov cx, 3
          call fill_array_with_zero
          
          pop es
          ;;;;;;;;;;;
          xor bx, bx
          cmp byte ptr ds:[si + bp], '('
          jne file_name_delim_pathbp_isnot_e2opara_2
          inc bp
file_name_delim_loop_7:
          mov al, byte ptr ds:[si + bp]
          call is_valid_char
          cmp ah, 1
          jne exit_file_name_delim_loop_7
          mov byte ptr cs:[eop2][bx], al
          inc bx
          inc bp
          cmp bx, 3
          jg file_name_delim_give_error
          jmp file_name_delim_loop_7
exit_file_name_delim_loop_7:
          cmp bx, 0
          je file_name_delim_give_error
          cmp byte ptr ds:[si + bp], ')'
          jne file_name_delim_give_error
          mov byte ptr cs:[b1], IS_FILE
          jmp file_name_delim_sub_dir_final_works
file_name_delim_pathbp_isnot_e2opara_2:
          mov byte ptr cs:[b1], 0ffh
file_name_delim_sub_dir_final_works:
          xor ah, ah
          cmp byte ptr cs:[fp][0], 0
          je file_name_delim_end_func
          
          ;setting ds
          push ds
          push cs
          pop ds
          
          mov si, fp
          xor bh, bh
          mov bl, byte ptr cs:[b1]
          push bx
          call check_path
          pop bx
          
          pop ds
          ;;;;;;;;;;;
          mov byte ptr cs:[b1], bl
          push word ptr cs:[w3]; => p_f_c = f_c
          pop word ptr cs:[w2] ;
          push word ptr cs:[w4]; => p_dsm_n = dsm_n
          pop word ptr cs:[w3] ;
          push word ptr cs:[w5]; => dsm_n = st_block
          pop word ptr cs:[w1] ; 
          cmp ah, 1
          jne file_name_delim_ah_is_ok_1
          jmp file_name_delim_give_error
file_name_delim_ah_is_ok_1:
          cmp ah, 2
          jne file_name_delim_ah_is_ok_2
          jmp file_name_delim_end_func
file_name_delim_ah_is_ok_2: 
          cmp ah, 4
          jne file_name_delim_end_func
          push ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          mov si, file_entry
          
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn1
          call get_file_name
          ;si is set
          ;es is set
          mov di, eop1
          call get_file_password
          
          pop es
          ;;;;;;;;;;;
          
          ;setting ds
          push ds
          push cs
          pop ds
          
          mov si, ccs_security_sys_msg
          call print_str
          mov si, the_msg
          call print_str
          mov si, the_folder_msg
          call print_str
          mov si, fn1
          call print_str
          mov si, next_part_of_ss_msg
          call print_str
          mov si, password_msg
          call print_str
          mov si, eop1
          call get_comp_pass
          
          pop ds
          ;;;;;;;;;;;
          cmp ah, 1
          je file_name_delim_valid_password
          
          ;setting ds
          push ds
          push cs
          pop ds
          
          mov si, invalid_pass_msg
          call print_str
          
          pop ds
          ;;;;;;;;;;;
          pop ax
          jmp file_name_delim_give_error
file_name_delim_valid_password:
          ;setting ds
          push ds
          push cs
          pop ds
          
          lea si, valid_pass_msg
          call print_str
          
          pop ds
          ;;;;;;;;;;;
          pop ax    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                                                                                                                                                                                                           
          jmp file_name_delim_end_func
file_name_delim_give_error:
          mov ah, 1
          mov word ptr cs:[w1], 0ffeeh
          mov word ptr cs:[w2], 0ffffh
          mov word ptr cs:[w3], 0ffeeh
          mov byte ptr cs:[b1], 0ffh
          mov byte ptr cs:[eop2][0], 0
          mov byte ptr cs:[fn2][0], 0                 
file_name_delim_end_func:
          pop di
          pop si
          pop bp
          pop cx
          pop bx
          ret      
file_name_delim endp

;c_fe_sp = cs:[w1] (low 8 bit)
;c_fe_p = cs:[w2]
;dsm_n = cs:[w3]
;ah is the status 1 if error
delete_file proc near
          push word ptr cs:[w0]
          push word ptr cs:[w1]
          push word ptr cs:[w2]
          push word ptr cs:[w3]
          push word ptr cs:[w4]
          push si
          push di
          push bx          
          mov bl, byte ptr cs:[current_file_entry_sec_ptr]
          push bx
          push word ptr cs:[current_file_entry_ptr]
          push word ptr cs:[dsm]
          sub word ptr cs:[w2], 32
          mov bx, word ptr cs:[w1]
          mov byte ptr cs:[current_file_entry_sec_ptr], bl
          mov word ptr cs:[current_file_entry_ptr], 512
          push word ptr cs:[w3]
          pop word ptr cs:[dsm]
          call get_file_entry
          cmp ah, 0
          jne _delete_file_give_error
          mov bx, word ptr cs:[w2]
          mov ah, byte ptr cs:[file_entry_sec][bx + 31]
          mov al, byte ptr cs:[file_entry_sec][bx + 30]
          mov word ptr cs:[w4], ax ;cs:[w4] = st_block
          mov byte ptr cs:[file_entry_sec][bx + 19], DELETED
          cmp word ptr cs:[w3], 0ffeeh
          jne _delete_file_dsm_n_ne20ffee
          push word ptr cs:[w1]
          pop word ptr cs:[w0]
          jmp _delete_file_next_part
_delete_file_dsm_n_ne20ffee:
          push word ptr cs:[w3]
          pop word ptr cs:[w0]
          add word ptr cs:[w0], 35
_delete_file_next_part:             
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_entry_sec
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne _delete_file_give_error
          cmp word ptr cs:[w4], 0
          je _delete_file_end_func
_delete_file_loop_1:
          cmp word ptr cs:[w4], 0ffffh
          je _delete_file_end_func
          mov si, word ptr cs:[w4]
          call convert_fdd_fptt_index2sec
          ;di is new index
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call read_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          ;sub di, 2
          dec di
          mov ax, 2
          mul di ;we should remember that we don't need dx here
          mov di, ax
          push word ptr cs:[file_pt_table][di]
          pop word ptr cs:[w4]
          mov word ptr cs:[file_pt_table][di], 0 ;my mean is the same word ptr (hey tanks man! "2007")
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1

          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_pt_table
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne _delete_file_give_error          
          jmp _delete_file_loop_1
_delete_file_give_error:
          mov ah, 1              
_delete_file_end_func:
          pop word ptr cs:[dsm]
          pop word ptr cs:[current_file_entry_ptr]
          pop bx
          mov byte ptr cs:[current_file_entry_sec_ptr], bl
          pop bx
          pop di
          pop si
          pop word ptr cs:[w4]
          pop word ptr cs:[w3]
          pop word ptr cs:[w2]
          pop word ptr cs:[w1]
          pop word ptr cs:[w0]
          ret  
delete_file endp

;no param
init_st_pt proc near
      mov word ptr cs:[st_pt1], 0
      mov word ptr cs:[st_pt2], 0 
      ret
init_st_pt endp

;st_val address = ds:si
_push_listing proc near
      push ax
      push si
      push di
      push cx
       
      ;setting es
      push es
      push cs
      pop es
      mov di, st_dat1      
      mov ax, word ptr cs:[st_pt1]
      add di, ax  
      mov cx, 6
      ;si and ds are set
      rep movsb
      pop es
      ;;;;;;;;;;;
       
      add word ptr cs:[st_pt1], 6
       
      pop cx
      pop di
      pop si
      pop ax
      ret
_push_listing endp

;st_val address = ds:si
_push_pathing proc near
      push ax
      push si
      push di
      push cx
       
      ;setting es
      push es
      push cs
      pop es
      mov di, st_dat2      
      mov ax, word ptr cs:[st_pt2]
      add di, ax  
      mov cx, 6
      ;si and ds are set
      rep movsb
      pop es
      ;;;;;;;;;;;
       
      add word ptr cs:[st_pt2], 6
       
      pop cx
      pop di
      pop si
      pop ax
      ret
_push_pathing endp


;st_val address = es:di
_pop_listing proc near
      push ax
      push si
      push di
      push cx
       
      sub word ptr cs:[st_pt1], 6
       
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, st_dat1
      mov ax, word ptr cs:[st_pt1]
      add si, ax
      mov cx, 6
      ;di and es is set
      rep movsb
      pop ds
      ;;;;;;;;;;;
       
      pop cx
      pop di
      pop si
      pop ax
      ret
_pop_listing endp

;st_val address = es:di
_pop_pathing proc near
      push ax
      push si
      push di
      push cx
       
      sub word ptr cs:[st_pt2], 6
       
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, st_dat2
      mov ax, word ptr cs:[st_pt2]
      add si, ax
      mov cx, 6
      ;di and es is set
      rep movsb
      pop ds
      ;;;;;;;;;;;
       
      pop cx
      pop di
      pop si
      pop ax
      ret
_pop_pathing endp

;no param
;ah = 'y/n'
show_read_only_msg proc near
srom_main_loop:
      
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, read_only_msg
      call print_str
      pop ds
      ;;;;;;;;;;;   
      
      call getche
      push ax
      call getch
      cmp al, 13
      je srom_is_ret
      pop ax
      jmp srom_main_loop 
srom_is_ret:
      pop ax      
      cmp al, 'y'
      je srom_yes
      cmp al, 'Y'
      je srom_yes
      cmp al, 'n'
      je srom_no
      cmp al, 'N'
      je srom_no
      
      jmp srom_main_loop                
srom_yes:
      
      mov ah, 'y'   
      jmp srom_end_func   
srom_no:
      mov ah, 'n'  
srom_end_func:
      call new_line
      ret
show_read_only_msg endp

;path buffer address = ds:si
;ah is status 1 if error 0 if successful
deletefile proc near
      push bx
      push cx
      push si
      push di
      push word ptr cs:[w0]
      push word ptr cs:[w1]
      push word ptr cs:[w2]
      push word ptr cs:[w3]
      push word ptr cs:[w4]
      push word ptr cs:[w5]
      push word ptr cs:[dsm]
      push word ptr cs:[current_file_entry_ptr]
      mov bl, byte ptr cs:[current_file_entry_sec_ptr]
      xor bh, bh
      push bx      
      
      ;ds and si are set
      call check_path
      cmp ah, 1
      je delete_file_give_error
      ;ds and si are set
      call file_name_delim
      ;cs:[w1] = dsm_n
      ;cs:[w2] = p_f_c
      ;cs:[w3] = p_dsm_n
      ;cs:[b1] = is file ?
      ;cs:fn2 = fn
      ;cs:eop2 = fe
      cmp ah, 1
      je delete_file_give_error

      push word ptr cs:[w1]
      pop word ptr cs:[dsm]
      mov byte ptr cs:[current_file_entry_sec_ptr], 19
      mov word ptr cs:[current_file_entry_ptr], 512
      
delete_file_loop_1:
      
      call get_file_entry
      cmp ah, 0
      jne delete_file_give_error
      
      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov si, file_entry
      mov di, fn1
      call get_file_name
      mov di, eop1
      call get_file_ext
      mov di, eop3
      call get_file_password
      pop es
      pop ds
      ;;;;;;;;;;;;;;;
      mov byte ptr cs:[b2], ah ;pass stt : 0 if has pass, 1 if has not pass
      
      ;setting ds and es
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov si, fn2
      mov di, fn1
      call str_comp
      pop es
      pop ds
      ;;;;;;;;;;;;;;;;;;
      cmp ah, 1
      jne delete_file_loop_1
      
      cmp byte ptr cs:[b1], IS_FILE
      jne delete_file_loop_1_IS_NOT_FILE
      
      mov si, file_entry
      call get_file_attr
      mov byte ptr cs:[b3], al
      and al, FOLDER
      cmp al, FOLDER
      je delete_file_loop_1
      
      ;setting ds and es
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov si, eop2
      mov di, eop1
      call str_comp
      pop es
      pop ds
      ;;;;;;;;;;;;;;;;;;
      cmp ah, 1
      jne delete_file_loop_1
      and byte ptr cs:[b3], READONLY
      cmp byte ptr cs:[b3], READONLY
      je delete_file_give_error
      cmp byte ptr cs:[b2], 1
      je delete_file_no_pass_fil
      
;;;;;;<<checking file password>>;;;;;;

      ;setting ds                                          
      push ds    
      push cs
      pop ds                                      
      mov si, ccs_security_sys_msg
      call print_str
      mov si, the_msg
      call print_str
      mov si, the_file_msg
      call print_str
      mov si, fn1
      call print_str
      mov al, '('
      call put_char
      mov si, eop1
      call print_str
      mov al, ')'
      call put_char
      mov si, next_part_of_ss_msg
      call print_str
      mov si, password_msg
      call print_str
      mov si, eop3
      call get_comp_pass          
      pop ds
      ;;;;;;;;;;;
          
      cmp ah, 1
      je delete_file_loop1_valid_pass_fil
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, invalid_pass_msg
      call print_str          
      pop ds
      ;;;;;;;;;;;
      
      jmp delete_file_give_error
delete_file_loop1_valid_pass_fil:
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, valid_pass_msg
      call print_str         
      pop ds
      ;;;;;;;;;;;        
delete_file_no_pass_fil:           

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      
      jmp exit_delete_file_loop_1      
delete_file_loop_1_IS_NOT_FILE:
      
      mov si, file_entry
      call get_file_attr
      mov byte ptr cs:[b3], al
      and al, FOLDER
      cmp al, FOLDER
      jne delete_file_loop_1
      
      and byte ptr cs:[b3], READONLY
      cmp byte ptr cs:[b3], READONLY
      je delete_file_give_error
      cmp byte ptr cs:[b2], 1
      je exit_delete_file_loop_1
      
;;;;;;<<checking fold password>>;;;;;;

      ;setting ds                                          
      push ds    
      push cs
      pop ds                                      
      mov si, ccs_security_sys_msg
      call print_str
      mov si, the_msg
      call print_str
      mov si, the_folder_msg
      call print_str
      mov si, fn1
      call print_str
      mov si, next_part_of_ss_msg
      call print_str
      mov si, password_msg
      call print_str
      mov si, eop3
      call get_comp_pass          
      pop ds
      ;;;;;;;;;;;
          
      cmp ah, 1
      je delete_file_loop1_valid_pass_fold
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, invalid_pass_msg
      call print_str          
      pop ds
      ;;;;;;;;;;;
      
      jmp delete_file_give_error
delete_file_loop1_valid_pass_fold:
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, valid_pass_msg
      call print_str         
      pop ds
      ;;;;;;;;;;;      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      
exit_delete_file_loop_1: 

      call init_st_pt
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Performing paragraph 1
      mov al, byte ptr cs:[current_file_entry_sec_ptr]
      xor ah, ah
      dec ax
      mov word ptr cs:[st_val], ax ;real_c_fe_sp = c_fe_sp - 1 
      push word ptr cs:[current_file_entry_ptr]
      pop word ptr cs:[st_val][2]
      cmp word ptr cs:[w1], 0ffeeh
      jne delete_file_dw1_isnot_e2ffee
      mov ax, word ptr cs:[w1] ; = 0ffeeh
      jmp delete_file_final_perform_1
delete_file_dw1_isnot_e2ffee:
      
      push word ptr cs:[w1]
      pop word ptr cs:[w2]
      mov cx, word ptr cs:[dsm]
      call find_prev_block
      cmp ax, 0
      je delete_file_give_error
delete_file_final_perform_1:
      
      mov word ptr cs:[st_val][4], ax
      
      mov si, st_val
      push ds
      push cs
      pop ds
      call _push_listing
      call _push_pathing
      pop ds
      ;;;;;;;;;;;;;;;;;;;;;;; >> Parent entry went in stack

      cmp byte ptr cs:[b1], IS_FILE
      je delete_file_final_works
      
      ;Then it's a folder(In this version of CCS-OS).
      ;TIP: Empty folders are in files group.
      
      mov si, file_entry
      call get_file_starting_block      
      cmp ax, 0
      je delete_file_final_works
      mov word ptr cs:[w1], ax

      ;Here it's a real folder and we want go inside it
      mov byte ptr cs:[current_file_entry_sec_ptr], 19
      mov word ptr cs:[current_file_entry_ptr], 512
      mov word ptr cs:[dsm], ax ;performing paragraph 1

delete_file_main_loop:
      
      call get_file_entry
      cmp word ptr cs:[dsm], 0
      je delete_file_give_error
      cmp ah, 1
      je delete_file_give_error
      cmp ah, 0
      je delete_file_ml_file_got ;ml = main_loop
      
      ;Here surly ah = 2
      
      cmp word ptr cs:[st_pt2], 6
      je delete_file_final_works ;There is only one entry in the stack
      
      ;Here surly cs:[st_pt2] > 6
      
      mov di, st_val
      ;setting es
      push es
      push cs
      pop es
      call _pop_pathing
      pop es
      ;;;;;;;;;;;
      
      mov ax, word ptr cs:[st_val]
      mov byte ptr cs:[current_file_entry_sec_ptr], al
      mov word ptr cs:[current_file_entry_ptr], 512
      push word ptr cs:[st_val][4]
      pop word ptr cs:[dsm]
      push word ptr cs:[dsm]
      pop word ptr cs:[w1]
      
      call get_file_entry
      cmp ah, 0
      jne delete_file_give_error
      
      push word ptr cs:[st_val][2]
      pop word ptr cs:[current_file_entry_ptr]
      
      jmp delete_file_main_loop ;Return to parent folder
      
delete_file_ml_file_got:

      mov si, file_entry
      call get_file_attr
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      and al, DELETED
      cmp al, DELETED
      je delete_file_main_loop

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Performing paragraph 2
      mov al, byte ptr cs:[current_file_entry_sec_ptr]
      xor ah, ah
      dec ax
      mov word ptr cs:[st_val], ax ;real_c_fe_sp = c_fe_sp - 1 
      push word ptr cs:[current_file_entry_ptr]
      pop word ptr cs:[st_val][2]    
      push word ptr cs:[w1]
      pop word ptr cs:[w2]
      mov cx, word ptr cs:[dsm]
      call find_prev_block
      cmp ax, 0
      je delete_file_give_error
      mov word ptr cs:[st_val][4], ax
      
      mov si, st_val
      push ds
      push cs
      pop ds
      call _push_listing
      pop ds
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;>> An entry went in stack
      
      and byte ptr cs:[b3], READONLY
      cmp byte ptr cs:[b3], READONLY
      jne delete_file_fe_is_not_ro
      
      call show_read_only_msg
      cmp ah, 'n'
      je delete_file_give_error
      
delete_file_fe_is_not_ro:
      
      and byte ptr cs:[b4], FOLDER
      cmp byte ptr cs:[b4], FOLDER
      jne delete_file_ml_is_not_fold
      
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Performing paragraph 2
      mov al, byte ptr cs:[current_file_entry_sec_ptr]
      xor ah, ah
      dec ax
      mov word ptr cs:[st_val], ax ;real_c_fe_sp = c_fe_sp - 1 
      push word ptr cs:[current_file_entry_ptr]
      pop word ptr cs:[st_val][2]    
      push word ptr cs:[w1]
      pop word ptr cs:[w2]
      mov cx, word ptr cs:[dsm]
      call find_prev_block
      cmp ax, 0
      je delete_file_give_error
      mov word ptr cs:[st_val][4], ax
      
      mov si, st_val
      push ds
      push cs
      pop ds
      call _push_pathing
      pop ds
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;>> An entry went in stack
      
      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov si, file_entry
      mov di, fn1
      call get_file_name
      mov di, eop3
      call get_file_password
      pop es
      pop ds
      ;;;;;;;;;;;
      cmp ah, 1
      je delete_file_ml_fold_has_no_pass
      
;;;;;;<<checking fold password>>;;;;;;

      ;setting ds                                          
      push ds    
      push cs
      pop ds                                      
      mov si, ccs_security_sys_msg
      call print_str
      mov si, the_msg
      call print_str
      mov si, the_folder_msg
      call print_str
      mov si, fn1
      call print_str
      mov si, next_part_of_ss_msg
      call print_str
      mov si, password_msg
      call print_str
      mov si, eop3
      call get_comp_pass          
      pop ds
      ;;;;;;;;;;;
          
      cmp ah, 1
      je delete_file_ml_fold_valid_pass
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, invalid_pass_msg
      call print_str          
      pop ds
      ;;;;;;;;;;;
      
      jmp delete_file_give_error
delete_file_ml_fold_valid_pass:
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, valid_pass_msg
      call print_str         
      pop ds
      ;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delete_file_ml_fold_has_no_pass:

      mov si, file_entry
      call get_file_starting_block
      cmp ax, 0
      jne delete_file_ml_enter_fold
      
      ;Folder is empty and it is in files group
      mov di, st_val
      ;setting es
      push es
      push cs
      pop es
      call _pop_pathing ;We don't need this st_val and we just wanted take it out from stack
      pop es
      ;;;;;;;;;;;
      
      jmp delete_file_main_loop      
delete_file_ml_enter_fold:

      ;performing paragraph 3
      mov byte ptr cs:[current_file_entry_sec_ptr], 19
      mov word ptr cs:[current_file_entry_ptr], 512
      mov word ptr cs:[dsm], ax
      mov word ptr cs:[w1], ax ;Parents st_blk
      jmp delete_file_main_loop
delete_file_ml_is_not_fold: ;is file

      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov si, file_entry
      mov di, fn1
      call get_file_name
      mov di, eop3
      call get_file_password
      mov di, eop1
      call get_file_ext
      pop es
      pop ds
      ;;;;;;;;;;;;;;;
      cmp ah, 1
      je delete_file_main_loop ;The file has no pass

      ;;;;;;<<checking file password>>;;;;;;

      ;setting ds                                          
      push ds    
      push cs
      pop ds                                      
      mov si, ccs_security_sys_msg
      call print_str
      mov si, the_msg
      call print_str
      mov si, the_file_msg
      call print_str
      mov si, fn1
      call print_str
      mov al, '('
      call put_char
      mov si, eop1
      call print_str
      mov al, ')'
      call put_char
      mov si, next_part_of_ss_msg
      call print_str
      mov si, password_msg
      call print_str
      mov si, eop3
      call get_comp_pass          
      pop ds
      ;;;;;;;;;;;
          
      cmp ah, 1
      je delete_file_ml_fil_valid_pass
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, invalid_pass_msg
      call print_str          
      pop ds
      ;;;;;;;;;;;
      
      jmp delete_file_give_error
delete_file_ml_fil_valid_pass:
          
      ;setting ds
      push ds
      push cs
      pop ds          
      mov si, valid_pass_msg
      call print_str         
      pop ds
      ;;;;;;;;;;;        
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      jmp delete_file_main_loop     
delete_file_final_works:

delete_file_final_loop:

      mov di, st_val
      
      ;setting es
      push es
      push cs
      pop es
      call _pop_listing
      pop es
      ;;;;;;;;;;;                
      
      push word ptr cs:[st_val]
      pop word ptr cs:[w1]
      push word ptr cs:[st_val][2]
      pop word ptr cs:[w2]
      push word ptr cs:[st_val][4]
      pop word ptr cs:[w3]
      
      call delete_file
      cmp ah, 1
      je delete_file_fatal

      cmp word ptr cs:[st_pt1], 0
      jne delete_file_final_loop
      
      ;All files, folders, subfolders and etc. are deleted!
      xor ah, ah
      jmp delete_file_end_func
delete_file_fatal:
      cmp word ptr cs:[st_pt1], 0
      je delete_file_give_error
      
      call new_line
      
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, fatal_err_msg
      call print_str
      pop ds
      ;;;;;;;;;;;
                  
delete_file_give_error:
      
      mov ah, 1
delete_file_end_func:

      pop bx 
      mov byte ptr cs:[current_file_entry_sec_ptr], bl
      pop word ptr cs:[current_file_entry_ptr]
      pop word ptr cs:[dsm]
      pop word ptr cs:[w5]
      pop word ptr cs:[w4]
      pop word ptr cs:[w3]
      pop word ptr cs:[w2]
      pop word ptr cs:[w1]
      pop word ptr cs:[w0]
      pop di
      pop si
      pop cx
      pop bx
      ret                    
deletefile endp

;starting first block = bx
clear_file_entry proc near
          push di
          push cx
          push es
          
          push cs
          pop es
          mov di, file_entry_sec
          add di, bx
          mov cx, 31
          call fill_array_with_zero
          
          pop es
          pop cx
          pop di
          ret
clear_file_entry endp

;file name buf addr = ds:si
;starting first block = bx
set_file_name proc near
          push si
          push di
          push cx
          push es
          
          push cs
          pop es
          mov di, file_entry_sec
          add di, bx
          mov cx, 13
          ;ds and si are set
          cld
          rep movsb
          
          pop es
          pop cx
          pop di
          pop si
          ret
set_file_name endp

;file pass buf addr = ds:si
;starting first block = bx
set_file_password proc near
          push si
          push di
          push cx

          mov di, file_entry_sec
          add di, bx
          cld
          ;ds and si is set
          mov cx, 3
set_file_password_main_loop:
          lodsb
          xor al, 0abh
          mov byte ptr cs:[di], al
          inc di
          loop set_file_password_main_loop
                       
          pop cx
          pop di
          pop si
          ret
set_file_password endp

;file ext buf addr = ds:si
;starting first block = bx
set_file_ext proc near
          push si
          push di
          push cx
          push ds
          push es
          
          push cs
          push cs
          pop es
          pop ds
          mov di, file_entry_sec
          add di, bx
          cld
          ;si is set
          mov cx, 3
          rep movsb
          
          pop es
          pop ds
          pop cx
          pop di
          pop si
          ret
set_file_ext endp

;starting first block = bx
set_file_date proc near
          push ax
          push dx
          push si
          
          mov si, file_entry_sec
          add si, bx
          call get_date
          mov byte ptr cs:[si], ah
          mov byte ptr cs:[si + 1], al
          mov byte ptr cs:[si + 2], dh
          
          call get_time
          mov byte ptr cs:[si + 3], ah
          mov byte ptr cs:[si + 4], al
          mov byte ptr cs:[si + 5], dh
          
          pop si
          pop dx
          pop ax
          ret
set_file_date endp

;no param
;ah = hour
;al = minute
;dh = second
get_time proc near
          push cx
          mov ah, 2
          int 1ah
          mov al, ch
          and al, 0fh
          mov ah, ch
          shr ah, 1
          shr ah, 1
          shr ah, 1
          shr ah, 1
          aad
          mov ch, al
          mov al, cl
          and al, 0fh
          mov ah, cl
          shr ah, 1
          shr ah, 1
          shr ah, 1
          shr ah, 1
          aad
          mov cl, al
          mov al, dh
          and al, 0fh
          mov ah, dh
          shr ah, 1
          shr ah, 1
          shr ah, 1
          shr ah, 1
          aad
          mov dh, al
          mov ah, ch
          mov al, cl
          ;dh is set
          pop cx
          ret
get_time endp

;no param
;ah = year
;al = month
;dh = day
get_date proc near
          push cx
          mov ah, 4h
          int 1ah
          mov al, ch
          and al, 0fh
          mov ah, ch
          shr ah, 1
          shr ah, 1
          shr ah, 1
          shr ah, 1
          aad
          mov ch, al
          mov al, cl
          and al, 0fh
          mov ah, cl
          shr ah, 1
          shr ah, 1
          shr ah, 1
          shr ah, 1
          aad
          mov cl, al
          mov al, ch
          mov ah, 100
          mul ah
          xor ch, ch
          add ax, cx
          mov cx, ax
          mov al, dh
          and al, 0fh
          mov ah, dh
          shr ah, 1
          shr ah, 1
          shr ah, 1
          shr ah, 1
          aad
          mov dh, al
          mov al, dl
          and al, 0fh
          mov ah, dl
          shr ah, 1
          shr ah, 1
          shr ah, 1
          shr ah, 1
          aad
          mov dl, al
          sub cx, 2000
          mov ah, cl
          mov al, dh
          xchg dh, dl
          pop cx
          ret
get_date endp

;path buf address = ds:si
;password buf addr = es:di
;file entry attr = cs:[b7]
;ah is status 1 if error
;ATTENTION IF YOU DON'T WANT YUOR FILE DOESN'T HAS PASSWORD PLEASE SET es:di TO ZERO
create_file_entry proc near
          ;si is set
          call check_path
          ;now:
          ;cs:[w3] = f_c
          ;cs:[w4] = dsm_n
          ;cs:[w5] = st_block
          ;cs:[b5] = other_attrs
          cmp ah, 1
          je create_file_entry_file_not_exists
          ;si is set
          call deletefile
          cmp ah, 1
          je create_file_entry_give_error
create_file_entry_file_not_exists:
          push di
          ;setting es
          push es
          push cs
          pop es
          
          mov di, fn2
          mov cx, 13
          call fill_array_with_zero
          mov di, eop2
          mov cx, 3
          call fill_array_with_zero
          
          pop es
          ;;;;;;;;;;;
          pop di
          ;ds and si are set
          call file_name_delim
          ;now:
          ;cs:[w1] = dsm_n
          ;cs:[w2] = p_f_c
          ;cs:[w3] = p_dsm_n;
          ;cs:[b1] = is file ?
          ;cs:fn2 is set
          ;cs:eop2 is set
          
          cmp word ptr cs:[w1], 0 ;THIS FOR WHEN FOLDER IS EMPTY
          je create_file_entry_crt_dsm
          
          ;Here cs:[1] = 0ffeeh or cs:[w1] # 0ffeeh
          push word ptr cs:[w1]
          pop word ptr cs:[dsm]
          mov word ptr cs:[current_file_entry_sec_ptr], 19
          mov word ptr cs:[current_file_entry_ptr], 512
          
create_file_finding_eofe:                              
          call get_file_entry
          cmp ah, 1
          je create_file_entry_give_error
          cmp ah, 2
          jne create_file_finding_eofe
          
          ;ATTN : get_file_entry has read the sector and file_entry_sec is set
          
          mov bx, word ptr cs:[current_file_entry_ptr] ; +32
          cmp bx, 512
          jne create_file_entry_con_1
          cmp word ptr cs:[dsm], 0ffeeh
          jne create_file_new_dsm_needed_0
create_file_entry_con_1:          
          ;es and di are set
          cmp byte ptr es:[di], 0
          je create_file_entry_has_not_pass
          or byte ptr cs:[b7], PROTECTED          
create_file_entry_has_not_pass:
          
          ;setting ds
          push ds
          push cs
          pop ds
          mov si, fn2
          call set_file_name
          add bx, 13
          
          ;setting ds
          push ds
          push es
          pop ds
          mov si, di
          call set_file_password
          pop ds
          ;;;;;;;;;;;
          
          add bx, 3
          mov si, eop2
          call set_file_ext                    
          pop ds
          ;;;;;;;;;;;
          
          add bx, 3
          mov di, file_entry_sec
          add di, bx
          mov cl, byte ptr cs:[b7]
          mov byte ptr cs:[di], cl
          inc bx
          call set_file_date
          mov di, file_entry_sec
          add bx, 8
          add di, bx
          mov word ptr cs:[di], 512
          ;WE DON'T NEED THESE PARTS OF FILE ENTRY THEN WE SHOULD SET THEM TO ZERO (WE HAVE DONE)
          cmp word ptr cs:[dsm], 0ffeeh
          jne create_file_dsm_ne2ffee_1
          mov al, byte ptr cs:[current_file_entry_sec_ptr]
          xor ah, ah
          dec ax
          mov word ptr cs:[w0], ax
          jmp create_file_con_0
create_file_dsm_ne2ffee_1:
          push word ptr cs:[w1]
          pop word ptr cs:[w2]
          mov cx, word ptr cs:[dsm]
          call find_prev_block
          cmp ax, 0
          je create_file_entry_give_error
          mov word ptr cs:[w0], ax
          add word ptr cs:[w0], 35
create_file_con_0:
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_entry_sec
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          ;ah is set          
          jmp create_file_entry_end_func
create_file_new_dsm_needed_0:
          ;Here dsm # 0ffeeh and cfe_p = 512
          push di
          mov ax, word ptr cs:[w1]
          call find_eof
          mov word ptr cs:[w4], di
          pop di
          cmp word ptr cs:[w0], 0ffffh
          je create_file_entry_give_error
          ;now cs:[w4] is CCS understandable fp index(eof)
          ;and cs:[w0] is set (eof)
          push word ptr cs:[w0]
          push di
          call find_blank_block
          mov word ptr cs:[w5], di
          mov word ptr cs:[w7], di
          push word ptr cs:[w0]
          pop word ptr cs:[w6]
          pop di
          pop word ptr cs:[w0]
          cmp word ptr cs:[w6], 0ffffh
          je create_file_entry_give_error
          ;now cs:[w5] is CCS understandable fp index(blank)
          ;and cs:[w6] is set (blank)
          mov ax, word ptr cs:[w5]
          add ax, 2
          mov word ptr cs:[w5], 2
          xor dx, dx
          div word ptr cs:[w5]
          mov word ptr cs:[w5], ax
          mov ax, word ptr cs:[w6]
          dec ax
          mov bx, 256
          mul bx
          add word ptr cs:[w5], ax
          ;;;;;;;;;;;;;;;;;;;;;;;;
          ;now cs:[w5] is user understandable fp index
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_pt_table
          call read_fdd_sector    
          pop es
          ;;;;;;;;;;;
          
          cmp ah, 0
          jne create_file_entry_give_error
          mov si, word ptr cs:[w4]
          push word ptr cs:[w5]
          pop word ptr cs:[file_pt_table][si]
          
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_pt_table
          call write_fdd_sector    
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          
          push word ptr cs:[w6]
          pop word ptr cs:[w0]
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_pt_table
          call read_fdd_sector
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          
          mov si, word ptr cs:[w7]
          mov word ptr cs:[file_pt_table][si], 0ffffh
          
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_pt_table
          call write_fdd_sector    
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          
          push di
          
          ;setting es
          push es
          push cs
          pop es
          mov di, file_entry_sec
          mov cx, 512
          call fill_array_with_zero
          pop es
          ;;;;;;;;;;;
          
          pop di
          
          push word ptr cs:[w5]
          pop word ptr cs:[w0]
          add word ptr cs:[w0], 35
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_entry_sec
          call write_fdd_sector
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          
          ;We don't need to read file_entry_sec
          
          xor bx, bx
          ;es and di are set
          cmp byte ptr es:[di], 0
          je create_file_entry_has_not_pass_2
          or byte ptr cs:[b7], PROTECTED          
create_file_entry_has_not_pass_2:
          
          ;setting ds
          push ds
          push cs
          pop ds
          mov si, fn2
          call set_file_name
          add bx, 13
          
          ;setting ds
          push ds
          push es
          pop ds
          mov si, di
          call set_file_password
          pop ds
          ;;;;;;;;;;;
          
          add bx, 3
          mov si, eop2
          call set_file_ext                    
          pop ds
          ;;;;;;;;;;;
          
          add bx, 3
          mov di, file_entry_sec
          add di, bx
          mov cl, byte ptr cs:[b7]
          mov byte ptr cs:[di], cl
          inc bx
          call set_file_date
          mov di, file_entry_sec
          add bx, 8
          add di, bx
          mov word ptr cs:[di], 512
          ;WE DON'T NEED THESE PARTS OF FILE ENTRY THEN WE SHOULD SET THEM TO ZERO (WE HAVE DONE)
          ;cs:[w0] is set
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_entry_sec
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          ;ah is set          
          jmp create_file_entry_end_func
create_file_entry_crt_dsm:
          ;This is for when parent folder is empty
          push di
          call find_blank_block
          mov word ptr cs:[w4], di
          push word ptr cs:[w0]
          pop word ptr cs:[w6]
          pop di
          ;now cs:[w4] is blank block's index #, cs:[w6] is sector #
          mov ax, word ptr cs:[w4]
          add ax, 2
          mov bx, 2
          xor dx, dx
          div bx
          mov word ptr cs:[w5], ax
          mov ax, word ptr cs:[w6]
          dec ax
          mov bx, 256
          mul bx
          add word ptr cs:[w5], ax
          ;cs:[w5] is brown index #
          
          mov word ptr cs:[current_file_entry_sec_ptr], 19
          mov word ptr cs:[current_file_entry_ptr], 512
          push word ptr cs:[w3]
          pop word ptr cs:[dsm]
          
          mov cx, word ptr cs:[w2]
create_file_crt_dsm_loop_0:
          call get_file_entry
          cmp ah, 1
          je create_file_entry_give_error                  
          loop create_file_crt_dsm_loop_0
          
          mov si, word ptr cs:[current_file_entry_ptr]
          sub si, 32 
          push word ptr cs:[w5]
          pop word ptr cs:[file_entry_sec][si][30]
          
          cmp word ptr cs:[dsm], 0ffeeh
          jne create_file_crt_dsm_ne_ffee
          mov al, byte ptr cs:[current_file_entry_sec_ptr]
          xor ah, ah
          dec ax
          mov word ptr cs:[w0], ax
          jmp crt_file_crt_dsm_ne_ffee_con0
create_file_crt_dsm_ne_ffee:
          push word ptr cs:[w3]
          pop word ptr cs:[w2]
          mov cx, word ptr cs:[dsm]
          call find_prev_block
          cmp ax, 0
          je create_file_entry_give_error
          mov word ptr cs:[w0], ax
          add word ptr cs:[w0], 35
crt_file_crt_dsm_ne_ffee_con0:                                          
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_entry_sec
          call write_fdd_sector
          pop es
          ;;;;;;;;;;;          
          cmp ah, 0
          jne create_file_entry_give_error
          
          push di
          
          ;setting es
          push es
          push cs
          pop es
          mov di, file_entry_sec
          mov cx, 512
          call fill_array_with_zero
          pop es
          ;;;;;;;;;;;
          
          pop di
          
          push word ptr cs:[w5]
          pop word ptr cs:[w0]
          add word ptr cs:[w0], 35
          push word ptr cs:[w0]
          pop word ptr cs:[w7]
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_entry_sec
          call write_fdd_sector
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          
          push word ptr cs:[w6]
          pop word ptr cs:[w0]
          mov byte ptr cs:[b0], 1
           
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_pt_table
          call read_fdd_sector
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          
          mov si, word ptr cs:[w4]
          mov word ptr cs:[file_pt_table][si], 0ffffh
          
          mov byte ptr cs:[b0], 1
           
          ;setting es
          push es
          push cs
          pop es
          mov bx, file_pt_table
          call write_fdd_sector
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          
          ;We don't need to read file_entry_sec
          
          xor bx, bx
          ;es and di are set
          cmp byte ptr es:[di], 0
          je create_file_entry_has_not_pass_3
          or byte ptr cs:[b7], PROTECTED          
create_file_entry_has_not_pass_3:
          
          ;setting ds
          push ds
          push cs
          pop ds
          mov si, fn2
          call set_file_name
          add bx, 13
          
          ;setting ds
          push ds
          push es
          pop ds
          mov si, di
          call set_file_password
          pop ds
          ;;;;;;;;;;;
          
          add bx, 3
          mov si, eop2
          call set_file_ext                    
          pop ds
          ;;;;;;;;;;;
          
          add bx, 3
          mov di, file_entry_sec
          add di, bx
          mov cl, byte ptr cs:[b7]
          mov byte ptr cs:[di], cl
          inc bx
          call set_file_date
          mov di, file_entry_sec
          add bx, 8
          add di, bx
          mov word ptr cs:[di], 512
          ;WE DON'T NEED THESE PARTS OF FILE ENTRY THEN WE SHOULD SET THEM TO ZERO (WE HAVE DONE)
          push word ptr cs:[w7]
          pop word ptr cs:[w0]
          mov byte ptr cs:[b0], 1
          
          ;setting es
          push es
          push cs
          pop es
          
          mov bx, file_entry_sec
          call write_fdd_sector
          
          pop es
          ;;;;;;;;;;;
          cmp ah, 0
          jne create_file_entry_give_error
          ;ah is set          
          jmp create_file_entry_end_func 
          
          jmp create_file_entry_end_func          
create_file_entry_give_error:
          mov ah, 1
create_file_entry_end_func:
          ret
create_file_entry endp

;file path and name buf addr = ds:si
;file password buf addr = es:di
;file attributes = b7
;ah = status 1 if error
createfile proc near
          ;ds:si is set
          ;es:di is set
          ;b7 is set
          call create_file_entry
          ret
createfile endp

;folder path and name buf addr = ds:si
;folder password buf addr = es:di
;folder attributes = b7
;ah = status 1 if error
createfolder proc near
          ;ds:si is set
          ;es:di is set
          or byte ptr cs:[b7], FOLDER
          call create_file_entry
          ret
createfolder endp

;interrupt sevice number = al
;interrupt service place = ds:si
install_service proc near
          push bx
          push es
          xor ah, ah
          mov bx, ax
          shl bx, 1
          shl bx, 1
          xor al, al
          mov es, ax
          mov es : [bx], si
          mov es : [bx + 2], ds 
          pop es
          pop bx      
          ret
install_service endp

;path = ds:si
show_dir proc near
          pusha
          ;setting es
          push es
          push cs
          pop es
          ;ds:si is set
          mov di, root_dir
          call str_comp
          pop es
          ;;;;;;;;;;;
          cmp ah, 1
          jne show_dir_03
          mov word ptr cs:[dsm], 0ffeeh
          mov byte ptr cs:[fn2][0], '('
          mov byte ptr cs:[fn2][1], 'r'
          mov byte ptr cs:[fn2][2], 'o'
          mov byte ptr cs:[fn2][3], 'o'
          mov byte ptr cs:[fn2][4], 't'
          mov byte ptr cs:[fn2][5], ')'
          mov byte ptr cs:[fn2][6], 0   
          jmp show_dir_04
show_dir_03:
          call check_path      
          cmp ah, 2
          jne show_dir_give_error 
          push word ptr cs:[w5]          
          call file_name_delim
          pop word ptr cs:[w5]
          cmp byte ptr cs:[b1], IS_FILE
          je show_dir_give_error
          cmp word ptr cs:[w5], 0
          je show_dir_give_error
          push word ptr cs:[w5]
          pop word ptr cs:[dsm]
show_dir_04:
          mov byte ptr cs:[current_file_entry_sec_ptr], 19
          mov word ptr cs:[current_file_entry_ptr], 512
          push ds
          push cs
          pop ds
          mov si, viewing_msg
          call print_str
          mov si, fn2
          call print_str
          mov si, view_msg_0
          call print_str
          pop ds
show_dir_main_loop:
          call get_file_entry
          cmp ah, 1
          je show_dir_give_error
          cmp ah, 2
          je exit_show_dir_main_loop
          mov si, file_entry
          call get_file_attr
          mov byte ptr cs:[b0], al
          mov byte ptr cs:[b1], al
          mov byte ptr cs:[b2], al
          
          and byte ptr cs:[b2], DELETED
          cmp byte ptr cs:[b2], DELETED
          je show_dir_main_loop
          
          and al, HIDDEN
          cmp al, HIDDEN
          jne show_dir_isnot_hidden
          push ds
          push cs
          pop ds
          mov si, hidden_msg
          call print_str
          pop ds
          jmp show_dir_main_loop
show_dir_isnot_hidden:
          push ds
          push es
          push cs
          push cs
          pop es
          pop ds              
          ;ds is set
          mov si, file_entry
          ;es is set
          mov di, fn0
          call get_file_name
          
          ;es, si is set
          mov di, eop0
          call get_file_ext
          
          mov di, fdate0
          call get_file_date
          pop es
          pop ds
          
          and byte ptr cs:[b0], FOLDER
          cmp byte ptr cs:[b0], FOLDER
          jne show_dir_isnot_folder
          
          call new_line
          push ds
          push cs
          pop ds
          mov si, fn0
          call print_str
          pop ds
          
          and byte ptr cs:[b1], PROTECTED
          cmp byte ptr cs:[b1], PROTECTED
          jne show_dir_isnot_pro_fold
          call insert_tab
          push ds
          push cs
          pop ds
          mov si, pass_msg_1
          call print_str
          
          call insert_tab
          mov ax, word ptr cs:[fdate0]
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][2]
          xor ah, ah
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][3]
          xor ah, ah
          call disp_num
          mov al, ' '
          call put_char
          mov al, byte ptr cs:[fdate0][4]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][5]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][6]
          xor ah, ah
          call disp_num          
          pop ds
          jmp show_dir_main_loop
show_dir_isnot_pro_fold:
          call insert_tab              
          push ds
          push cs
          pop ds
          mov si, pass_msg_0
          call print_str
          pop ds              

          call insert_tab
          mov ax, word ptr cs:[fdate0]
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][2]
          xor ah, ah
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][3]
          xor ah, ah
          call disp_num
          mov al, ' '
          call put_char
          mov al, byte ptr cs:[fdate0][4]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][5]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][6]
          xor ah, ah
          call disp_num                    
          jmp show_dir_main_loop
show_dir_isnot_folder:
          call new_line
          push ds
          push cs
          pop ds
          mov si, fn0
          call print_str
          mov al, '('
          call put_char
          mov si, eop0
          call print_str
          mov al, ')'
          call put_char
          pop ds          
          
          and byte ptr cs:[b1], PROTECTED
          cmp byte ptr cs:[b1], PROTECTED
          jne show_dir_isnot_pro_file
          call insert_tab
          push ds
          push cs
          pop ds
          mov si, pass_msg_1
          call print_str
          pop ds
          
          call insert_tab
          mov ax, word ptr cs:[fdate0]
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][2]
          xor ah, ah
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][3]
          xor ah, ah
          call disp_num
          mov al, ' '
          call put_char
          mov al, byte ptr cs:[fdate0][4]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][5]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][6]
          xor ah, ah
          call disp_num
          jmp show_dir_main_loop
show_dir_isnot_pro_file:
          call insert_tab              
          push ds
          push cs
          pop ds
          mov si, pass_msg_0
          call print_str
          pop ds              

          call insert_tab
          mov ax, word ptr cs:[fdate0]
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][2]
          xor ah, ah
          call disp_num
          mov al, '/'
          call put_char
          mov al, byte ptr cs:[fdate0][3]
          xor ah, ah
          call disp_num
          mov al, ' '
          call put_char
          mov al, byte ptr cs:[fdate0][4]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][5]
          xor ah, ah
          call disp_num
          mov al, ':'
          call put_char
          mov al, byte ptr cs:[fdate0][6]
          xor ah, ah
          call disp_num
          jmp show_dir_main_loop           
exit_show_dir_main_loop:            
          jmp show_dir_end_func
show_dir_give_error:
          push ds
          push cs
          pop ds
          mov si, dir_err
          call print_str
          pop ds          
show_dir_end_func:
          popa        
          ret        
show_dir endp

int20h:
         pop word ptr cs:[_ip_val]
         pop word ptr cs:[_cs_val]
         pop word ptr cs:[_flags]
         mov word ptr cs:[_sp_val], sp
          
         mov word ptr cs:[w1], ax
         mov ax, cs
         cli
         mov ss, ax
         mov sp, 0ffeeh
         sti
         mov ax, word ptr cs:[w1]
         
         cmp ah, 0
         jne int20h_next_1
         call put_char
         jmp _IRET
int20h_next_1:  ;cx = returns number of printed characters
         cmp ah, 1
         jne int20h_next_2
         call print_str
         call str_len
         jmp _IRET
int20h_next_2:
         cmp ah, 2
         jne int20h_next_3
         call getch
         jmp _IRET
int20h_next_3:
         cmp ah, 3
         jne int20h_next_4
         call getche
         jmp _IRET
int20h_next_4:
         cmp ah, 4
         jne int20h_next_5
         call get_str
         jmp _IRET
int20h_next_5:
         cmp ah, 5
         jne int20h_next_6
         call get_pass
         jmp _IRET
int20h_next_6:
         cmp ah, 6
         jne int20h_next_7
         call get_comp_pass
         jmp _IRET
int20h_next_7:
         cmp ah, 7
         jne int20h_next_8
         push ax
         mov ax, cx
         call disp_num
         pop ax
         jmp _IRET
int20h_next_8:
         cmp ah, 8
         jne int20h_next_9
         call new_line
         jmp _IRET
int20h_next_9:
         cmp ah, 9
         jne int20h_next_a
         call insert_tab
         jmp _IRET
int20h_next_a:
         cmp ah, 0ah
         jne int20h_next_b
         call openfile
         jmp _IRET
int20h_next_b:
         cmp ah, 0bh
         jne int20h_next_c
         call readfile
         jmp _IRET
int20h_next_c:
         cmp ah, 0ch
         jne int20h_next_d
         call writefile
         jmp _IRET
int20h_next_d:
         cmp ah, 0dh
         jne int20h_next_e
         call deletefile
         jmp _IRET
int20h_next_e:
         cmp ah, 0eh
         jne int20h_next_f
         mov byte ptr cs:[b7], al
         call createfile
         jmp _IRET
int20h_next_f:
         cmp ah, 0fh
         jne int20h_next_10
         mov byte ptr cs:[b7], al
         call createfolder
         jmp _IRET
int20h_next_10:
         cmp ah, 12h
         jne int20h_next_11
         call show_dir
         jmp _IRET
int20h_next_11:
     
     

_IRET:
         mov word ptr cs:[w1], ax
         mov ax, word ptr cs:[_cs_val]
         cli
         mov ss, ax
         mov sp, word ptr cs:[_sp_val]
         mov es, ax
         mov ds, ax
         push word ptr cs:[_flags]
         push word ptr cs:[_cs_val]
         push word ptr cs:[_ip_val]
         sti
         mov ax, word ptr cs:[w1]
         iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;the main func
_main proc near
         mov byte ptr cs:[active_page], 0
         call make_def_fids
         ;;;;;;;;;;;
         
         mov si, welcome_msg
         call print_str
         ;installing interrupts
         mov si, install_int20h_msg
         call print_str
         ;ds is set
         mov si, int20h
         mov al, 20h
         call install_service
         ret
_main endp

end prog_entry