;SFL
.model small

NORMAL          equ 0
READONLY        equ 1
HIDDEN          equ 2
FOLDER          equ 4
V_FOLDER        equ 8 ;not supported by CCS 10 
DELETED         equ 10h
PROTECTED       equ 20h

FIL_1_SEC_COUNT equ 25
FIL_2_SEC_COUNT equ 33
FIL_3_SEC_COUNT equ 10


.code
org 100h
prog_entry:
jmp start_point
nop
         fil_1_name db "ints(sse)", 0
         fil_2_name db "hdd(sse)", 0
         fil_3_name db "inter(sse)", 0  
   
         w0 dw ?
         w1 dw ?
         w2 dw ?
         w3 dw ?
         w4 dw ?
         w5 dw ?
         
         b0 db ?
         b1 db ?
         b2 db ?
         b3 db ?
         b4 db ?
         b5 db ?
         b6 db ?
         
         file_entry_sec db 512 dup (?)
         file_pt_table dw 256 dup (?)
         file_entry db 32 dup (?)
         
         fn0 db 14 dup (?)
         fn1 db 14 dup (?)
         eop0 db 4 dup (?)
         eop1 db 4 dup (?)
         
         fh0 db 10 dup (?)
         fh1 db 10 dup (?)
         fh2 db 10 dup (?)
         
         dsm dw ?
         current_file_entry_ptr dw ?
         current_file_entry_sec_ptr db ?
         
         ccs_security_sys_msg db 0ah, 0dh, "CCS-OS Security System", 0
         the_msg db 0ah, 0dh, "The ", 0
         the_file_msg db "file '", 0
         the_folder_msg db "folder '", 0
         next_part_of_ss_msg db "' which you want to access is protected.", 0ah, 0dh
                        db "You must enter a valid password to access it.", 0 
         password_msg db 0ah, 0dh, "Password: ", 0
         invalid_pass_msg db 0ah, 0dh, "Invalid Password.", 0
         valid_pass_msg db 0ah, 0dh, "Password Accepted.", 0
         
         pls_wait_msg db 0ah, 0dh, "Please wait while CCS-OS is loading files...", 0
         loading_msg db "Loading ", 0
         three_dots db "...", 0
         fil_nf_err_p1 db "File '", 0
         fil_nf_err_p2 db "' not found.", 0ah, 0dh, "Press any key...", 0 
         ret_msg db 0ah, 0dh, "Returned to SFL(SSE)", 0ah, 0dh,0
start_point:
cli
mov ax, cs
mov ds, ax
mov ss, ax
mov es, ax
mov sp, 0ffeeh
sti
call _main
retf
nop

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

;al = got ch
getch proc near
         xor ah, ah
         int 16h
         ret
getch endp

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
         mov w0, bx
         inc w0
         pop dx
         pop cx
         pop bx
         pop ax
         ret 
convert_fdd_fptt_index2sec endp

;sector number = w0
;sectors count = b0
;buffer's segment = es
;buffer's offset = bx
;ah = 0 success 1 fail
read_fdd_sector proc near
         push bx
         push cx
         push dx 
               
         mov ax, w0
         mov cl, b0
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
		 jc read_fdd_sector_give_error
		 pop ax
		 pop cx
         inc ax                 
         dec cx
         jz read_fdd_sector_end_func
         add bx, 512
         jmp read_fdd_sector_main_loop
read_fdd_sector_give_error:
         pop cx
         pop cx                  
read_fdd_sector_end_func:

         pop dx
         pop cx
         pop bx
         ret
read_fdd_sector endp

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

;character = al
;ah = 1 is valid, 0 is invalid
is_valid_char proc near 
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

;ah = status : 1 error 0 file got 2 EOFE
get_file_entry proc near
         push bx
         push cx
         push dx
         push si
         push di
         push w0
         cmp current_file_entry_ptr, 512
         jne cfep_ne_512
         cmp dsm, 0ffeeh
         jne dsm_ne_ffee
         xor ah, ah
         mov al, current_file_entry_sec_ptr
         mov w0, ax
         mov b0, 1
         ;es is set
         lea bx, file_entry_sec
         call read_fdd_sector
         cmp ah, 0
         jne get_file_error
         mov current_file_entry_ptr, 0
         inc current_file_entry_sec_ptr
         jmp get_file_no_error
