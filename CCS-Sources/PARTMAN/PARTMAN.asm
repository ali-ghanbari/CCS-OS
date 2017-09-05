;PARTMAN.asm
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
;;;;;;;;;;;;;;;;;;;;;;;;;;
DAP_PACKET_SIZE     equ 0
DAP_SECTORS_COUNT   equ 2
DAP_OFFSET_ADDR     equ 4
DAP_SEGMENT_ADDR    equ 6
DAP_SECTOR_NUMBER   equ 8
DAP_SECTOR_NUM_P2   equ 12
;;;;;;;;;;;;;;;;;;;;;;;;;;
PARTITION_1         equ 1beh
PARTITION_2         equ 1ceh
PARTITION_3         equ 1deh
PARTITION_4         equ 1eeh
MBR_SIGN            equ 1feh
;;;;;;;;;;;;;;;;;;;;;;;;;;
PART_BOOT_FLAG      equ 0
PART_CHS_BEGIN      equ 1
PART_TYPE_CODE      equ 4
PART_CHS_END        equ 5
PART_LBA_BEGIN      equ 8
PART_LEN            equ 12
;;;;;;;;;;;;;;;;;;;;;;;;;;
PART_TYPE_DEFINED   equ 1
PART_TYPE_UNDEFINED equ 0 
PART_TYPE_NTFS      equ 7
PART_TYPE_LIN_EXT   equ 83h
;;;;;;;;;;;;;;;;;;;;;;;;;;

org 100h
prog_entry:
jmp start_point
nop
      char_lim dw ?
      read_chars dw ?
      buf0 db 50 dup (?)
      sec_buf db 512 dup (?)
      part_man_0 db "Welcome to  CCS-OS 10.0 Partition Manager", 0
      part_man_1 db "CCS-HD-FS Partition Manager v1.0", 0  
      menu_0 db "Select an item:", 0ah, 0dh, 0
      menu_1 db "c : Create Partition.", 0ah, 0dh, 0
      menu_2 db "d : Delete Partition.", 0ah, 0dh, 0
      menu_3 db "s : Show Partitions.", 0ah, 0dh, 0
      menu_4 db "m : Make Bootable First Partition.", 0ah, 0dh, 0
      menu_5 db "e : exit.", 0ah, 0dh, 0
      menu_6 db 0ah, 0dh, "Enter Here: ", 0
      ud_part db "No partition defined.", 0
      prs_key db 0ah, 0dh, "Press any key...", 0
      hdd_err db "Error in reading H.D.D ...", 0
      hdd_full db "Error; H.D.D is full; you cannot create any partition.", 0
      crt_part_msg db "Partition created!", 0 
      crt_part_err db "Unable to create partition...", 0
      
      yes_msg db "Yes", 0
      no_msg db "No", 0
      ok_msg db "OK", 0
      
      none_loc_msg db "No entry", 0
      ntfs_msg db "NTFS", 0
      gtfs_msg db "CCS-HD-FS", 0
      lin_msg db "Linux-Ext", 0
      unknown_msg db "Unknown", 0
      
      ;5,7,8,5
      part_lst_tab db "<Partition>     <Type>       <Size(MB)>        <Healthy>     <Bootable>", 0
      part_size_que db "Enter partition size that you want to create [          ](MB)", 0
      d_part_que db 0ah, 0dh, "Do you want to delete partition (y/n) ?", 0   
      fix_mbr_que db 0ah, 0dh, "Error; Ivalid Master Boot Record;", 0ah,  0dh
                  db "Do you want fix it (y/n) ?", 0
             

start_point:
call _main
retf
nop

;ah = 0 if no error, 1 if error
read_hdd_sector proc near
      push bx
      push cx
      push dx
      mov ah, 02h
      mov al, 1
      mov ch, 0
      mov cl, 1
      mov dh, 0
      mov dl, 80h
      lea bx, sec_buf
      int 13h
      pop dx
      pop cx
      pop bx
      ret              
read_hdd_sector endp

;ah = 0 if no error, 1 if error
write_hdd_sector proc near
      push bx
      push cx
      push dx
      mov ah, 03h
      mov al, 1
      mov ch, 0
      mov cl, 1
      mov dh, 0
      mov dl, 80h
      lea bx, sec_buf
      int 13h
      pop dx
      pop cx
      pop bx
      ret              
