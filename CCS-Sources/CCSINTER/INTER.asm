;INTER.asm
.model small
.586
.code
NORMAL     equ 0
READONLY   equ 1
HIDDEN     equ 2
FOLDER     equ 4
V_FOLDER   equ 8 ;not supported by CCS 10 
DELETED    equ 10h
PROTECTED  equ 20h

org 100h
prog_entry:
jmp start_point
nop
   w1: dw ?
   buf0 db 40 dup (?)
   buf1 db 514 dup (?)
   fp0 db 40 dup (?)
   fp1 db 40 dup (?)
   eop0 db 4 dup (?)
   eop1 db 4 dup (?)
   fh0 db 10 dup (?)
   fh1 db 10 dup (?)
   ;about str
   sys_name db 0ah, 0dh, "CCS-OS v10.0", 0ah, 0dh, 0
   sys_copy db "Copyright (C) 2001-2006 by Ali Ghanbari", 0ah, 0dh, 0
   sys_info db "Version 10.05;" , 0ah, 0dh,
            "This user interface and it's kernel are written by Ali Ghanbari; I will register it "
            db "and I will write another version of CCS and I will make it better...", 0ah, 0dh, 0   
   ;;;;;;;;;;
   sys_com_line db 0ah, 0dh, "Enter CCS Command [without capital]: ", 0
   sys_crt_msg_0 db 0ah, 0dh, "Enter folder's path: ", 0
   sys_com_err db 0ah, 0dh, "Invalid CCS Command.", 0ah, 0dh, 0 
   sys_crt_fld db 0ah, 0dh, "fatal : unable to create folder.", 0ah, 0dh, 0
   sys_crt_pass_0 db 0ah, 0dh, "Please enter password if you want your folder be protected [3]: ", 0
   sys_crt_pass_1 db 0ah, 0dh, "Please say yes if you want your folder be readonly [y/n]: ", 0
   sys_crt_pass_2 db 0ah, 0dh, "Please say yes if you want your folder be hidden [y/n]: ", 0
   sys_crt_plz db 0ah, 0dh, "Creating...", 0
   sys_dlt_msg_0 db 0ah, 0dh, "Enter file/folder path to delete: ", 0
   sys_dlt_que db 0ah, 0dh, "Are you sure you want to delete ? [y/n]: ", 0
   sys_dlt_plz db 0ah, 0dh, "Deletting...", 0
   sys_sf_msg db "Enter file name to show it: ", 0 
   sys_sf_msg_0 db 0ah, 0dh, "Press any key to continue reading...", 0ah, 0dh, 0  
   sys_sf_err0 db 0ah, 0dh, "The file is empty!", 0
   sys_sf_err1 db 0ah, 0dh, "An I/O error or file not found!", 0
   sys_sd_msg db 0ah, 0dh, "Enter directory path to show it's inside: ", 0
   sys_sp_msg db 0ah, 0dh, "Enter a CCS-OS executable (SSE) or other compatible file name to perform it", 0ah, 0dh
              db ":", 0 
   sys_sp_loading_msg db 0ah, 0dh, "Loading...", 0
   sys_cf_source_msg db 0ah, 0dh, "Enter source file name: ", 0
   sys_cf_des_msg db 0ah, 0dh, "Enter destination file name: ", 0 
   sys_cf_copying db 0ah, 0dh, "Copying...", 0
   sys_cf_moving db 0ah, 0dh, "Moving...", 0
   sys_crt_fil db 0ah, 0dh, "fatal : unable to create file.", 0ah, 0dh, 0
   sys_crt_pass_fil_0 db 0ah, 0dh, "Please enter password if you want your file be protected [3]: ", 0
   sys_crt_pass_fil_1 db 0ah, 0dh, "Please say yes if you want your file be readonly [y/n]: ", 0
   sys_crt_pass_fil_2 db 0ah, 0dh, "Please say yes if you want your file be hidden [y/n]: ", 0
   sys_crt_msg_fil_0 db 0ah, 0dh, "Enter file's path: ", 0
   
   ;CCS Commands
   c_about db "about", 0
   c_reboot db "reboot", 0
   c_crt_fold db "crt_fold", 0
   c_delete db "delete", 0
   c_show_f db "show_file", 0
   c_show_dir db "show_dir", 0
   c_crt_proc db "crt_proc", 0 
   c_copy db "copy_file", 0
   c_move db "move_file", 0
   c_crt_file db "crt_file", 0
   c_clrscr db "clrscr", 0
   ;;;;;;;;;;;;;