get_file_error:     
         mov ah, 1
         jmp exit_func_get_file_entry
get_file_no_error:
         jmp cfep_ne_512
dsm_ne_ffee:
         mov ax, dsm
         mov w0, ax
         add w0, 35
         mov b0, 1
         ;es is set
         lea bx, file_entry_sec
         call read_fdd_sector
         cmp ah, 0
         jne get_file_error
         mov current_file_entry_ptr, 0
         mov si, dsm
         call convert_fdd_fptt_index2sec
         mov b0, 1
         ;es is set
         lea bx, file_pt_table
         call read_fdd_sector
         cmp ah, 0
         jne get_file_error
         dec di
          
         mov ax, 2
         mul di
         mov di, ax
         
         push file_pt_table [di]
         pop dsm
cfep_ne_512:
         mov si, current_file_entry_ptr
         cmp file_entry_sec [si], 0
         jne fes_ne_0
         mov ah, 2
         jmp exit_func_get_file_entry
fes_ne_0:
         lea si, file_entry_sec
         add si, current_file_entry_ptr
         lea di, file_entry
         mov cx, 32
         rep movsb          
         add current_file_entry_ptr, 32
         xor ah, ah
exit_func_get_file_entry:
         pop w0 
         pop di
         pop si
         pop dx
         pop cx
         pop bx
         ret            
get_file_entry endp

;file entry buf address = ds:si
;es:di = des buf address
get_file_name proc near  
         push cx
         push si
         push di
         pushf
         cld
         mov cx, 13
         rep movsb          
         popf
         pop di
         pop si
         pop cx 
         ret
get_file_name endp

;file entry buf address = ds:si
;es:di = des buf address
;ah = 0 entry(file/folder) has password, 1 if entry has not password 
get_file_password proc near
         push cx
         push si
         push di
         call get_file_attr
         and al, PROTECTED
         cmp al, PROTECTED
         jne get_file_password_file_has_not_password_1
         add si, 13
         mov al, [si]
         cmp al, 0
         je get_file_password_file_has_not_password_1
         cmp al, 0abh
         je get_file_password_file_has_not_password_1
         mov cx, 3
passwording:
         lodsb  
         xor al, 0abh ;password secret
         mov es:[di], al
         inc di
         loop passwording
         xor ah, ah
         jmp get_file_password_end_func
get_file_password_file_has_not_password_1:
         mov ah, 1                               
get_file_password_end_func: 
         pop di
         pop si
         pop cx
         ret        
get_file_password endp

;file entry buf address = ds:si
;es:di = des buf address
get_file_ext proc near
         push cx
         push si
         push di
         pushf
         cld
         add si, 16
         mov cx, 3
         rep movsb
         popf
         pop di
         pop si
         pop cx
         ret   
get_file_ext endp

;file entry buf address = ds:si
;al = attrs
get_file_attr proc near
         mov al, [si + 19]
         ret
get_file_attr endp

;file entry buf address = ds:si
;es:di = fdate
get_file_date proc near
         push ax
         push cx
         push si
         push di
         add si, 20
         mov al, [si]
         xor ah, ah
         add ax, 2000
         mov es:word ptr [di], ax
         add di, 2
         inc si
         mov cx, 5
get_file_date_ring:
         mov al, [si]
         mov es:[di], al
         inc si
         inc di
         loop get_file_date_ring
         pop di
         pop si
         pop cx
         pop ax
         ret
get_file_date endp 

;file entry buf address = ds:si
;w0 = file size
;w1 = next part
get_file_size proc near
         push ax    
         mov ax, word ptr [si + 26]
         mov w0, ax
         mov ax, word ptr [si + 28]
         mov w1, ax
         pop ax
         ret    
