;HD-FORM
.model small
.586
.code

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
;;;;;;;;;;;;;;;;;;;;;;;;;;

org 100h
prog_entry:
jmp start_point
nop
      hd_form_welcome db 0ah, 0dh, "Hard Disk Format v1.0 (written by Ali Ghanbari).", 0
      mbr_err_0 db 0ah, 0dh, "Invalid Master Boot Record;", 0
      no_part_err_0 db 0ah, 0dh, "No partitions defined;", 0
      hdd_read_err_0 db 0ah , 0dh, "H.D.D I/O error;", 0
      sec_buf db 512 dup (?)
      part0_msg db 0ah, 0dh, "     0 = (root)", 0
      part1_msg db 0ah, 0dh, "     1 = (dat0)", 0
      part2_msg db 0ah, 0dh, "     2 = (dat1)", 0
      part3_msg db 0ah, 0dh, "     3 = (dat2)", 0
      select_msg db 0ah, 0dh, "Select a partition to format it: ", 0
      active_partition db ?
      mbr_sect: db 512 dup (?)
      buf0: db 514 dup (?)
      formatting_msg db 0ah, 0dh, "Formatting...", 0 
      
start_point:
call _main
retf
nop

;partition number = bl (0 to read absolute, 1 = part1, 2 = part2, etc.)
;sector number = edx
;number of sectors that must be read = cx
;transfer buffer address = ds:di
;ah = 0 if no error, 1 if error
read_hdd_sector proc near
      push si
      push ebx
      push cx
      push edx
      cmp bl, 0
      je read_hdd_sector_abs
      cmp bl, 1
      jne read_hdd_sector_next_bl_test_1
      cmp byte ptr cs:[mbr_sect][PARTITION_1][PART_TYPE_CODE], 1
      jne read_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_1][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_1][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_1][PART_LEN]
      cmp edx, ebx
      jg read_hdd_sector_give_error
      jmp read_hdd_sector_abs
read_hdd_sector_next_bl_test_1:
      
      cmp bl, 2
      jne read_hdd_sector_next_bl_test_2
      cmp byte ptr cs:[mbr_sect][PARTITION_2][PART_TYPE_CODE], 1
      jne read_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_2][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_2][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_2][PART_LEN]
      cmp edx, ebx
      jg read_hdd_sector_give_error
      jmp read_hdd_sector_abs
read_hdd_sector_next_bl_test_2:
      
      cmp bl, 3
      jne read_hdd_sector_next_bl_test_3
      cmp byte ptr cs:[mbr_sect][PARTITION_3][PART_TYPE_CODE], 1
      jne read_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_3][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_3][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_3][PART_LEN]
      cmp edx, ebx
      jg read_hdd_sector_give_error
      jmp read_hdd_sector_abs
read_hdd_sector_next_bl_test_3:
      
      cmp bl, 4
      jne read_hdd_sector_give_error
      cmp byte ptr cs:[mbr_sect][PARTITION_4][PART_TYPE_CODE], 1
      jne read_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_4][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_4][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_4][PART_LEN]
      cmp edx, ebx
      jg read_hdd_sector_give_error
read_hdd_sector_abs:
      
      mov si, DAP_Packet
      mov byte ptr cs:[si][DAP_PACKET_SIZE], 16
      mov word ptr cs:[si][DAP_SECTORS_COUNT], cx
      mov word ptr cs:[si][DAP_OFFSET_ADDR], di
      mov word ptr cs:[si][DAP_SEGMENT_ADDR], ds
      mov dword ptr cs:[si][DAP_SECTOR_NUMBER], edx
      mov dword ptr cs:[si][DAP_SECTOR_NUM_P2], 0
      mov ah, 42h
      mov dl, 80h
      
      ;setting ds
      push ds
      push cs
      pop ds
      int 13h
      pop ds
      ;;;;;;;;;;;
      
      jc read_hdd_sector_give_error
      xor ah, ah
      jmp read_hdd_sector_end_func
read_hdd_sector_give_error:
      
      mov ah, 1
read_hdd_sector_end_func:
      
      pop edx
      pop cx
      pop ebx
      pop si
      ret          
read_hdd_sector endp

;partition number = bl (0 to write absolute, 1 = part1, 2 = part2, etc.)
;sector number = edx
;number of sectors that must be written = cx
;source buffer = ds:di
;ah = 0 if no error, 1 if error
write_hdd_sector proc near
      push si
      push ebx
      push cx
      push edx
      cmp bl, 0
      je write_hdd_sector_abs
      cmp bl, 1
      jne write_hdd_sector_next_bl_test_1
      cmp byte ptr cs:[mbr_sect][PARTITION_1][PART_TYPE_CODE], 1
      jne write_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_1][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_1][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_1][PART_LEN]
      cmp edx, ebx
      jg write_hdd_sector_give_error
      jmp write_hdd_sector_abs