start_point:
call _main
retf
nop

;al = the character
put_char proc near
         push ax
         mov ah, 0
         int 20h
         pop ax
         ret
put_char endp

;al = got ch
getch proc near
         mov ah, 2
         int 20h
         ret
getch endp

;number = ax
disp_num proc near
      push ax
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
      pop ax
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

;address of string = ds:si
print_str proc near
         push ax
         mov ah, 1
         int 20h
         pop ax
         ret
print_str endp

;address of buffers = es:di
get_str proc near
         push ax
         mov ah, 4
         int 20h
         pop ax
         ret
get_str endp

;address of buffers = es:di
get_pass proc near
         push ax
         mov ah, 5
         int 20h
         pop ax
         ret
get_pass endp

;no param
print_about proc near
         push si
         lea si, sys_name
         call print_str
         lea si, sys_copy
         call print_str
         lea si, sys_info
         call print_str
         pop si
         ret
print_about endp

;no param
print_com_line proc near
         push si      
         lea si, sys_com_line
         call print_str
         pop si
         ret      
print_com_line endp

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

;ds:si = path
;new path = ds:si
;bp = fd 0 or hd 1
path_inter proc near
         push ax
         push si
         cmp byte ptr [si], 'f'
         jne path_inter_h_check
         cmp byte ptr [si + 1], 'd'
         jne path_inter_give_error
         cmp byte ptr [si + 2], '.'
         jne path_inter_give_error
         add si, 3
path_inter_fd_loop:
         lodsb
         cmp al, 0
         je exit_path_inter_fd_loop
         mov byte ptr [si - 4], al
         jmp path_inter_fd_loop
exit_path_inter_fd_loop:
         mov byte ptr [si - 4], al ;al = 0
         xor bp, bp
         jmp path_inter_end_func
path_inter_h_check:
         cmp byte ptr [si], 'h'
         jne path_inter_give_error
         cmp byte ptr [si + 1], 'd'
         jne path_inter_give_error
         cmp byte ptr [si + 2], '.'
         jne path_inter_give_error
         cmp byte ptr [si + 3], '0'
         jne path_inter_next_part_1
         mov al, 1
         jmp path_inter_con_0
path_inter_next_part_1:
         cmp byte ptr [si + 3], '1'
         jne path_inter_next_part_2
         mov al, 2
         jmp path_inter_con_0
path_inter_next_part_2:
         cmp byte ptr [si + 3], '2'
         jne path_inter_next_part_3
         mov al, 3
         jmp path_inter_con_0
path_inter_next_part_3:
         cmp byte ptr [si + 3], '3'
         jne path_inter_give_error
         mov al, 4
         jmp path_inter_con_0
path_inter_con_0:
         cmp byte ptr [si + 4], '.'
         jne path_inter_give_error
         mov ah, 8
         int 21h
         
         add si, 5
path_inter_hd_loop:
         lodsb
         cmp al, 0
         je exit_path_inter_hd_loop
         mov byte ptr [si - 6], al
         jmp path_inter_hd_loop
exit_path_inter_hd_loop:
         mov byte ptr [si - 6], al ;al = 0
         mov bp, 1          
         jmp path_inter_end_func
path_inter_give_error:
         
         mov byte ptr [si], 0
         mov bp, 0ffffh
path_inter_end_func:
         pop si
         pop ax
         ret
path_inter endp