get_file_size endp

;file entry buf address = ds:si
;ax = file starting block
get_file_starting_block proc near
         mov ax, word ptr [si + 30]              
         ret              
get_file_starting_block endp

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
         mov eop0 [bp], 0
         call put_char
         mov al, 20h
         call put_char
         mov al, 8
         call put_char
get_comp_pass_bp_le0:
         jmp get_comp_pass_ring
not_bs:
         mov eop0 [bp], al 
         mov al, '*'
         call put_char
         inc bp
         cmp bp, 4
         je get_comp_pass_enter_pressed
         jmp get_comp_pass_ring
get_comp_pass_enter_pressed:
         mov eop0 [bp], 0
         lea di, eop0
         call str_comp                  
get_comp_pass_end_func:
         pop di                                
         pop bp
         ret
get_comp_pass endp

;no param
make_def_fids proc near
         mov dsm, 0ffeeh
         mov current_file_entry_sec_ptr, 19
         mov current_file_entry_ptr, 512
         ret
make_def_fids endp

;the path string addr = ds:si
;w3 = f_c
;w4 = dsm_n
;w5 = st_block
;b5 = other_attrs
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
          mov w4, 0ffeeh
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
          mov fn0 [di], al
          inc di
          cmp di, 13
          jg check_path_give_error
          jmp check_path_sub_loop_1
exit_check_path_sub_loop_1: 
          mov fn0 [di], 0
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
          mov eop0 [di], al
          inc di
          cmp di, 3
          jg check_path_give_error
          jmp check_path_sub_loop_2
exit_check_path_sub_loop_2:
          mov eop0 [di], 0
          cmp di, 0
          je check_path_give_error
          cmp al, ')'
          jne check_path_give_error
          cmp byte ptr[si], 0
          jne check_path_give_error
          mov current_file_entry_ptr, 512
          mov w3, 1 ;x = 1
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          ;we don't need to push si reg into the stack
          ;because here is the final step of this function
          lea si, file_entry
          ;es is set
          lea di, fn1
          call get_file_name
          ;si is set
          ;es is set
          lea di, eop1
          call get_file_ext
          ;si is set
          call get_file_attr
          ;al is attrs
          ;attrs backups
          mov b3, al
          mov b4, al
          mov b5, al ;other_attrs 
          mov b6, al
check_path_sub_loop_3:
          lea si, fn0
          ;es is set
          lea di, fn1
          call str_comp
          cmp ah, 1
          jne check_path_sub_loop_3_invalid_file
check_path_sub_loop_3_ok1:
          lea si, eop0
          ;es is set
          lea di, eop1
          call str_comp
          cmp ah, 1
          jne check_path_sub_loop_3_invalid_file
check_path_sub_loop_3_ok2:
          and b3, DELETED
          cmp b3, DELETED
          je check_path_sub_loop_3_invalid_file
check_path_sub_loop_3_ok3:
          and b4, FOLDER
          cmp b4, FOLDER
          jne exit_check_path_sub_loop_3
check_path_sub_loop_3_invalid_file:
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          lea si, file_entry
          ;es is set
          lea di, fn1
          call get_file_name
          ;si is set
          lea di, eop1
          call get_file_ext
          call get_file_attr
          ;al is attrs
          mov b3, al
          mov b4, al
          mov b5, al ;other attrs
          mov b6, al
          inc w3 ;x ++
          jmp check_path_sub_loop_3
exit_check_path_sub_loop_3:           
          ;w3 is set
          ;b5 is set
          lea si, file_entry
          call get_file_starting_block
          ;ax is file starting block
          mov w5, ax
          and b6, PROTECTED             
          cmp b6, PROTECTED
          jne check_path_file_is_not_pro
check_path_file_is_pro:
          mov ah, 3
          jmp check_path_end_func
check_path_file_is_not_pro:
          xor ah, ah
          jmp check_path_end_func                 