write_hdd_sector_next_bl_test_1:
      
      cmp bl, 2
      jne write_hdd_sector_next_bl_test_2
      cmp byte ptr cs:[mbr_sect][PARTITION_2][PART_TYPE_CODE], 1
      jne write_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_2][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_2][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_2][PART_LEN]
      cmp edx, ebx
      jg write_hdd_sector_give_error
      jmp write_hdd_sector_abs
write_hdd_sector_next_bl_test_2:
      
      cmp bl, 3
      jne write_hdd_sector_next_bl_test_3
      cmp byte ptr cs:[mbr_sect][PARTITION_3][PART_TYPE_CODE], 1
      jne write_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_3][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_3][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_3][PART_LEN]
      cmp edx, ebx
      jg write_hdd_sector_give_error
      jmp write_hdd_sector_abs
write_hdd_sector_next_bl_test_3:
      
      cmp bl, 4
      jne write_hdd_sector_give_error
      cmp byte ptr cs:[mbr_sect][PARTITION_4][PART_TYPE_CODE], 1
      jne write_hdd_sector_give_error
      add edx, dword ptr cs:[mbr_sect][PARTITION_4][PART_LBA_BEGIN]
      mov ebx, dword ptr cs:[mbr_sect][PARTITION_4][PART_LBA_BEGIN]
      add ebx, dword ptr cs:[mbr_sect][PARTITION_4][PART_LEN]
      cmp edx, ebx
      jg write_hdd_sector_give_error
write_hdd_sector_abs:
      
      mov si, DAP_Packet
      mov byte ptr cs:[si][DAP_PACKET_SIZE], 16
      mov word ptr cs:[si][DAP_SECTORS_COUNT], cx
      mov word ptr cs:[si][DAP_OFFSET_ADDR], di
      mov word ptr cs:[si][DAP_SEGMENT_ADDR], ds
      mov dword ptr cs:[si][DAP_SECTOR_NUMBER], edx
      mov dword ptr cs:[si][DAP_SECTOR_NUM_P2], 0
      mov ah, 43h
      xor al, al ;write with out verify!
      mov dl, 80h
      
      ;setting ds
      push ds
      push cs
      pop ds
      int 13h
      pop ds
      ;;;;;;;;;;;
      jc write_hdd_sector_give_error 
      jmp write_hdd_sector_end_func
write_hdd_sector_give_error:
      
      mov ah, 1
write_hdd_sector_end_func:
     
      pop edx
      pop cx
      pop ebx
      pop si
      ret          
write_hdd_sector endp

;no param
;ah = status 0 if no error 1 if error
check_mbr proc near
      push bx
      push cx
      push edx
      push di
      xor bl, bl ;read absolute sector
      xor edx, edx
      mov cx, 1
      mov di, mbr_sect
      call read_hdd_sector     
      cmp ah, 0
      jne check_mbr_give_error
      cmp word ptr cs:[mbr_sect][MBR_SIGN], 0aa55h
      jne check_mbr_give_error
      jmp check_mbr_end_func
check_mbr_give_error:
      
      mov ah, 1
check_mbr_end_func:
      
      pop di
      pop edx
      pop cx
      pop bx
      ret
check_mbr endp

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