_int proc near
         cmp bp, 0
         jne _int_hd
         int 20h
         jmp _int_end_func
_int_hd:
         int 21h
_int_end_func:
         ret
_int endp

sec_int proc near
         cmp word ptr cs:[w1], 0
         jne sec_int_hd
         int 20h
         jmp sec_int_end_func
sec_int_hd:
         int 21h
sec_int_end_func:
         ret
sec_int endp

create_folder proc near
         lea si, sys_crt_msg_0
         call print_str
         lea di, fp0
         call get_str
         call new_line
         
         lea si, fp0
         call path_inter
         cmp bp, 0ffffh
         je create_folder_end_func
         
         lea si, sys_crt_pass_0
         call print_str
         push es
         push cs
         pop es
         lea di, eop0
         call get_pass
         pop es
         call new_line
         
         xor dl, dl
         lea si, sys_crt_pass_1
         call print_str
         call getch
         call new_line
         cmp al, 'n'
         je _crt_n1
         cmp al, 'y'
         jne _crt_n1
         
         mov dl, READONLY
         
_crt_n1:
         lea si, sys_crt_pass_2
         call print_str
         call getch
         call new_line
         cmp al, 'n'
         je _crt_n2_no
         cmp al, 'y'
         jne _crt_n2
         cmp dl, READONLY
         je crt_fold_ale2RO
         xor dl, dl
crt_fold_ale2RO:        
         or dl, HIDDEN
         jmp _crt_n2 
_crt_n2_no:
         cmp dl, READONLY
         je _crt_n2
         xor dl, dl 
_crt_n2:       
         lea si, sys_crt_plz
         call print_str
         lea si, fp0
         lea di, eop0
         mov ah, 0fh
         mov al, dl
         call _int
           
create_folder_end_func:
         call new_line
         ret     
create_folder endp

delete proc near
         lea si, sys_dlt_msg_0
         call print_str
         lea di, fp0
         call get_str
         call new_line
         
         lea si, fp0
         call path_inter
         cmp bp, 0ffffh
         je delete_end_func
         
         lea si, sys_dlt_que
         call print_str
         call getch
         call new_line
         cmp al, 'n'
         je _main_loop
         cmp al, 'y'
         jne _main_loop
         call new_line
         lea si, sys_dlt_plz
         call print_str

         lea si, fp0
         mov ah, 0dh
         call _int
         
delete_end_func:
         call new_line    
         ret
delete endp

show_f proc near
         call new_line
         lea si, sys_sf_msg
         call print_str
         lea di, fp0
         call get_str
         call new_line
         
         lea si, fp0
         call path_inter
         cmp bp, 0ffffh
         je show_f_give_error
         
         ;ds and es are set
         lea si, fp0
         lea di, fh0
         mov ah, 0ah
         call _int
         
         cmp word ptr [di], 0ffffffffh 
         je show_f_give_error
show_f_main_loop:
         lea si, fh0
         lea bx, buf1
         mov ah, 0bh
         call _int
         cmp ah, 1
         je show_f_empty
         cmp ah, 0ffh
         je show_f_end_func
         cmp ah, 0
         jne show_f_give_error
         
         mov byte ptr buf1 [513], 0         
         
         call new_line
         lea si, buf1
         call print_str
         call new_line
         
         lea si, sys_sf_msg_0
         call print_str
         call getch
         jmp show_f_main_loop                         
show_f_empty:
         lea si, sys_sf_err0
         call print_str
         jmp show_f_end_func    
show_f_give_error:
         lea si, sys_sf_err1
         call print_str
show_f_end_func:
                         
         ret
show_f endp

show_dir proc near
         lea si, sys_sd_msg
         call print_str
         lea di, fp0
         call get_str
         call new_line
         
         lea si, fp0
         call path_inter
         cmp bp, 0ffffh
         je show_dir_end_func
         
         lea si, fp0
         mov ah, 12h
         call _int
         
show_dir_end_func:
         call new_line
         ret
show_dir endp