al_is_zero:
          mov current_file_entry_ptr, 512
          mov w3, 1
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          ;we don't need to push si reg into the stack
          ;because here is the final step of this function
          lea si, file_entry
          ;es is set
          lea di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          ;al is attrs
          ;attrs backups
          mov b3, al
          mov b4, al
          mov b5, al ;other_attrs 
          mov b6, al
check_path_sub_loop_4:
          lea si, fn0
          ;es is set
          lea di, fn1
          call str_comp
          cmp ah, 1
          jne check_path_sub_loop_4_invalid_fold
check_path_sub_loop_4_ok1:
          and b3, DELETED
          cmp b3, DELETED
          je check_path_sub_loop_4_invalid_fold
check_path_sub_loop_4_ok2:
          and b4, FOLDER
          cmp b4, FOLDER
          je exit_check_path_sub_loop_4
check_path_sub_loop_4_invalid_fold:
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          lea si, file_entry
          ;es is set
          lea di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          ;al is attrs
          ;attrs backups
          mov b3, al
          mov b4, al
          mov b5, al ;other_attrs 
          mov b6, al
          inc w3 ;x++
          jmp check_path_sub_loop_4 
exit_check_path_sub_loop_4:
          ;w3 is set
          ;b5 is set
          lea si, file_entry
          call get_file_starting_block
          ;ax is starting block
          mov w5, ax
          and b6, PROTECTED
          cmp b6, PROTECTED
          jne check_path_fold_is_not_pro
check_path_fold_is_pro:
          mov ah, 4
          jmp check_path_end_func
check_path_fold_is_not_pro:
          mov ah, 2
          jmp check_path_end_func                                                                        
al_is_dot:
          cmp [si], 0
          je check_path_give_error
          mov current_file_entry_ptr, 512
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error
          ;ATTENTION
          ;WE NEED TO push si into the stack
          ;because here is not final step and there is some folders and sub folders and files after this
          push si
          lea si, file_entry
          ;es is set
          lea di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          ;al is attrs
          ;attrs backups
          mov b3, al
          mov b4, al
          ;we don't need b5, in this version of CCS 
          mov b6, al
check_path_sub_loop_5:
          lea si, fn0
          ;es is set
          lea di, fn1
          call str_comp
          cmp ah, 1
          jne check_path_sub_loop_5_invalid_fold
check_path_sub_loop_5_ok1:
          and b3, DELETED
          cmp b3, DELETED
          je check_path_sub_loop_5_invalid_fold
check_path_sub_loop_5_ok2:
          and b4, FOLDER
          cmp b4, FOLDER
          je exit_check_path_sub_loop_5
check_path_sub_loop_5_invalid_fold:
          call get_file_entry
          cmp ah, 0
          jne check_path_give_error2
          lea si, file_entry
          ;es is set
          lea di, fn1
          call get_file_name
          ;si is set
          call get_file_attr
          ;al is attrs
          ;attrs backups
          mov b3, al
          mov b4, al
          ;we don't need b5, in this version of CCS 
          mov b6, al
          jmp check_path_sub_loop_5
exit_check_path_sub_loop_5:
          lea si, file_entry
          ;es is set
          lea di, eop1
          call get_file_password
          cmp ah, 1
          je check_path_fold_has_not_password
          lea si, ccs_security_sys_msg
          call print_str
          lea si, the_msg
          call print_str
          lea si, the_folder_msg
          call print_str
          lea si, fn1
          call print_str
          lea si, next_part_of_ss_msg
          call print_str
          lea si, password_msg
          call print_str
          ;pushing eop0 into the stack
          mov ah, eop0[0]
          mov al, eop0[1]
          push ax
          mov ah, eop0[2]
          mov al, eop0[3]
          push ax
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          lea si, eop1
          call get_comp_pass
          mov bh, ah
          ;taking eop0 from stack
          pop ax
          mov eop0 [3], al
          mov eop0 [2], ah
          pop ax
          mov eop0[1], al
          mov eop0[0], ah
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          cmp bh, 1
          je check_path_valid_password
          lea si, invalid_pass_msg
          call print_str
          jmp check_path_give_error2
