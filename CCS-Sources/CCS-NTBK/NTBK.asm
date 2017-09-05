;note-book.asm
.model small
.586
.code

org 100h
prog_entry:
jmp start_point
nop

   welcome_msg db 0ah, 0dh, "CCS-Note Book v1.0 (written by Ali Ghanbari)", 0ah, 0dh, 0
   menu_msg db "Press n/a/e(to New file/Append/Exit): ", 0
   ESC_msg db 0ah, 0dh, "Attention: Press ESC to exit and save.", 0ah, 0dh, 0
   addr_msg db 0ah, 0dh, "Enter new file's address: ", 0
   prs_key db 0ah, 0dh, "Press any key...", 0
   fn db 80 dup (0)
   eop db 5 dup (0)
   buf db 512 dup (0)
   fh db 10 dup (0)
   w1 dw ?
start_point:
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

;al = got ch
getche proc near
      xor ah, ah
      int 16h
      call put_char
      ret
getche endp

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

;address of buffers = es:di
get_str proc near
      push ax
      push cx
      push di
      xor cx, cx
get_str_loop:
      call getch
      cmp al, 13
      je exit_get_str_loop
get_str_bs:
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
exit_get_str_loop0:
      call getch
      cmp al, 13
      je exit_get_str_loop
      cmp al, 8
      je get_str_bs
      jmp exit_get_str_loop0            
exit_get_str_loop1:
      jmp get_str_loop
exit_get_str_loop:
      mov byte ptr es:[di], 0

      pop di
      pop cx
      pop ax
      ret
get_str endp

;count = cx
go_back proc near
      push ax
      push cx
go_back_main_loop:
      mov al, 8
      call put_char
      loop go_back_main_loop
      pop cx
      pop ax  
      ret
go_back endp

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

_main proc near
      lea si, welcome_msg
      call print_str
      lea si, menu_msg
      call print_str
      
      call getche
      call new_line
      cmp al, 'e'
      je _main_end_func
      cmp al, 'a'
      je _main_append
      cmp al, 'n'
      jne _main_end_func
      lea si, addr_msg
      call print_str
      
      ;es is set
      lea di, fn
      call get_str
      
      lea si, fn
      call path_inter
      cmp bp, 0ffffh
      je _main_end_func
      
      mov ah, 0eh
      xor al, al
      lea si, fn
      lea di, eop
      mov word ptr [di], 0
      call _int
      cmp ah, 1
      je _main_end_func
_main_write_to_file:      
      mov ah, 0ah
      lea si, fn
      lea di, fh
      call _int
      
      call new_line
      lea si, ESC_msg
      call print_str
      
      ;es is set
      lea di, buf
      xor cx, cx
_get_str_loop:
      call getch
      cmp al, 27
      je _exit_get_str_loop
_get_str_bs:
      cmp al, 8
      jne _get_str_not_bs
      cmp cx, 0
      jle _get_str_cx_le0
      dec cx
      dec di
      mov byte ptr es:[di], 0
      call put_char
      mov al, 20h
      call put_char
      mov al, 8
      call put_char
_get_str_cx_le0:
      jmp _get_str_loop
_get_str_not_bs:
      cmp al, 13
      jne _get_str_alne213
      mov byte ptr es:[di], 0ah
      inc di
      mov byte ptr es:[di], al
      mov al, 0ah
      call put_char
      mov al, 0dh
      call put_char
      inc di
      inc cx
      jne _exit_get_str_loop1
_get_str_alne213:
      mov byte ptr es:[di], al
      call put_char
      inc di
      inc cx
;_exit_get_str_loop0:
;      call getch
;      cmp al, 27
;      je _exit_get_str_loop
;      cmp al, 8
;      je get_str_bs
;      jmp _exit_get_str_loop0            
_exit_get_str_loop1:
      jmp _get_str_loop
_exit_get_str_loop:
      mov byte ptr es:[di], 0
      ;;;;;;;;;;;
      
      push cs
      push cs
      pop ds
      pop es      
      mov ah, 0ch
      lea si, fh
      ;es is set
      lea di, buf
      call _int
      cmp ah, 0
      jne _main_end_func
      
      lea si, prs_key
      call print_str
      call getch
      jmp _main_end_func     
_main_append:
      lea si, addr_msg
      call print_str
      
      ;es is set
      lea di, fn
      call get_str
      
      lea si, fn
      call path_inter
      cmp bp, 0ffffh
      je _main_end_func
      
      jmp _main_write_to_file       
_main_end_func:
      ret
_main endp
end prog_entry