crt_proc proc near
         push es
         
         lea si, sys_sp_msg
         call print_str
         lea di, fp0
         call get_str
         call new_line
         lea si, fp0
         call path_inter
         cmp bp, 0ffffh
         je crt_proc_give_error 
         
         ;ds and es are set
         lea si, fp0
         lea di, fh0
         mov ah, 0ah
         call _int
         
         cmp word ptr [di], 0ffffffffh 
         je crt_proc_give_error
         
         lea si, sys_sp_loading_msg
         call print_str
         call new_line
         
         mov ax, 4000h
         mov es, ax
         mov bx, 100h
         
crt_proc_main_loop:
         push bx 
         push es
         lea si, fh0             
         mov ah, 0bh
         call _int         
         pop es
         pop bx
         
         cmp ah, 1
         je crt_proc_end_func
         cmp ah, 0ffh
         je crt_proc_exit_main_loop
         cmp ah, 0
         jne crt_proc_give_error
         add bx, 512
         jmp crt_proc_main_loop

crt_proc_exit_main_loop:
         
         mov ax, sp
         push es
         push es
         pop ds
         pop ss
         mov sp, 0ffeeh
         pusha
         
         db 09Ah
         dw 0100h
         dw 4000h
         
         popa
         push cs
         push cs
         pop ds
         pop ss
         mov sp, ax
                                 
         jmp crt_proc_end_func
crt_proc_give_error:
         lea si, sys_sf_err1
         call print_str
         
crt_proc_end_func:                                  
         pop es         
         ret
crt_proc endp

copy_file proc near
         lea si, sys_cf_source_msg
         call print_str
         lea di, fp0
         call get_str
         lea si, sys_cf_des_msg
         call print_str
         lea di, fp1
         call get_str
         call new_line
         
         lea si, fp0
         call path_inter
         cmp bp, 0ffffh
         je copy_file_give_error
         push bp
         lea si, fp1
         call path_inter
         mov word ptr cs:[w1], bp
         pop bp
         cmp word ptr cs:[w1], 0ffffh
         je copy_file_give_error
         
         ;ds and es are set
         lea si, fp0
         lea di, fh0
         mov ah, 0ah
         call _int
         
         cmp word ptr [di], 0ffffffffh 
         je copy_file_give_error
         
         lea si, fp1
         lea di, eop0
         mov word ptr [di], 0
         xor al, al
         mov ah, 0eh
         call sec_int
         
         cmp ah, 1
         je copy_file_give_error
         
         lea si, fp1
         lea di, fh1
         mov ah, 0ah
         call sec_int
         
         cmp word ptr [di], 0ffffffffh 
         je copy_file_give_error
         
         lea si, sys_cf_copying
         call print_str
         
         lea bx, buf1
copy_main_loop:         
         push bx 
         push es         
         lea si, fh0
         mov ah, 0bh
         call _int
         pop es
         pop bx
         
         cmp ah, 1
         je copy_file_end_func
         cmp ah, 0ffh
         je exit_copy_main_loop        
         cmp ah, 0
         jne copy_file_give_error
         
         push bx 
         push es         
         lea si, fh1
         mov di, bx
         mov ah, 0ch
         call sec_int
         pop es
         pop bx
         
         cmp ah, 0
         jne copy_file_give_error         
         jmp copy_main_loop
exit_copy_main_loop:         
         jmp copy_file_end_func
copy_file_give_error:
         lea si, sys_sf_err1
         call print_str
         
copy_file_end_func:         
         ret 
copy_file endp

move_file proc near
         call copy_file
         lea si, sys_cf_moving
         call print_str                  
         lea si, fp0
         mov ah, 0dh
         call _int
         cmp ah, 1
         je move_file_give_error         
         jmp move_file_end_func
move_file_give_error:
         lea si, sys_sf_err1
         call print_str
move_file_end_func:         
         ret
move_file endp