;ah = 0 if h.d.d is empty, ah = 20 if h.d.d is full; ah is undefined part num 
;esi is availible entry point
check_hdd_partitions proc near
      cmp byte ptr sec_buf [PARTITION_1][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_p2
      xor ah, ah
      mov esi, 63
      ret 
chk_p2:
      lea si, part0_msg
      call print_str
      cmp byte ptr sec_buf [PARTITION_2][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_p3
      mov ah, 2
      mov esi, dword ptr sec_buf [PARTITION_1][PART_LBA_BEGIN]
      add esi, dword ptr sec_buf [PARTITION_1][PART_LEN]  
      ret 
chk_p3:
      lea si, part1_msg
      call print_str
      cmp byte ptr sec_buf [PARTITION_3][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_p4
      mov ah, 3
      mov esi, dword ptr sec_buf [PARTITION_2][PART_LBA_BEGIN]
      add esi, dword ptr sec_buf [PARTITION_2][PART_LEN]  
      ret
chk_p4:
      lea si, part2_msg
      call print_str
      cmp byte ptr sec_buf [PARTITION_4][PART_TYPE_CODE], PART_TYPE_UNDEFINED
      jne chk_hdd_end_func
      mov ah, 4
      mov esi, dword ptr sec_buf [PARTITION_3][PART_LBA_BEGIN]
      add esi, dword ptr sec_buf [PARTITION_3][PART_LEN]  
      ret
chk_hdd_end_func:
      lea si, part3_msg
      call print_str
      mov ah, 20
      ret
check_hdd_partitions endp

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
      mov di, buf0
      mov cx, 100h
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

_main proc near
      lea si, hd_form_welcome
      call print_str
      
      call check_mbr
      cmp ah, 1
      je _mbr_give_err
      
      xor bl, bl
      xor edx, edx
      mov cx, 1
      lea di, sec_buf
      call read_hdd_sector
      cmp ah, 0
      jne _hdd_io_give_err
            
      call check_hdd_partitions
      cmp ah, 0
      je _no_part_give_err
      
      lea si, select_msg
      call print_str
      
      call getche
      mov active_partition, al
      sub active_partition, 2Fh  ; = 30h - 1, 30h = 0(ch) -> 31h - 30h = 1h
      
      call new_line
         
      cmp active_partition, 1
      jne _main_part_not_act
      call put_boot_strap
      mov bl, active_partition
      xor edx, edx
      mov di, buf0
      mov cx, 1
      call write_hdd_sector
      cmp ah, 0
      jne _hdd_io_give_err
_main_part_not_act:      
      lea si, formatting_msg
      call print_str
      
      mov di, buf0
      mov cx, 512
      call fill_array_with_zero
      
      mov al, active_partition
      cmp al, 1
      jne _main_next_al_1
      mov ecx, dword ptr [mbr_sect][PARTITION_1][PART_LEN]
      jmp _main_con_0
_main_next_al_1:
      cmp al, 2
      jne _main_next_al_2
      mov ecx, dword ptr [mbr_sect][PARTITION_2][PART_LEN]
      jmp _main_con_0
_main_next_al_2:
      cmp al, 3
      jne _main_next_al_3
      mov ecx, dword ptr [mbr_sect][PARTITION_3][PART_LEN]
      jmp _main_con_0
_main_next_al_3:
      cmp al, 4
      jne _main_end_func
      mov ecx, dword ptr [mbr_sect][PARTITION_4][PART_LEN]
_main_con_0:
      mov edx, 1
_main_l_0:

      mov bl, active_partition
      mov di, buf0
      push cx
      mov cx, 1
      call write_hdd_sector
      pop cx 
      cmp ah, 0
      jne _hdd_io_give_err
      inc edx
      loop _main_l_0
      jmp _main_end_func
_mbr_give_err:
      lea si, mbr_err_0
      call print_str
      jmp _main_end_func
_no_part_give_err:
      lea si, no_part_err_0
      call print_str
      jmp _main_end_func
_hdd_io_give_err:
      lea si, hdd_read_err_0
      call print_str
      jmp _main_end_func      
_main_end_func: 
      call new_line
      ret
_main endp

org 7000h
    DAP_Packet: db 16 dup (?)
org 7C00h
_prog_entry:
jmp _start_point
nop
    ;msg's:
    wait_msg db 0ah, 0dh, "Please wait...", 0ah, 0dh, 0       
    err_msg1 db 0ah, 0dh, "An error detected during loading...", 0ah, 0dh,
                          "Press any key...", 0
    DISK_LABEL db "NO NAME             ", 0
    SYS_NAME db "CCS-OS", 0
    SYS_VER db 0ah
_start_point:
call __main
ret
nop

;al = got ch
_getch proc near 
    xor ah, ah
    int 16h
    ret
_getch endp

;address of string = ds:si
_print_str proc near
    pushf
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
    popf          
    ret
_print_str endp

;sector number = edx
;sectors count = cx
;transfer buffer = ds:di
;ah = 0 if no error, 1 if error
_read_hdd_sector proc near
    push si
    push edx
    mov si, DAP_Packet
    mov byte ptr [si][DAP_PACKET_SIZE], 16
    mov word ptr [si][DAP_SECTORS_COUNT], cx
    mov word ptr [si][DAP_OFFSET_ADDR], di
    mov word ptr [si][DAP_SEGMENT_ADDR], ds
    mov dword ptr [si][DAP_SECTOR_NUMBER], edx
    mov dword ptr [si][DAP_SECTOR_NUM_P2], 0
    push ds
    push cs
    pop ds
    mov ah, 42h
    mov dl, 80h
    int 13h
    pop ds
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

__main proc near
       
    mov ax, cs
    mov ds, ax
    mov es, ax
    cli
    mov ss, ax
    mov sp, 0ffeeh
    sti         
          
    lea si, wait_msg
    call _print_str
                          
    mov ax, 2000h
    ;mov es, di
    mov di, 100h
    
    mov edx, 1
    mov cx, 1;10
    push ds
    ;push es
    ;pop ds
    mov ds, ax
    call _read_hdd_sector
    pop ds
    cmp ah, 0
    jne _bt_st_give_error
          
;_bt_st_read_file:
;    call _getch
    ;mov si, fh
    ;call readfile
;    add bx, 512
    ;cmp ah, 2
    ;je _bt_st_give_error          
    ;cmp ah, 0ffh
    ;je _bt_st_give_error ;_bt_st_read_file
    
    mov ax, 2000h
    mov ds, ax
    mov si, 100h
    ;call _print_str
    lodsb
    mov ah, 0eh
    mov bx, 7
    int 10h
    call _getch      
    ;db 0eah
    ;dw 0100h  ;ea00010008
    ;dw 1000h
                 
_bt_st_give_error:       
    lea si, err_msg1
    call _print_str
    call _getch
    int 19h
_end_bt_st:                  
    ret
    org 7dfeh
    db 55h, 0aah
__main endp

end prog_entry