write_hdd_sector endp

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
      mov word ptr [read_chars], cx
      cmp cx, word ptr [char_lim]
      jne exit_get_str_loop1
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
      mov word ptr [read_chars], cx
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

;no param
insert_tab proc near
      push ax
      push cx
ins_tab_loop:
      mov al, 20h
      call put_char
      loop ins_tab_loop    
      pop cx
      pop ax
      ret
insert_tab endp

;ah = 0 if h.d.d is empty, ah = 20 if h.d.d is full; ah is undefined part num 
;esi is availible entry point
check_hdd_partitions proc near
      cmp byte ptr sec_buf [PARTITION_1][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_p2
      xor ah, ah
      mov esi, 63
      ret 
chk_p2:
      cmp byte ptr sec_buf [PARTITION_2][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_p3
      mov ah, 2
      mov esi, dword ptr sec_buf [PARTITION_1][PART_LBA_BEGIN]
      add esi, dword ptr sec_buf [PARTITION_1][PART_LEN]  
      ret 
chk_p3:
      cmp byte ptr sec_buf [PARTITION_3][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_p4
      mov ah, 3
      mov esi, dword ptr sec_buf [PARTITION_2][PART_LBA_BEGIN]
      add esi, dword ptr sec_buf [PARTITION_2][PART_LEN]  
      ret
chk_p4:
      cmp byte ptr sec_buf [PARTITION_4][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_hdd_end_func
      mov ah, 4
      mov esi, dword ptr sec_buf [PARTITION_3][PART_LBA_BEGIN]
      add esi, dword ptr sec_buf [PARTITION_3][PART_LEN]  
      ret
chk_hdd_end_func:
      mov ah, 20
      ret
check_hdd_partitions endp

create_part proc near
      push cx
      call read_hdd_sector
      cmp ah, 0
      jne crt_p_give_error
      call check_hdd_partitions
      
      cmp ah, 20
      je crt_p_hdd_full
      
      xchg al, ah
      xor ah, ah
      push esi
      push ax
      
      call cls
      mov cx, 20
      call insert_tab
      lea si, part_man_0
      call print_str 
      call new_line
      add cx, 3
      call insert_tab
      lea si, part_man_1
      call print_str
      call new_line
      call new_line
      lea si, part_size_que
      call print_str
      mov cx, 15
      call go_back
      
      call get_num
      ;eax is set
      mov ebx, eax
      xor eax, eax
      pop ax
      cmp ax, 0
      jne crt_p_con_0
      mov ebp, PARTITION_1
      mov dl, 80h
      jmp crt_p_con_1
crt_p_con_0:
      mov cx, 16
      mul cx
      add ax, PARTITION_1
      sub ax, 10h
      movzx ebp, ax
      xor dl, dl
crt_p_con_1:
      pop esi
      mov byte ptr sec_buf [ebp][PART_BOOT_FLAG], dl
      mov byte ptr sec_buf [ebp][PART_TYPE_CODE], PART_TYPE_DEFINED
      mov dword ptr sec_buf [ebp][PART_LBA_BEGIN], esi
      mov eax, ebx
      mov ebx, 1048576
      mul ebx
      mov ebx, 512
      div ebx
      mov dword ptr sec_buf [ebp][PART_LEN], eax
      
      call new_line
      call new_line
      
      call put_boot_strap
      call write_hdd_sector
      cmp ah, 0
      jne crt_p_con_2
      
      lea si, crt_part_msg
      call print_str
      lea si, prs_key
      call print_str
      call getch
      jmp crt_p_end_func
      
crt_p_con_2:

      lea si, crt_part_err
      call print_str
      lea si, prs_key
      call print_str
      call getch
      jmp crt_p_end_func     
      
crt_p_give_error:
      call new_line         
      lea si, hdd_err
      call print_str
      lea si, prs_key
      call print_str
      call getch
      ret
crt_p_hdd_full:
      call new_line
      lea si, hdd_full
      call print_str
      lea si, prs_key
      call print_str
      call getch   
crt_p_end_func:
      pop cx         
      ret     
create_part endp

show_parts proc near
      push cx     
      call read_hdd_sector
      cmp ah, 0
      jne s_p_give_error
      call cls
      mov cx, 20
      call insert_tab
      lea si, part_man_0
      call print_str 
      call new_line
      add cx, 3
      call insert_tab
      lea si, part_man_1
      call print_str
      call new_line
      call new_line
      lea si, part_lst_tab
      call print_str
      call new_line
      mov cx, 1
      call insert_tab
      
      mov ebp, PARTITION_1
      mov ecx, 4
      mov eax, 1
      
      cmp byte ptr sec_buf [ebp][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      je shp_ud
      
      jmp shp_ft0
shp_loop:
      add ebp, 16
      inc eax
shp_ft0:
      push eax
      push ecx 
      
      cmp byte ptr sec_buf [ebp][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne shp_l5
      pop ecx
      pop eax
      jmp exit_shp_loop
shp_l5:
           
      ;eax is set
      call disp_num
      
      mov cx, 5
      call insert_tab
      
      cmp byte ptr sec_buf [ebp][PART_TYPE_CODE], PART_TYPE_NTFS
      jne shp_l0
      lea si, ntfs_msg
      call print_str
      jmp shp_con0
shp_l0:
      cmp byte ptr sec_buf [ebp][PART_TYPE_CODE], PART_TYPE_LIN_EXT
      jne shp_l1
      lea si, lin_msg
      call print_str
      jmp shp_con0
shp_l1:
      cmp byte ptr sec_buf [ebp][PART_TYPE_CODE], PART_TYPE_DEFINED
      jne shp_l2
      lea si, gtfs_msg
      call print_str
      jmp shp_con0
shp_l2:
      lea si, unknown_msg
      call print_str
shp_con0:
      mov cx, 5
      call insert_tab
      
      mov eax, dword ptr sec_buf [ebp][PART_LEN]
      mov ecx, 512
      mul ecx
      ;eax, edx is byte num
      mov ecx, 1048576
      div ecx
      ;eax is set
      call disp_num 
      
      mov cx, 9
      call insert_tab
      
      cmp dword ptr sec_buf [ebp][PART_LBA_BEGIN], 0
      je shp_l3
      lea si, ok_msg
      call print_str
      jmp shp_con1
shp_l3:
      lea si, none_loc_msg
      call print_str
shp_con1:
      mov cx, 6
      call insert_tab
         
      cmp byte ptr sec_buf [ebp][PART_BOOT_FLAG], 80h ;bootable?
      jne shp_l4
      lea si, yes_msg
      call print_str
      jmp shp_con2
shp_l4: 
      lea si, no_msg
      call print_str  
shp_con2:
      call new_line
      mov cx, 1
      call insert_tab   
      pop ecx
      pop eax
      dec ecx
      jnz shp_loop
exit_shp_loop:
      call new_line
      lea si, prs_key
      call print_str
      call getch
      jmp s_p_end_func
      
shp_ud:
      lea si, ud_part
      call print_str
      lea si, prs_key
      call print_str
      call getch
      jmp s_p_end_func
s_p_give_error:
      call new_line         
      lea si, hdd_err
      call print_str
      lea si, prs_key
      call print_str
      call getch         
s_p_end_func:
      pop cx 
      ret     
show_parts endp

delete_part proc near
      push cx      
      call new_line
      call read_hdd_sector
      cmp ah, 0
      jne d_p_give_error
      call check_hdd_partitions
      cmp ah, 0
      jne d_part_def
      
      lea si, ud_part
      call print_str
      lea si, prs_key
      call print_str
      call getch
      jmp d_part_end_func
d_part_def:
      cmp ah, 20
      jne d_part_isnot_full
      mov ebp, 1eeh
      jmp d_part_con_0
d_part_isnot_full:
      xchg al, ah
      xor ah, ah
      dec ax
      mov bx, 10h
      mul bx
      add ax, PARTITION_1
      sub ax, 10h
      movzx ebp, ax
d_part_con_0:
      lea si, d_part_que
      call print_str
      call getche
      cmp al, 'n'
      je d_part_end_func
      cmp al, 'y'
      jne d_part_con_0
      mov byte ptr sec_buf [ebp][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      call put_boot_strap
      call write_hdd_sector
      cmp ah, 0
      jne d_p_give_error       
      jmp d_part_end_func
d_p_give_error:
      call new_line      
      lea si, hdd_err
      call print_str
      lea si, prs_key
      call print_str
      call getch
d_part_end_func:
      pop cx      
      ret
delete_part endp

menu proc near
      call new_line
      call new_line
      lea si, menu_0
      call print_str
      lea si, menu_1
      call print_str
      lea si, menu_2
      call print_str
      lea si, menu_3
      call print_str
      lea si, menu_4
      call print_str
      lea si, menu_5
      call print_str
      lea si, menu_6
      call print_str
      call getche
      ;al is set
menu_le0:
      cmp al, 'c'
      jne menu_l0
      call create_part
      ret
menu_l0:
      cmp al, 'd'
      jne menu_l1
      call delete_part
menu_l1:
      cmp al, 'e'
      jne menu_l2
      ret
menu_l2:
      cmp al, 's'
      jne menu_l3
      call show_parts
      ret
menu_l3:
      cmp al, 'm'
      jne menu_le
      call make_bootable_first_part
      ret
menu_le:        
      ret
menu endp

print_name_of_part_man proc near
      push cx
pnpm0:                 
      call cls
      mov cx, 20
      call insert_tab
      lea si, part_man_0
      call print_str 
      call new_line
      add cx, 3
      call insert_tab
      lea si, part_man_1
      call print_str
      call menu
      cmp al, 'e'
      je pnpm1 
      jmp pnpm0
pnpm1:
      pop cx                
      ret
print_name_of_part_man endp 

;32-bit number = eax
disp_num proc near
      push ebx
      push edx
      mov ebx, 1000000000
      call to_deci
      mov ebx, 100000000
      call to_deci
      mov ebx, 10000000
      call to_deci
      mov ebx, 1000000
      call to_deci
      mov ebx, 100000
      call to_deci
      mov ebx, 10000
      call to_deci
      mov ebx, 1000
      call to_deci
      mov ebx, 100
      call to_deci
      mov ebx, 10
      call to_deci
      add al, 30h
      call put_char
      pop edx
      pop ebx
      ret
to_deci:
      xor edx, edx
      div ebx
      add al, 30h
      push edx
      call put_char
      pop eax
      ret
disp_num endp

;no param
put_boot_strap proc near
      push si
      push di
      push cx
      push ds
      push es
      pushf
      
      push cs
      push cs
      pop ds
      pop es
      mov si, 7C00h
      lea di, sec_buf
      mov cx, 0d0h;90h
      cld
      rep movsw
     
      popf
      pop es
      pop ds
      pop cx
      pop di
      pop si 
      ret
put_boot_strap endp

;eax = got num
;CF set if error, clear if succeeded
get_num proc near
      push di
      push ebx
      push ecx
      push edx

      mov word ptr [char_lim], 10
      lea di, buf0
      call get_str      
      mov cx, word ptr [read_chars]
      cmp cx, 0
      jle bad_dec_num
      xor eax, eax
      xor ebx, ebx
convert_dec_num:
      mov edx, 10
      mul edx
      jc bad_dec_num
      mov dl, buf0 [bx]
      sub dl, '0'
      js bad_dec_num
      cmp dl, 9
      ja bad_dec_num
      add eax, edx
      inc ebx
      loop convert_dec_num
done_dec_num:
      pop edx
      pop ecx
      pop ebx
      pop di
      ret
bad_dec_num:
      stc
      jmp done_dec_num
get_num endp

;no param
;ah = status 0 if no error 1 if error
check_mbr proc near
      call read_hdd_sector
      cmp ah, 0
      jne check_mbr_give_error
      cmp word ptr sec_buf [MBR_SIGN], 0aa55h
      jne check_mbr_give_error
      jmp check_mbr_end_func
check_mbr_give_error:
      lea si, fix_mbr_que
      call print_str
      call getche
      cmp al, 'n'
      jne check_mbr_con_0
      mov ah, 1
      jmp check_mbr_end_func
check_mbr_con_0:
      cmp al, 'y'
      jne check_mbr_give_error
      mov word ptr sec_buf [MBR_SIGN], 0aa55h
      call put_boot_strap
      call write_hdd_sector
      xor ah, ah
check_mbr_end_func:
      ret
check_mbr endp

make_bootable_first_part proc near
      call read_hdd_sector
      cmp ah, 0
      jne mbfp_give_error
      call put_boot_strap
      mov byte ptr sec_buf [PARTITION_1][PART_BOOT_FLAG], 80h
      call write_hdd_sector
      cmp ah, 0
      jne mbfp_give_error
      jmp mbfp_end_func
mbfp_give_error:
      call new_line
      lea si, hdd_err
      call print_str
      call getch              
mbfp_end_func:
      ret             
make_bootable_first_part endp

_main proc near
      call check_mbr
      cmp ah, 1
      je _main_give_error
      call print_name_of_part_man
      jmp _main_end_func
_main_give_error:
      call new_line
      lea si, hdd_err
      call print_str
      call getch
_main_end_func:
      ret
_main endp

;TIP: 7600 = 7C00 - 600
org 7000h
      DAP_Packet: db 16 dup (?)
      _buf: db 512 dup (?)
org 7C00h
jmp bs_prog_entry
nop
      _hdd_err: db "H.D.D error(It may be partition table error or none bootable partition)!", 0
      _prs_key: db 0ah, 0dh, "Press any key...", 0
bs_prog_entry:
      mov ax, cs

      cli
      mov ss, ax
      mov sp, 7C00h
      push ax
      push ax
      pop ds
      pop es
      sti
          
      cld
      mov cx, 100h
      mov si, 7C00h
      mov di, 600h
      rep movsw
      
      mov ax, continue_here
      sub ax, 7600h
      jmp ax
    
continue_here:
      
            
      xor edx, edx
      mov di, _buf
      call _read_hdd_sector
      cmp ah, 0
      jne bs_hdd_read_error    
      
      cmp word ptr [_buf][MBR_SIGN], 0aa55h ;MBR Checked
      jne bs_hdd_read_error
      
      cmp dword ptr [_buf][PARTITION_1][PART_BOOT_FLAG], 80h
      jne bs_hdd_read_error
      
      mov edx, dword ptr [_buf][PARTITION_1][PART_LBA_BEGIN]
      mov di, 7C00h
      call _read_hdd_sector
      cmp ah, 0
      jne bs_hdd_read_error
      xor ax, ax
      push ax
      mov ax, 7C00h;600h
      push ax
      
      ;root dir end calcs
      mov eax, dword ptr [_buf][PARTITION_1][PART_LEN]
      dec eax
      mov esi, eax
      xor edx, edx
      mov ebx, 128
      div ebx
      ;inc eax Convert zero to one
      ;inc eax Sector 0 is reserved
      add eax, 2
      mov ebp, eax
      ;ebp = c_fe_sp
      add ebp, dword ptr [_buf][PARTITION_1][PART_LBA_BEGIN]
      mov eax, esi
      xor edx, edx
      mov ebx, 8
      div ebx
      mov esi, eax
      add esi, ebp
      add esi, 2
      retf
      
      nop
      
;sector number = edx
;transfer buffer = ds:di
;ah = 0 if no error, 1 if error
_read_hdd_sector proc near
      push si
      push edx
      mov si, DAP_Packet
      mov byte ptr [si][DAP_PACKET_SIZE], 16
      mov word ptr [si][DAP_SECTORS_COUNT], 1
      mov word ptr [si][DAP_OFFSET_ADDR], di
      mov word ptr [si][DAP_SEGMENT_ADDR], ds
      mov dword ptr [si][DAP_SECTOR_NUMBER], edx
      mov dword ptr [si][DAP_SECTOR_NUM_P2], 0
      mov ah, 42h
      mov dl, 80h
      int 13h
      jc _read_hdd_sector_give_error
      xor ah, ah
      jmp _read_hdd_sector_end_func
_read_hdd_sector_give_error:
      mov ah, 1
_read_hdd_sector_end_func:
      pop edx
      pop si
      ret          
_read_hdd_sector endp

;al = got ch
_getch proc near
      xor ah, ah
      int 16h
      ret
_getch endp

;address of string = ds:si
_print_str proc near
      push ax
      push bx
      push si
      cld
_print_ch:
      lodsb
      cmp al, 0
      je _exit_print_str_func
      mov ah, 0eh
      mov bx, 7
      int 10h
      jmp _print_ch
_exit_print_str_func:          
      pop si
      pop bx
      pop ax
      ret
_print_str endp

bs_hdd_read_error:
      mov si, _hdd_err
      sub si, 7600h
      call _print_str
      mov si, _prs_key
      sub si, 7600h
      call _print_str
      call _getch

end prog_entry