create_file proc near
         lea si, sys_crt_msg_fil_0
         call print_str
         lea di, fp0
         call get_str
         call new_line
         
         lea si, fp0
         call path_inter
         cmp bp, 0ffffh
         je create_file_end_func
         
         lea si, sys_crt_pass_fil_0
         call print_str
         lea di, eop0
         call get_pass
         call new_line
         
         xor dl, dl
                  
         lea si, sys_crt_pass_fil_1
         call print_str
         call getch
         call new_line
         cmp al, 'n'
         je _crt_file_n1
         cmp al, 'y'
         jne _crt_file_n1
         
         mov dl, READONLY
         
_crt_file_n1:
         lea si, sys_crt_pass_fil_2
         call print_str
         call getch
         call new_line
         cmp al, 'n'
         je _crt_file_n2_no
         cmp al, 'y'
         jne _crt_file_n2
         cmp dl, READONLY
         je crt_file_ale2RO
         xor dl, dl
crt_file_ale2RO:        
         or dl, HIDDEN
         jmp _crt_file_n2 
_crt_file_n2_no:
         cmp dl, READONLY
         je _crt_file_n2
         xor dl, dl 
_crt_file_n2:
         
         call new_line
         
         lea si, sys_crt_plz
         call print_str
         lea si, fp0
         lea di, eop0
         mov ah, 0eh
         mov al, dl
         call _int

create_file_end_func:         
         call new_line     
         ret     
create_file endp

GOTO_XY PROC                    ;DL = X, DH = Y
      PUSH AX
      PUSH BX
      
      MOV AH, 02
      MOV BH, 00
      INT 10H

      POP BX
      POP AX
      RET
GOTO_XY ENDP

;no param
CLS PROC
      PUSH AX
      PUSH CX
      PUSH DX
      
      MOV AX, 0600H
      XOR CX, CX
      MOV DX, 184FH
      MOV BH, 07
      INT 10H
      XOR DX, DX
      CALL GOTO_XY
        
      POP DX
      POP CX
      POP AX
      RET
CLS ENDP

_main proc near
         call print_about
_main_loop:
         call print_com_line
         lea di, buf0
         call get_str
         ;di is set
         lea si, c_about
         call str_comp
         cmp ah, 1
         jne _next_com_1
         call print_about
         jmp _main_loop
_next_com_1:
         lea si, c_reboot
         call str_comp
         cmp ah, 1
         jne _next_com_2
         int 19h ;reboots computer
         jmp _main_loop
_next_com_2:
         lea si, c_crt_fold
         call str_comp
         cmp ah, 1
         jne _next_com_3
         call create_folder
         jmp _main_loop
_next_com_3:
         lea si, c_delete
         call str_comp
         cmp ah, 1
         jne _next_com_4
         call delete
         jmp _main_loop
_next_com_4:
         lea si, c_show_f
         call str_comp
         cmp ah, 1
         jne _next_com_5
         call show_f
         jmp _main_loop
_next_com_5:
         lea si, c_show_dir
         call str_comp
         cmp ah, 1
         jne _next_com_6
         call show_dir
         jmp _main_loop
_next_com_6:
         lea si, c_crt_proc
         call str_comp
         cmp ah, 1
         jne _next_com_7
         call crt_proc
         jmp _main_loop
_next_com_7:
         lea si, c_copy
         call str_comp
         cmp ah, 1
         jne _next_com_8
         call copy_file
         jmp _main_loop
_next_com_8:
         lea si, c_move
         call str_comp
         cmp ah, 1
         jne _next_com_9
         call move_file
         jmp _main_loop
_next_com_9:
         lea si, c_crt_file
         call str_comp
         cmp ah, 1
         jne _next_com_a
         call create_file
         jmp _main_loop
_next_com_a:
         lea si, c_clrscr
         call str_comp
         cmp ah, 1
         jne _next_com_b
         call cls
         jmp _main_loop
_next_com_b:
         lea si, sys_com_err
         call print_str
         jmp _main_loop
         ret
_main endp
end prog_entry