check_path_valid_password:
          lea si, valid_pass_msg
          call print_str    
check_path_fold_has_not_password:
          lea si, file_entry
          call get_file_starting_block
          mov dsm, ax
          mov w4, ax
          pop si
          jmp check_path_main_loop
check_path_give_error2:
          pop si                   
check_path_give_error:
          mov w3, 0
          mov w4, 0ffeeh
          mov w5, 0
          mov b5, 0ffh
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

;file path buf addr = ds:si
;file io handle buf addr = es:di
;WARNING ALL DATA IN THESE ARRAY'S WILL BE LOST <<fn0>>, <<fn1>>, <<eop0>>, <<eop1>>
openfile proc near
          push ax
          push si
          push di
          ;si is set
          call check_path
          push ax
          mov ax, w3
          mov word ptr [di], ax
          mov ax, w4
          mov word ptr [di + 2], ax
          mov ax, w5
          mov word ptr [di + 4], ax
          mov al, b5
          mov byte ptr [di + 6], al
          pop ax
          cmp ah, 0
          je open_file_end_func  
open_file_ah_test_1:
          cmp ah, 3
          jne set_invalid_fh
          push di
          lea si, file_entry
          ;es is set
          lea di, fn1
          call get_file_name
          ;es is set
          lea di, eop1
          call get_file_password
          pop di
          lea si, ccs_security_sys_msg
          call print_str
          lea si, the_msg
          call print_str
          lea si, the_folder_msg
          call print_str
          lea si, fn1
          call print_str
          lea si, next_part_of_ss_msg
          call print_str
          lea si, password_msg
          call print_str
          lea si, eop1
          call get_comp_pass
          cmp ah, 1
          je open_file_valid_password
          lea si, invalid_pass_msg
          call print_str
          jmp set_invalid_fh
open_file_valid_password:
          lea si, valid_pass_msg
          call print_str
          jmp open_file_end_func               
set_invalid_fh:     
          mov word ptr [di], 0ffffh
          mov word ptr [di + 2], 0ffffh
          mov word ptr [di + 4], 0ffffh
          mov byte ptr [di + 6], 0ffh    
open_file_end_func:
          pop di
          pop si
          pop ax         
          ret
openfile endp

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

;file io handle buf addr = ds:si
;buffer addr = es:bx
;ah = 1 if file is empty (des buf will fill by 0xff), 0xff if eof, 0 if no error, 2 if read error 
readfile proc near
          push bx
          push cx
          ;mov ax, word ptr [si + 4]
          ;call disp_num
          ;call new_line
          cmp word ptr [si + 4], 0
          jne read_file_f_input_nt
          mov cx, 512
read_file_loop:
          mov [bx], 0ffh
          inc bx     
          loop read_file_loop
          mov ah, 1
          jmp read_file_end_func     
read_file_f_input_nt:
          cmp word ptr [si + 4], 0ffffh
          je read_file_is_eof
          mov cx, word ptr [si + 4]
          add cx, 35
          mov w0, cx
          mov b0, 1
          ;es is set
          ;bx is set
          call read_fdd_sector
            
          mov cx, word ptr [si + 4]
          push di
          push si
          mov si, cx                 
          call convert_fdd_fptt_index2sec          
          push es
          push di
          push ds
          pop es
          mov b0, 1
          ;es is set
          lea bx, file_pt_table
          ;w0 is set
          call read_fdd_sector
          pop di
          pop es
          pop si
          ;converting byte to word
          dec di
          mov ax, 2
          mul di
          mov di, ax
          mov cx, file_pt_table [di]
          
          ;call new_line
          ;mov ax, cx
          ;call disp_num
          ;call new_line
          ;mov ax, di
          ;call disp_num
          ;call new_line
          ;call new_line
          
          mov word ptr [si + 4], cx
          pop di
          ;cmp ah, 0
          ;jne read_file_error
          xor ah, ah 
          jmp read_file_end_func
read_file_error:
          mov ah, 2      
read_file_is_eof:
          mov ah, 0ffh       
read_file_end_func:
          pop cx
          pop bx                    
          ret
readfile endp

_main proc near      
         lea si, pls_wait_msg
         call print_str
         
;;;;;;;;;;;;;;;;;;;;;PART1
         call new_line
         lea si, loading_msg
         call print_str
         lea si, fil_1_name
         call print_str
         lea si, three_dots
         call print_str

         lea di, fh0
         lea si, fil_1_name
         call openfile
         cmp word ptr [di], 0ffffh
         jne _main_next_con_0
         ;display error
         call new_line
         lea si, fil_nf_err_p1
         call print_str
         lea si, fil_1_name
         call print_str
         lea si, fil_nf_err_p2
         call print_str
         call getch
         jmp _main_end_func
_main_next_con_0:
         push es
         mov ax, 1000h
         mov es, ax
         
         lea si, fh0
         mov bx, 100h
         mov cx, FIL_1_SEC_COUNT
fil_1_loop:
         call readfile
         cmp ah, 0
         jne _main_end_func
         add bx, 512  
         loop fil_1_loop
         pop es   
;;;;;;;;;;;;;;;;;;;;;PART2
         call new_line
         lea si, loading_msg
         call print_str
         lea si, fil_2_name
         call print_str
         lea si, three_dots
         call print_str
         
         lea di, fh1
         lea si, fil_2_name
         call openfile
         cmp word ptr [di], 0ffffh
         jne _main_next_con_1
         ;display error
         call new_line
         lea si, fil_nf_err_p1
         call print_str
         lea si, fil_2_name
         call print_str
         lea si, fil_nf_err_p2
         call print_str
         call getch
         jmp _main_end_func
_main_next_con_1:
         push es
         mov ax, 2000h
         mov es, ax
         
         lea si, fh1
         mov bx, 100h
         mov cx, FIL_2_SEC_COUNT
fil_2_loop:
         call readfile
         cmp ah, 0
         jne _main_end_func
         add bx, 512  
         loop fil_2_loop
         pop es
;;;;;;;;;;;;;;;;;;;;PART3
         call new_line
         lea si, loading_msg
         call print_str
         lea si, fil_3_name
         call print_str
         lea si, three_dots
         call print_str
         
         lea di, fh2
         lea si, fil_3_name
         call openfile
         cmp word ptr [di], 0ffffh
         jne _main_next_con_2
         ;display error
         call new_line
         lea si, fil_nf_err_p1
         call print_str
         lea si, fil_3_name
         call print_str
         lea si, fil_nf_err_p2
         call print_str
         call getch
         jmp _main_end_func
_main_next_con_2:
         mov ax, 3000h
         mov es, ax
         
         lea si, fh2
         mov bx, 100h
         mov cx, FIL_3_SEC_COUNT
fil_3_loop:
         call readfile
         cmp ah, 0
         jne _main_end_func
         add bx, 512  
         loop fil_3_loop

         ;1000:0100 INTS(SSE)
         ;2000:0100 HDD(SSE)
         ;3000:0100 INTER(SSE)
         
         mov ax, 1000h
         mov es, ax
         mov ds, ax
         cli
         mov ss, ax
         mov sp, 0FFEEh
         sti
         
         db 09Ah
         dw 0100h
         dw 1000h
         
         mov ax, 2000h
         mov es, ax
         mov ds, ax
         cli
         mov ss, ax
         mov sp, 0FFEEh
         sti
         
         db 09Ah
         dw 0100h
         dw 2000h
         
         mov ax, 3000h
         mov es, ax
         mov ds, ax
         cli
         mov ss, ax
         mov sp, 0FFEEh
         sti
         
         db 09Ah
         dw 0100h
         dw 3000h

         mov ax, cs
         mov ds, ax
         
         call new_line
         lea si, ret_msg
         call print_str                  
_main_end_func:
         call new_line
         lea si, ret_msg
         call print_str
         ret
_main endp
end prog_entry