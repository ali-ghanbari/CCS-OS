;INTS.asm
;BEFORE CALLING MOST OF FUNCTIONS WE MUST SET ACTIVE PATITION VALUE
.model tiny
.586
NORMAL              equ 0
READONLY            equ 1
HIDDEN              equ 2
FOLDER              equ 4
V_FOLDER            equ 8 ;not supported by CCS 10 
DELETED             equ 10h
PROTECTED           equ 20h
IS_FILE             equ 0f1h
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
;;;;;;;;;;;;;;;;;;;;;;;;;;    
.code
org 100h
_file_entry:
jmp code_starting
      DAP_Packet: db 16 dup (?)
      mbr_sect: db 512 dup (?)
      active_partition: db ?
      current_file_entry_sec_ptr: dw 2 dup (?) ;double word
      current_file_entry_ptr: dw ?
      dsm: dw 2 dup (?) ;double word
      root_dir_end: dw 2 dup (?) ;double word
      file_entry_sec: db 512 dup (?)
      file_pt_table: db 512 dup (?)
      file_entry: db 66 dup (?)
      st_pt1: dw ? ;for listing
      st_pt2: dw ? ;for pathing
      
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
                     db "Info : If you say NO CCS-OS will cancel delete operation and user interface will "
                     db "show an error; that is not important.", 0ah, 0dh 
                     db "One of entries is read only, do you want continue [y/n] ? ", 0
      mbr_error_msg: db 0ah, 0dh, "An error detected : H.D.D MBR is not okay; Retry to partitioning will fix this problem.", 0
      hdd_been_unknown: db 0ah, 0dh, "WARNING : THE H.D.D BEEN UNKNOWN BY DETECTED ERROR!", 0ah, 0dh, 0
      prs_any_key_msg: db 0ah, 0dh, "Press any key to continue...", 0
      hdd_not_supported: db 0ah, 0dh, "fatal error 0 : This H.D.D is unsupported by CCS-OS 10;",0ah, 0dh,
                        "Because this H.D.D doesn't support BIOS extensions.", 0
      hdd_supported_msg: db 0ah, 0dh, "H.D.D is supported by CCS-OS and ready to use.", 0
      welcome_msg: db 0ah, 0dh, "CCS-OS 10 H.D.D I/O Interrupt Services", 0ah, 0dh
                   db "Copyright (C) 2005-2006 Ali Ghanbari.", 0
      install_int21h_msg: db 0ah, 0dh, "Configuring service #21h at (0x0000:0x0084)...", 0
      
      root_dir: db "(root)", 0
      viewing_msg: db 0ah, 0dh, "Viewing directory '", 0
      view_msg_0: db "' inside:", 0ah, 0dh, 0
      hidden_msg: db 0ah, 0dh, "[HIDDEN]", 0
         
      dir_err: db 0ah, 0dh, "An error detected;", 0
    
      pass_msg_0: db "  ][", 0
      pass_msg_1: db "  []", 0
                        
      
      b0: db ?
      b1: db ?
      b2: db ?
      b3: db ?
      b4: db ?
      b5: db ?
      b6: db ?
      b7: db ?
      
      dw0: dw ?
          dw ?
      dw1: dw ?
          dw ?
      dw2: dw ?
          dw ?
      dw3: dw ?
          dw ?
      dw4: dw ?
          dw ?
      dw5: dw ?
          dw ?
      dw6: dw ?
          dw ?
      dw7: dw ?
          dw ?
   
      fn0: db 44 dup (?)
      fn1: db 44 dup (?)
      fn2: db 44 dup (?)
      eop0: db 5 dup (?)
      eop1: db 5 dup (?)
      eop2: db 5 dup (?)
      eop3: db 5 dup (?)
      fp: db 102 dup (?)
      fdate0: db 9 dup (?)
      buf0: db 514 dup (?)
      st_val: dw 6 dup (?)
      ;ATTENTION st_val must be valued follow this model:
      ;0 - 3 : c_fe_sp (dword)
      ;4 - 5 : c_fe_p (word)
      ;6 - 10 : dsm_n (dword)
      st_dat1: dw 512 dup (?) ;for listing
      st_dat2: dw 512 dup (?) ;for pathing
      
      _ip_val: dw ?
      _cs_val: dw ?
      _sp_val: dw ?
      _flags: dw ?
      
code_starting:

call _main ;jump to main func
retf ;exit hdd(sse)

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
      xor ah, ah
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
      
      ;setting ds
      push ds
      push cs
      pop ds
      call read_hdd_sector
      pop ds
      ;;;;;;;;;;;
      
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

;no param
;ah = status 1 if this h.d.d supports BIOS extentions, 0 if BIOS extentions are not supported
check_extentions proc near
      push bx
      push dx
      mov ah, 41h
      mov bx, 55aah
      mov dl, 80h                                                                               
      int 13h
      jc check_extentions_give_error
      mov ah, 1
      jmp check_extentions_end_func
check_extentions_give_error:
      
      xor ah, ah
check_extentions_end_func:
      
      pop dx
      pop bx
      ret
check_extentions endp

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

;32-bit number = eax
disp_num proc near
      push eax
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
      pop eax
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
new_line proc near
      push ax
      mov al, 0ah
      call put_char
      mov al, 0dh
      call put_char
      pop ax
      ret
new_line endp

;no param (active partition must be set)
;eax = active partition's size, 0 if error
get_active_partition_size proc near
      cmp byte ptr cs:[active_partition], 0
      je get_act_part_size_give_error
get_act_part_size_next_1:
      cmp byte ptr cs:[active_partition], 1
      jne get_act_part_size_next_2
      cmp byte ptr cs:[mbr_sect][PARTITION_1][PART_TYPE_CODE], 1
      jne get_act_part_size_give_error
      mov eax, dword ptr cs:[mbr_sect][PARTITION_1][PART_LEN]
      jmp get_act_part_size_end_func
get_act_part_size_next_2:
      cmp byte ptr cs:[active_partition], 2
      jne get_act_part_size_next_3
      cmp byte ptr cs:[mbr_sect][PARTITION_2][PART_TYPE_CODE], 1
      jne get_act_part_size_give_error
      mov eax, dword ptr cs:[mbr_sect][PARTITION_2][PART_LEN]
      jmp get_act_part_size_end_func
get_act_part_size_next_3:
      cmp byte ptr cs:[active_partition], 3
      jne get_act_part_size_next_4
      cmp byte ptr cs:[mbr_sect][PARTITION_3][PART_TYPE_CODE], 1
      jne get_act_part_size_give_error
      mov eax, dword ptr cs:[mbr_sect][PARTITION_3][PART_LEN]
      jmp get_act_part_size_end_func
get_act_part_size_next_4:
      cmp byte ptr cs:[active_partition], 4
      jne get_act_part_size_give_error
      cmp byte ptr cs:[mbr_sect][PARTITION_4][PART_TYPE_CODE], 1
      jne get_act_part_size_give_error
      mov eax, dword ptr cs:[mbr_sect][PARTITION_4][PART_LEN]
      jmp get_act_part_size_end_func
get_act_part_size_give_error:
      xor eax, eax
get_act_part_size_end_func:
      ret                     
get_active_partition_size endp

;no param (active_partition must be set)
;current_file_entry_sec_ptr =  FFFFFFFF if error
make_cfe_sp_def proc near
      push eax
      push ebx
      push edx
      ;active_partition is set
      call get_active_partition_size
      cmp eax, 0
      je make_cfe_sp_def_give_error 
      ;eax is set
      dec eax
      xor edx, edx
      mov ebx, 128
      div ebx
      ;inc eax Convert zero to one
      ;inc eax Sector 0 is reserved
      add eax, 2
      mov dword ptr cs:[current_file_entry_sec_ptr], eax
      jmp make_cfe_sp_def_end_func
make_cfe_sp_def_give_error:
      mov dword ptr cs:[current_file_entry_sec_ptr], 0ffffffffh
make_cfe_sp_def_end_func: 
      pop edx
      pop ebx
      pop eax
      ret
make_cfe_sp_def endp 

;no param
make_cfe_p_def proc near
      mov word ptr cs:[current_file_entry_ptr], 512
      ret         
make_cfe_p_def endp

;no param
make_dsm_def proc near
      mov dword ptr cs:[dsm], 0ffffeeeeh
      ret
make_dsm_def endp

;no param (active_partition must be set)
make_def_fids proc near
      push eax
      push ebx
      push edx
      call make_cfe_sp_def
      cmp dword ptr cs:[current_file_entry_sec_ptr], 0ffffffffh
      je make_def_fids_give_error
      call make_cfe_p_def
      call make_dsm_def
      call get_active_partition_size
      ;eax is set
      dec eax
      xor edx, edx
      mov ebx, 8
      div ebx
      inc eax
      mov dword ptr cs:[root_dir_end], eax
      mov eax, dword ptr cs:[current_file_entry_sec_ptr]
      add dword ptr cs:[root_dir_end], eax
      inc dword ptr cs:[root_dir_end]
      jmp make_def_fids_end_func
make_def_fids_give_error:
      mov dword ptr cs:[dsm], 0ffffffffh                   
      mov dword ptr cs:[root_dir_end], 0ffffffffh
      mov word ptr cs:[current_file_entry_ptr], 0ffffh
make_def_fids_end_func:
      pop edx
      pop ebx
      pop eax 
      ret
make_def_fids endp

;index = esi
;edi = new index
;edx = sector
convert_hdd_fptt_index2sec proc near
      push eax
      push ebx
      push ecx
      
      mov eax, esi
      dec eax
      xor edx, edx
      mov ecx, 128
      div ecx
      mov ebx, eax
      mov ecx, 128
      mul ecx
      mov edi, esi
      sub edi, eax
      mov edx, ebx
      inc edx
      
      pop ecx
      pop ebx
      pop eax
      ret 
convert_hdd_fptt_index2sec endp

;no param
;ah = 0 file got, 1 if error and 2 if EOFE
get_file_entry proc near
      push ecx
      push edx
      push esi
      push edi 
      pushf
      cmp word ptr cs:[current_file_entry_ptr], 512
      jne get_file_entry_cfe_p_ne_512
      cmp dword ptr cs:[dsm], 0ffffeeeeh
      jne get_file_entry_dsm_ne_ffffeeee
      
      ;setting ds
      push ds
      push cx
      push bx
      
      push cs
      pop ds
      mov edx, dword ptr cs:[current_file_entry_sec_ptr]
      mov di, file_entry_sec
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
      call read_hdd_sector
      
      pop bx
      pop cx
      pop ds
      ;;;;;;;;;;;
      cmp ah, 0
      jne get_file_entry_give_error
      mov word ptr cs:[current_file_entry_ptr], 0
      inc dword ptr cs:[current_file_entry_sec_ptr]
      jmp get_file_entry_cfe_p_ne_512
get_file_entry_dsm_ne_ffffeeee:
      mov edx, dword ptr cs:[dsm]
      add edx, dword ptr cs:[root_dir_end]
      ;setting ds
      push ds
      push cx
      push bx
      
      push cs
      pop ds
      
      mov di, file_entry_sec
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
      call read_hdd_sector
      
      pop bx
      pop cx
      pop ds
      ;;;;;;;;;;;
      cmp ah, 0
      jne get_file_entry_give_error
      mov word ptr cs:[current_file_entry_ptr], 0
      mov esi, dword ptr cs:[dsm]
      call convert_hdd_fptt_index2sec
      ;edx and edi are set
      push edi
      ;setting ds
      push ds
      push cx
      push bx
      
      push cs
      pop ds
      
      mov di, file_pt_table
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
      call read_hdd_sector
      
      pop bx
      pop cx
      pop ds
      ;;;;;;;;;;;
      pop edi
      cmp ah, 0
      jne get_file_entry_give_error
      dec edi
      mov eax, 4
      mul edi
      mov edi, eax
      push dword ptr cs:[file_pt_table][edi]
      pop dword ptr cs:[dsm]
get_file_entry_cfe_p_ne_512:
      mov di, word ptr cs:[current_file_entry_ptr]
      cmp byte ptr cs:[file_entry_sec][di], 0
      jne get_file_entry_is_not_eofe
      mov ah, 2
      jmp get_file_entry_end_func
get_file_entry_is_not_eofe:
      cld
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov si, file_entry_sec
      add si, word ptr cs:[current_file_entry_ptr]
      mov di, file_entry
      mov cx, 16
      rep movsd
      pop es
      pop ds
      add word ptr cs:[current_file_entry_ptr], 64
      xor ah, ah
      jmp get_file_entry_end_func
get_file_entry_give_error:
      mov ah, 1
get_file_entry_end_func:
      popf                  
      pop edi 
      pop esi
      pop edx
      pop ecx
      ret
get_file_entry endp

;no param
;es:di file name
get_file_name proc near
      push cx
      push si
      push di
      push ds
      pushf
      
      push cs
      pop ds
      cld
      mov si, file_entry
      ;es, di are set
      mov cx, 41
      rep movsb
      
      popf
      pop ds 
      pop di
      pop si
      pop cx
      ret
get_file_name endp

;no param
;es:di = des buf address
;ah = 0 entry(file/folder) has password, 1 if entry has not password 
get_file_password proc near
      push cx
      push si
      push di
      push ds
      pushf
      
      push cs
      pop ds
      call get_file_attr
      and al, PROTECTED
      cmp al, PROTECTED
      jne get_file_password_file_has_not_password_1
      mov si, file_entry
      add si, 41
      ;es, di are set
      mov al, byte ptr cs:[si]
      cmp al, 0
      je get_file_password_file_has_not_password_1
      cmp al, 0abh
      je get_file_password_file_has_not_password_1
      mov cx, 3
      cld
passwording:
      lodsb
      cmp al, 0
      je exit_passwording  
      xor al, 0abh ;password secret
      mov byte ptr es:[di], al
      inc di
      loop passwording
exit_passwording:
      mov byte ptr es:[di], 0
      xor ah, ah
      jmp get_file_password_end_func
get_file_password_file_has_not_password_1:
      mov ah, 1 
                                    
get_file_password_end_func: 
      popf
      pop ds
      pop di
      pop si
      pop cx
      ret        
get_file_password endp 

;no param
;es:di = des buf address
get_file_ext proc near
      push cx
      push si
      push di
      push ds
      pushf
      
      push cs
      pop ds
      cld
      mov si, file_entry
      add si, 44
      mov cx, 3
      rep movsb
      
      popf
      pop ds
      pop di
      pop si
      pop cx
      ret   
get_file_ext endp

;no param
;al = attrs
get_file_attr proc near
      mov al, byte ptr cs:[file_entry][47]
      ret
get_file_attr endp 

;no param
;es:di = fdate
get_file_date proc near
      push ax
      push cx
      push si
      push di
      
      mov si, file_entry
      add si, 48
      mov al, byte ptr cs:[si]
      xor ah, ah
      add ax, 2000
      mov word ptr es:[di], ax
      add di, 2
      inc si
      mov cx, 5
get_file_date_ring:
      mov al, byte ptr cs:[si]
      mov byte ptr es:[di], al
      inc si
      inc di
      loop get_file_date_ring
      
      pop di
      pop si
      pop cx
      pop ax
      ret
get_file_date endp  

;no param
;ecx = file size
;dx = next part
get_file_size proc near
      mov ecx, dword ptr cs:[file_entry][54]
      mov dx, word ptr cs:[file_entry][58]
      ret    
get_file_size endp

;no param
;eax = file starting block
get_file_starting_block proc near
      mov eax, dword ptr cs:[file_entry][60]              
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
;cs:[dw3] = f_c
;cs:[dw4] = dsm_n
;cs:[dw5] = st_block
;cs:[b5] = other_attrs
;ah = 1 if error, 0 file is normal and valid, 3 file is valid and protected
;2 folder is normal, 4 folder is protected 
;WARNING ALL DATA IN THESE ARRAY'S WILL BE LOST <<fn0>>, <<fn1>>, <<eop0>>, <<eop1>>
check_path proc near
      push ebx
      push ecx
      push edx
      push esi
      push edi 
      pushf
      ;si and ds are set
      call str_len
      cmp cx, 1
      jl check_path_give_error
      ;active_partition is set
      call make_def_fids
      mov dword ptr cs:[dw4], 0ffffeeeeh
      cld
      ;si and ds are set
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
      cmp di, 41
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
      ;si is incrised and ds is set
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
      cmp byte ptr ds:[si], 0 ;(DS) source
      jne check_path_give_error
      mov word ptr cs:[current_file_entry_ptr], 512
      mov dword ptr cs:[dw3], 1 ;x = 1
      call get_file_entry
      cmp ah, 0
      jne check_path_give_error
      ;we don't need to push si reg into the stack
      ;because here is the final step of this function
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      ;es is set
      mov di, eop1
      call get_file_ext
      pop es
      ;;;;;;;;;;;
      
      call get_file_attr
      ;al is attrs
      ;attrs backups
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      mov byte ptr cs:[b5], al ;other_attrs 
      mov byte ptr cs:[b6], al
check_path_sub_loop_3:
      mov si, fn0
      
      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov di, fn1
      call str_comp
      pop es
      pop ds
      ;;;;;;;;;;;;;;;
      
      cmp ah, 1
      jne check_path_sub_loop_3_invalid_file
check_path_sub_loop_3_ok1:
      mov si, eop0
      
      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov di, eop1
      call str_comp
      pop es
      pop ds
      ;;;;;;;;;;;;;;;
      
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
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      mov di, eop1
      call get_file_ext
      pop es
      ;;;;;;;;;;;
      
      call get_file_attr
      ;al is attrs
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      mov byte ptr cs:[b5], al ;other attrs
      mov byte ptr cs:[b6], al
      inc dword ptr cs:[dw3] ;x ++
      jmp check_path_sub_loop_3
exit_check_path_sub_loop_3:           
      ;cs:[dw3] is set
      ;cs:[b5] is set
      call get_file_starting_block
      ;eax is file starting block
      mov dword ptr cs:[dw5], eax
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
      mov dword ptr cs:[dw3], 1
      call get_file_entry
      cmp ah, 0
      jne check_path_give_error
      ;we don't need to push si reg into the stack
      ;because here is the final step of this function
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      pop es
      ;;;;;;;;;;;
           
      call get_file_attr
      ;al is attrs
      ;attrs backups
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      mov byte ptr cs:[b5], al ;other_attrs 
      mov byte ptr cs:[b6], al
check_path_sub_loop_4:
      mov si, fn0
      
      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov di, fn1
      call str_comp
      pop es
      pop ds
      ;;;;;;;;;;;;;;;      
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
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      pop es
      ;;;;;;;;;;;
      
      call get_file_attr
      ;al is attrs
      ;attrs backups
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      mov byte ptr cs:[b5], al ;other_attrs 
      mov byte ptr cs:[b6], al
      inc dword ptr cs:[dw3] ;x++
      jmp check_path_sub_loop_4 
exit_check_path_sub_loop_4:
      ;cs:[dw3] is set
      ;cs:[b5] is set
      call get_file_starting_block
      ;eax is starting block
      mov dword ptr cs:[dw5], eax
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
      cmp ds:[si], 0 ;source (DS)
      je check_path_give_error
      mov word ptr cs:[current_file_entry_ptr], 512
      call get_file_entry
      cmp ah, 0
      jne check_path_give_error
      ;ATTENTION
      ;WE NEED TO push si into the stack
      ;because here is not final step and there is some folders and sub folders and files after this
      push si
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      pop es
      ;;;;;;;;;;;      
      ;si is set
      call get_file_attr
      ;al is attrs
      ;attrs backups
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      ;we don't need cs:[b5], in this version of CCS 
      mov byte ptr cs:[b6], al
check_path_sub_loop_5:
      mov si, fn0
      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov di, fn1
      call str_comp
      pop es
      pop ds
      ;;;;;;;;;;;;;;;
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
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      pop es
      ;;;;;;;;;;;
      
      call get_file_attr
      ;al is attrs
      ;attrs backups
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      ;we don't need cs:[b5] in this version of CCS 
      mov byte ptr cs:[b6], al
      jmp check_path_sub_loop_5
exit_check_path_sub_loop_5:                 
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
      
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, eop1
      call get_comp_pass
      pop ds
      ;;;;;;;;;;;
      
      mov bh, ah
      ;taking eop0 from stack
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
      call get_file_starting_block
      mov dword ptr cs:[dsm], eax
      mov dword ptr cs:[dw4], eax
      pop si
      jmp check_path_main_loop
check_path_give_error2:
      pop si 
                        
check_path_give_error:
      mov dword ptr cs:[dw3], 0
      mov dword ptr cs:[dw4], 0ffffeeeeh
      mov dword ptr cs:[dw5], 0
      mov byte ptr cs:[b5], 0ffh
      mov ah, 1
      
check_path_end_func:
      popf
      pop edi
      pop esi
      pop edx
      pop ecx
      pop ebx
      ret 
check_path endp

;file path buf addr = ds:si
;file io handle buf addr = es:di
;WARNING ALL DATA IN THESE ARRAY'S WILL BE LOST <<fn0>>, <<fn1>>, <<eop0>>, <<eop1>>
openfile proc near
      push eax
      push si
      push di
      ;si is set
      call check_path
      push ax
      mov eax, dword ptr cs:[dw3]    ;f_c
      mov dword ptr es:[di], eax
      mov eax, dword ptr cs:[dw4]    ;dsm_n
      mov dword ptr es:[di + 4], eax
      mov eax, dword ptr cs:[dw5]    ;st_block
      mov dword ptr es:[di + 8], eax
      mov al, byte ptr cs:[b5]       ;other_attrs
      mov byte ptr es:[di + 12], al
      pop ax
      cmp ah, 0
      je open_file_end_func 
      cmp ah, 1
      je set_invalid_fh 
open_file_ah_test_1:
      push di
      cmp ah, 3
      jne set_invalid_fh
          
      ;setting es
      push es
      push cs
      pop es
        
      mov di, fn1
      call get_file_name
      mov di, eop1
      call get_file_password
      mov di, eop2
      call get_file_ext
          
      pop es
      ;;;;;;;;;;;
          
      pop di
      
      cmp ah, 1
      je open_file_end_func
         
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
      mov si, eop2
      call print_str
      mov al, ')'
      call put_char
      mov si, next_part_of_ss_msg
      call print_str
      mov si, password_msg
      call print_str
      mov si, eop1
      call get_comp_pass
          
      pop ds
      ;;;;;;;;;;;
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
      mov dword ptr es:[di], 0ffffffffh
      mov dword ptr es:[di + 4], 0ffffffffh
      mov dword ptr es:[di + 8], 0ffffffffh
      mov byte ptr es:[di + 12], 0ffh
              
open_file_end_func:
      pop di
      pop si         
      pop eax
      ret
openfile endp 

;file io handle buf addr = ds:si
;buffer addr = es:bx
;ah = 1 if file is empty (des buf will fill by 0xff), 0xff if eof, 0 if no error, 2 if read error 
readfile proc near
      push bx
      push ecx
      push edx
      push si
      push di
      cmp dword ptr es:[si], 0ffffffffh
      je read_file_error
      cmp dword ptr ds:[si + 8], 0
      jne read_file_f_input_nt
      mov cx, 128
read_file_loop:
      mov dword ptr es:[bx], 0ffffffffh
      add bx, 4     
      loop read_file_loop
      mov ah, 1
      jmp read_file_end_func     
read_file_f_input_nt:
      cmp dword ptr ds:[si + 8], 0ffffffffh
      je read_file_is_eof
      mov edx, dword ptr ds:[si + 8]
      add edx, dword ptr cs:[root_dir_end]
      
      ;setting ds
      push ds
      push es
      pop ds
      mov di, bx
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
      call read_hdd_sector
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne read_file_error
      push esi
      mov esi, dword ptr ds:[si + 8]
      call convert_hdd_fptt_index2sec
      pop esi
      ;edx is set
      ;edi is new index
      push edi
      mov di, file_pt_table
      push bx
      
      ;setting ds
      push ds
      push cs
      pop ds
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
      call read_hdd_sector
      pop ds
      ;;;;;;;;;;;
      
      pop bx
      pop edi
      cmp ah, 0
      jne read_file_error
      ;converting double word to byte
      dec edi
      mov eax, 4
      mul edi
      mov edi, eax
      push dword ptr cs:[file_pt_table][edi]
      pop dword ptr ds:[si + 8]
      xor ah, ah 
          
      jmp read_file_end_func
read_file_error:
      mov ah, 2
      jmp read_file_end_func      
read_file_is_eof:
      mov ah, 0ffh       
read_file_end_func:
      pop di
      pop si
      pop edx         
      pop ecx
      pop bx                    
      ret
readfile endp   

;index = esi
;edi = new index
;edx = sector
convert_hdd_dirt_index2sec proc near
      push eax
      push ebx 
      push esi  
      push dword ptr cs:[dw0]
               
      mov eax, 8
      mul esi
      mov esi, eax
      dec eax
      xor edx, edx
      mov ebx, 512
      div ebx
      xor edx, edx
      mov ebx, 8
      div ebx
      mov dword ptr cs:[dw0], eax
      mov ebx, 8
      mul ebx
      push eax
      xor edx, edx
      mov ebx, 8
      mov eax, esi
      div ebx
      xor edx, edx
      mov ebx, 64
      div ebx
      mov edi, eax
      pop eax
      sub edi, eax
      mov edx, dword ptr cs:[dw0]
      
      pop dword ptr cs:[dw0] 
      pop esi           
      pop ebx
      pop eax
      ret             
convert_hdd_dirt_index2sec endp  

;file starting block = eax
;edi = new index
;edx = sector and status: 0xffffffff if error
find_eof proc near
      push eax
      push ebx
      push ecx
      push esi
      mov esi, eax
      call convert_hdd_fptt_index2sec
      ;edi = new index
      ;edx is set
      ;es is set
      push edi
      
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop ds
      ;;;;;;;;;;;
      
      pop edi
      cmp ah, 0
      jne find_eof_give_error
find_eof_main_loop:
      ;convert byte ptr 2 dword ptr
      dec edi
      mov eax, 4
      push edx
      mul edi   
      pop edx
      mov edi, eax 
      mov ecx, dword ptr cs:[file_pt_table][edi] ;ecx = j
      cmp ecx, 0ffffffffh
      je exit_find_eof_main_loop
      push edx
      mov esi, ecx
      call convert_hdd_fptt_index2sec
      mov ecx, edx
      pop edx
      cmp edx, ecx
      je find_eof_main_loop
      mov edx, ecx
      ;es is set
      push edi
      mov di, file_pt_table
      push cx
      
      ;setting ds
      push ds
      push cs
      pop ds
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop ds
      ;;;;;;;;;;;
      
      pop cx
      pop edi
      cmp ah, 0
      jne find_eof_give_error
exit_find_eof_main_loop:
      cmp ecx, 0ffffffffh
      jne find_eof_main_loop
      jmp find_eof_end_func
find_eof_give_error:
      mov edx, 0ffffffffh          
find_eof_end_func:
      pop esi
      pop ecx
      pop ebx
      pop eax
      ret
find_eof endp

;no param
;edi = new index
;edx = sector and status: 0xffffffff is error
find_blank_block proc near
      push eax
      push ebx
      push ecx
      push esi
      push dword ptr cs:[dw0]       
               
      ;active_partition is set
      call get_active_partition_size
      cmp eax, 0
      je find_blank_block_give_error
      dec eax
      mov ebx, 128
      xor edx, edx
      div ebx     
      inc eax
      mov ebx, 128
      mul ebx
          
      mov ecx, eax ;n * 128
      xor edx, edx
      mov ebx, 1 ;i = 1 first block
find_blank_block_main_loop:
      mov esi, ebx
      push edx
      call convert_hdd_fptt_index2sec
      ;edi = new index
      ;edx is set
      dec edi
      mov eax, 4
      push edx
      mul edi
      pop edx
      mov edi, eax
      ;edx is set
      mov dword ptr cs:[dw0], edx
      pop edx
      cmp dword ptr cs:[dw0], edx
      je dw0_is_e2dw1
      mov edx, dword ptr cs:[dw0]
      push edi
      ;edx is set
      
      ;setting ds
      push ds
      push cs
      pop ds
      
      mov di, file_pt_table
      push cx
      push bx
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop bx
      pop cx
      pop ds
      ;;;;;;;;;;;
      
      pop edi
      cmp ah, 0
      jne find_blank_block_give_error
dw0_is_e2dw1:
      cmp dword ptr cs:[file_pt_table][edi], 0
      je find_blank_block_end_func
      inc ebx                           
      loop find_blank_block_main_loop 
      jmp find_blank_block_give_error                     
exit_find_blank_block_main_loop:
      jmp find_blank_block_end_func                      
find_blank_block_give_error:
      mov edx, 0ffffffffh
find_blank_block_end_func:
      pop dword ptr cs:[dw0]
      pop esi
      pop ecx
      pop ebx
      pop eax       
      ret       
find_blank_block endp  

;file io handle addr = ds:si
;next part = dw2
;es:di = buffer addr
;ah = 0 if successful
writefile proc near
      push ebx
      push ecx
      push esi
      push edi
      push edx
      push dword ptr cs:[dw1]
      push dword ptr cs:[dw2]
      push dword ptr cs:[dw3]
      push dword ptr cs:[dw4]
      push dword ptr cs:[dsm]
      push word ptr cs:[current_file_entry_ptr] 
      push dword ptr cs:[current_file_entry_sec_ptr]
      
      cmp dword ptr ds:[si], 0ffffffffh ;checking f_output
      je write_file_give_error
      push si
      push di
      mov ebx, dword ptr ds:[si]
      mov eax, 64
      mul ebx
      mov esi, eax
      call convert_hdd_dirt_index2sec
      mov dword ptr cs:[dw1], edi
      ;edx is set    
      pop di
      pop si
      ;cs:[dw1] = edi = new index
      cmp ds:[si][4], 0ffffeeeeh ;checking f_dsm
      jne write_file_f_dsm_is_not_ffee
      call make_def_fids
      add edx, dword ptr cs:[current_file_entry_sec_ptr]
      jmp write_file_l_1
write_file_f_dsm_is_not_ffee:
      add edx, dword ptr ds:[si][4]
      add edx, dword ptr cs:[root_dir_end]
write_file_l_1:
      ;edx is set     
      ;setting ds
      push ds
      push cs
      pop ds
      
      push di
      mov di, file_entry_sec
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
      call read_hdd_sector
      pop di
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne write_file_give_error
      ;TIP: we don't need to give value to dsm and current_file_entry_sec_ptr because get_file_entry function
      ;doesn't read the disk and remember that we have read the sector.
      mov word ptr cs:[current_file_entry_ptr], 0
      mov ecx, dword ptr cs:[dw1]
write_file_loop_1:
      call get_file_entry
      dec ecx
      cmp ecx, 0        
      jne write_file_loop_1      
      sub word ptr cs:[current_file_entry_ptr], 64
      mov ax, word ptr cs:[current_file_entry_ptr]
      movzx eax, ax
      mov dword ptr cs:[dw1], eax ;j = cs:[dw1] = cs:[current_file_entry_ptr] - 64;
      call get_file_attr
      and al, READONLY
      cmp al, READONLY
      je write_file_give_error
      ;cs:[dw3] = old_s
      push edx
      call get_file_size
      mov dword ptr cs:[dw3], ecx
      pop edx
      inc dword ptr cs:[dw3]
      mov eax, dword ptr cs:[dw3] ;new size
      mov ebx, dword ptr cs:[dw1]
      mov dword ptr cs:[file_entry_sec][ebx][54], eax
      mov eax, dword ptr cs:[dw2] ;next part
      mov word ptr cs:[file_entry_sec][ebx][58], ax
      dec dword ptr cs:[dw3]
      cmp dword ptr cs:[dw3], 0
      jne write_file_old_s_is_not_zero
      inc dword ptr cs:[dw3]
      push edx
      push edi
      call find_blank_block
      mov dword ptr cs:[dw3], edi
      mov dword ptr cs:[dw4], edx
      pop edi
      pop edx
      ;cs:[dw3] blank block's new index
      ;cs:[dw4] blank block's sector
      cmp dword ptr cs:[dw4], 0ffffffffh
      je write_file_give_error    
      push ebx
      push edx
      mov ecx, 4
      xor edx, edx
      mov eax, dword ptr cs:[dw3]
      add eax, 4
      div ecx
      mov ebx, eax
      mov eax, dword ptr cs:[dw4]
      dec eax
      mov ecx, 128
      mul cx
      add eax, ebx
      pop edx
      pop ebx
      mov dword ptr cs:[file_entry_sec][ebx][60], eax
      mov ecx, eax
      ;edx is set
      
      ;setting ds
      push ds
      push cs
      pop ds
      
      push di
      push cx
      mov di, file_entry_sec
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop cx
      pop di
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0 
      jne write_file_give_error
      mov edx, ecx
      add edx, dword ptr cs:[root_dir_end]
      
      ;setting ds
      push ds
      push es
      pop ds
      
      ;di is set
      mov bl, byte ptr cs:[active_partition]
      push cx
      mov cx, 1
      call write_hdd_sector
      pop cx
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne write_file_give_error
      mov edx, dword ptr cs:[dw4]
      
      ;setting ds
      push ds
      push cs
      pop ds
      
      mov di, file_pt_table
      push cx
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop cx
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0 
      jne write_file_give_error
      push edx
      mov ebx, dword ptr cs:[dw4]
      dec ebx
      mov eax, 128
      mul ebx
      mov ebx, ecx
      sub ebx, eax
      dec ebx
      mov eax, 4
      mul ebx
      mov ebx, eax
      pop edx
      mov dword ptr cs:[file_pt_table][ebx], 0ffffffffh
      ;edx is set
      
      ;setting ds
      push ds
      push cs
      pop ds
      
      mov di, file_pt_table
      push cx
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop cx
      pop ds
      ;;;;;;;;;;;
      cmp ah, 0
      jne write_file_give_error
      mov dword ptr ds:[si][8], ecx
      xor ah, ah
      jmp write_file_end_func
write_file_old_s_is_not_zero:   
      ;edx is set    
      
      ;setting ds
      push ds
      push cs
      pop ds
      push di
      mov di, file_entry_sec
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop di
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne write_file_give_error
      call get_file_starting_block
      ;eax is file's starting block
      push edi
      call find_eof
      mov dword ptr cs:[dw1], edi ;cs:[dw1] = edi = new index
      pop edi
      cmp edx, 0ffffffffh
      je write_file_give_error
      ;edx is sector # in eof
      ;cs:[dw1] is new index
      push edi
      push edx
      call find_blank_block
      mov eax, edx
      mov dword ptr cs:[dw4], edi
      pop edx
      pop edi
      ;now eax is sector number (blank block)
      ;and cs:[dw4] is new index (blank block)
      cmp eax, 0ffffffffh
      je write_file_give_error
      push dword ptr cs:[dw4]
      pop dword ptr cs:[dw2]
      ;cs:[dw2] is green blank block
      push edx
      mov dword ptr cs:[dw3], eax
      inc dword ptr cs:[dw4]
      mov eax, dword ptr cs:[dw4]
      add eax, 4
      mov dword ptr cs:[dw4], 4
      xor edx, edx
      div dword ptr cs:[dw4]
      mov dword ptr cs:[dw4], eax
      ;now cs:[dw3] is blank block's sector # & cs:[dw4] is index #
      mov ecx, dword ptr cs:[dw3]
      dec ecx
      mov eax, 128
      mul ecx
      add eax, dword ptr cs:[dw4]
      mov ecx, eax
      pop edx
      ;inc ecx
      ;ecx is user understandable blank block's index #
      ;edx is set
      
      ;setting ds
      push ds
      push cs
      pop ds
      
      push cx
      push di
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop di
      pop cx
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne write_file_give_error
      mov ebx, dword ptr cs:[dw1]
      mov dword ptr cs:[file_pt_table][ebx], ecx
      ;edx is set
      
      ;setting ds
      push ds
      push cs
      pop ds
      push di
      push cx
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop cx
      pop di
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0 
      jne write_file_give_error
      mov edx, dword ptr cs:[dw3]
      
      ;setting ds
      push ds
      push cs
      pop ds
      
      push di
      push cx
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop cx
      pop di
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne write_file_give_error
      push edx
      mov ebx, dword ptr cs:[dw3]
      dec ebx
      mov eax, 128
      mul ebx
      mov ebx, ecx
      sub ebx, eax
      dec ebx
      ;add ebx, 4
      mov eax, 4
      mul ebx
      mov ebx, eax
      pop edx
      mov dword ptr cs:[file_pt_table][ebx], 0ffffffffh
      ;edx is set
      
      ;setting ds
      push ds
      push cs
      pop ds
      
      push di
      push cx
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop cx
      pop di
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne write_file_give_error
      
      mov edx, ecx
      add edx, dword ptr cs:[root_dir_end]
      
      ;setting ds
      push ds
      push es
      pop ds
      ;di is set
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne write_file_give_error 
      xor ah, ah                           
      jmp write_file_end_func
write_file_give_error:
      mov ah, 1
write_file_end_func:
      pop dword ptr cs:[current_file_entry_sec_ptr]
      pop word ptr cs:[current_file_entry_ptr]
      pop dword ptr cs:[dsm]          
      pop dword ptr cs:[dw4]
      pop dword ptr cs:[dw3]            
      pop dword ptr cs:[dw2]
      pop dword ptr cs:[dw1]
      pop edx
      pop edi
      pop esi
      pop ecx
      pop ebx
      ret
writefile endp 

;st_block = cs:[dw2]
;next_block = ecx
;eax = preview block and status if zero error
;WARNING ALL DATA IN ARRAY'S <<file_pt_table>> WILL BE LOST!!!
find_prev_block proc near
      push dword ptr cs:[current_file_entry_sec_ptr]
      push word ptr cs:[current_file_entry_ptr]
      push dword ptr cs:[dsm]
      push dword ptr cs:[dw1]
      push dword ptr cs:[dw2]
      push ebx
      push ecx
      push edx
      push esi
      push edi
      
      mov esi, dword ptr cs:[dw2]
      call convert_hdd_fptt_index2sec
      ;edx is sector #
      ;edi is new index
      ;edx is set
          
      ;setting ds
      push edi
      push ds
      push cx
      push cs
      pop ds
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop cx
      pop ds
      pop edi
      ;;;;;;;;;;;
          
      cmp ah, 0
      jne find_prev_block_give_error
      dec edi
      mov eax, 4
      mul edi
      mov edi, eax
      push dword ptr cs:[file_pt_table][edi]
      pop dword ptr cs:[dw1]
      cmp dword ptr cs:[dw1], ecx
      jne st_b_isnot_e2nb
      mov eax, dword ptr cs:[dw2]
      jmp find_prev_block_end_func
st_b_isnot_e2nb:
find_prev_block_main_loop:
      push edx
      mov esi, dword ptr cs:[dw1]
      call convert_hdd_fptt_index2sec
      mov dword ptr cs:[dw2], edx
      pop edx
      ;cs:[dw2] is sector #
      ;edi is new index  
      cmp edx, dword ptr cs:[dw2]
      je find_prev_block_dw0e2dw2_1
      mov edx, dword ptr cs:[dw2]
          
      ;setting ds
      push edi
      push ds
      push cx
      push cs
      pop ds          
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop cx
      pop ds
      pop edi
      ;;;;;;;;;;;
          
      cmp ah, 0
      jne find_prev_block_give_error
find_prev_block_dw0e2dw2_1:

      dec edi
      mov eax, 4
      mul edi
      mov edi, eax
      push dword ptr cs:[file_pt_table][edi]
      pop dword ptr cs:[dw3]
      cmp dword ptr cs:[dw3], ecx
      jne find_prev_block_dw3_isnot_e2cx
      mov eax, dword ptr cs:[dw1]
      jmp find_prev_block_end_func
find_prev_block_dw3_isnot_e2cx:

      mov esi, dword ptr cs:[dw3]
      call convert_hdd_fptt_index2sec
      ;edi is new index
      ;edx is set
      cmp edx, dword ptr cs:[dw2]
      je find_prev_block_dw0e2dw2_2
      ;edx is set
          
      ;setting ds
      push edi
      push ds
      push cx
      push cs
      pop ds
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop cx
      pop ds
      pop edi
      ;;;;;;;;;;;
          
      cmp ah, 0
      jne find_prev_block_give_error
find_prev_block_dw0e2dw2_2:

      dec edi
      mov eax, 4
      mul edi
      mov edi, eax
      push dword ptr cs:[file_pt_table][edi]
      pop dword ptr cs:[dw1]
      cmp dword ptr cs:[dw1], ecx
      jne find_prev_block_main_loop
      mov eax, dword ptr cs:[dw3]      
      jmp find_prev_block_end_func              
find_prev_block_give_error:
          
      xor ax, ax                 
find_prev_block_end_func:
      pop edi
      pop esi 
      pop edx              
      pop ecx
      pop ebx
      pop dword ptr cs:[dw2]
      pop dword ptr cs:[dw1]
      pop dword ptr cs:[dsm]
      pop word ptr cs:[current_file_entry_ptr]
      pop dword ptr cs:[current_file_entry_sec_ptr]                  
      ret
find_prev_block endp

;path starting addr = ds:si
;cs:[dw1] = dsm_n
;cs:[dw2] = p_f_c
;cs:[dw3] = p_dsm_n
;cs:[b1] = is file ?
;cs:fn2 = fn
;cs:eop2 = fe             
;ah = status 1 if error
;ATTENTION, ALL DATA IN ARRAY'S <<eop0->eop2>> and <<fn0->fn2>> 
file_name_delim proc near
      push ebx
      push ecx
      push ebp
      push esi
      push edi
      
      ;setting es
      push es
      push cs
      pop es
      movzx esi, si
      mov di, eop2
      mov cx, 3
      call fill_array_with_zero
      mov di, eop1
      call fill_array_with_zero
      mov di, fn2
      mov cx, 42
      call fill_array_with_zero
      mov di, fn1
      call fill_array_with_zero
      pop es
      ;;;;;;;;;;;
      
      xor ebx, ebx
      xor ebp, ebp
file_name_delim_loop_1:
      mov dword ptr cs:[dw0], ebx
file_name_delim_loop_2:
      mov al, byte ptr ds:[esi][ebp]
      call is_valid_char
      cmp ah, 1
      jne exit_file_name_delim_loop_2
      mov byte ptr cs:[fp][ebx], al
      inc ebx
      inc ebp
      jmp file_name_delim_loop_2
exit_file_name_delim_loop_2:
      cmp dword ptr cs:[dw0], ebx
      je file_name_delim_give_error
      cmp al, '('
      je file_name_delim_path_ok_1
      cmp al, '.'
      je file_name_delim_path_ok_1
      cmp al, 0
      jne file_name_delim_give_error
file_name_delim_path_ok_1:
      mov byte ptr cs:[fp][ebx], al     
      inc ebx 
      mov byte ptr cs:[fp][ebx], 0      
      inc ebp      
      cmp al, '.' ;or ds:[si][ebp - 1] = al
      je file_name_delim_loop_1
      mov byte ptr cs:[fp][ebp - 1], 0      
      ;mov ebx, ebp
      dec ebx
file_name_delim_loop_3:
      cmp byte ptr cs:[fp][ebx], '.'
      je file_name_delim_sub_dir
      cmp ebx, 0
      je file_name_delim_root_dir
      dec ebx
      jmp file_name_delim_loop_3
file_name_delim_root_dir:
      dec ebp ;we need i - 1
      ;xor ebx, ebx
file_name_delim_loop_4:
      mov al, byte ptr cs:[fp][ebx]
      mov byte ptr cs:[fn2][ebx], al
      inc ebx
      cmp ebx, ebp
      jle file_name_delim_loop_4
      mov di, eop2
      mov cx, 3
      
      ;setting es
      push es
      push cs
      pop es      
      call fill_array_with_zero
      pop es
      ;;;;;;;;;;;
      
      xor ebx, ebx
      cmp byte ptr ds:[esi][ebp], '('
      jne file_name_delim_pathbp_isnot_e2opara_1
      inc ebp
file_name_delim_loop_5:
      mov al, ds:[esi][ebp]
      call is_valid_char
      cmp ah, 1
      jne exit_file_name_delim_loop_5
      mov byte ptr cs:[eop2][ebx], al
      inc ebx
      inc ebp
      cmp ebx, 3
      jg file_name_delim_give_error
      jmp file_name_delim_loop_5
exit_file_name_delim_loop_5:
      cmp ebx, 0
      je file_name_delim_give_error
      cmp al, ')'
      jne file_name_delim_give_error
      mov byte ptr cs:[eop2][ebx], 0
      mov byte ptr cs:[b1], IS_FILE
      jmp file_name_delim_root_dir_final_works
file_name_delim_pathbp_isnot_e2opara_1:
      mov byte ptr cs:[b1], 0ffh
file_name_delim_root_dir_final_works:
      mov byte ptr cs:[fp][0], 0
      mov dword ptr cs:[dw1], 0ffffeeeeh
      jmp file_name_delim_sub_dir_final_works
file_name_delim_sub_dir:
      inc ebx
      dec ebp ;we need i - 1
      mov edi, ebx
file_name_delim_loop_6:
      mov al, byte ptr cs:[fp][edi]
      push edi
      sub edi, ebx
      mov byte ptr cs:[fn2][edi], al
      pop edi
      inc edi
      cmp edi, ebp
      jle file_name_delim_loop_6
      mov byte ptr cs:[fp][ebx - 1], 0
      mov di, eop2
      mov cx, 3
      
      ;setting es
      push es
      push cs
      pop es
      call fill_array_with_zero
      pop es
      ;;;;;;;;;;;
      
      xor ebx, ebx
      cmp byte ptr ds:[esi][ebp], '('
      jne file_name_delim_pathbp_isnot_e2opara_2
      inc ebp
file_name_delim_loop_7:
      mov al, ds:[esi][ebp]
      call is_valid_char
      cmp ah, 1
      jne exit_file_name_delim_loop_7
      mov byte ptr cs:[eop2][ebx], al
      inc ebx
      inc ebp
      cmp ebx, 3
      jg file_name_delim_give_error
      jmp file_name_delim_loop_7
exit_file_name_delim_loop_7:
      cmp ebx, 0
      je file_name_delim_give_error
      cmp byte ptr ds:[esi][ebp], ')'
      jne file_name_delim_give_error
      mov byte ptr cs:[b1], IS_FILE
      jmp file_name_delim_sub_dir_final_works
file_name_delim_pathbp_isnot_e2opara_2:
      mov byte ptr cs:[b1], 0ffh
file_name_delim_sub_dir_final_works:
      xor ah, ah
      cmp byte ptr cs:[fp][0], 0
      je file_name_delim_end_func
      mov si, fp            
      xor bh, bh
      mov bl, byte ptr cs:[b1]
      push ebx
      push ds
      push cs
      pop ds
      call check_path
      pop ds
      pop ebx
      mov byte ptr cs:[b1], bl
      push dword ptr cs:[dw3]; => p_f_c = f_c
      pop dword ptr cs:[dw2] ;
      push dword ptr cs:[dw4]; => p_dsm_n = dsm_n
      pop dword ptr cs:[dw3] ;
      push dword ptr cs:[dw5]; => dsm_n = st_block
      pop dword ptr cs:[dw1] ; 
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
      
      push eax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;setting es, ds
      push ds
      push es
      push cs
      push cs
      pop ds
      pop es
      mov di, fn1
      call get_file_name
      ;es is set
      mov di, eop1
      call get_file_password
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
      pop es
      pop ds
      ;;;;;;;;;;;;;;;
      
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
      
      pop eax
      jmp file_name_delim_give_error
file_name_delim_valid_password:
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, valid_pass_msg
      call print_str
      pop ds
      ;;;;;;;;;;;
      
      pop eax    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                                                                                                                                                                                                           
      jmp file_name_delim_end_func
      
file_name_delim_give_error:
      mov ah, 1
      mov dword ptr cs:[dw1], 0ffffeeeeh
      mov dword ptr cs:[dw2], 0ffffffffh
      mov dword ptr cs:[dw3], 0ffffeeeeh
      mov byte ptr cs:[b1], 0ffh
      mov byte ptr cs:[eop2][0], 0
      mov byte ptr cs:[fn2][0], 0                 
file_name_delim_end_func:
      
      pop edi
      pop esi
      pop ebp
      pop ecx
      pop ebx
      ret      
file_name_delim endp

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
      mov cx, 10
      ;si and ds are set
      rep movsb
      pop es
      ;;;;;;;;;;;
       
      add word ptr cs:[st_pt1], 10
       
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
      mov cx, 10
      ;si and ds are set
      rep movsb
      pop es
      ;;;;;;;;;;;
       
      add word ptr cs:[st_pt2], 10
       
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
       
      sub word ptr cs:[st_pt1], 10
       
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, st_dat1
      mov ax, word ptr cs:[st_pt1]
      add si, ax
      mov cx, 10
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
       
      sub word ptr cs:[st_pt2], 10
       
      ;setting ds
      push ds
      push cs
      pop ds
      mov si, st_dat2
      mov ax, word ptr cs:[st_pt2]
      add si, ax
      mov cx, 10
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

;block = cs:[dw4]
;ah is status 1 if error
clear_target proc near
      push bx
      push cx
      push edx
      push di
      push ds
      push es       

      push cs
      push cs
      pop ds
      pop es
      
      mov di, buf0
      mov cx, 512
      call fill_array_with_zero
             

      mov edx, dword ptr cs:[dw4]
      add edx, dword ptr cs:[root_dir_end]
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      cmp ah, 0
      jne cl_target_give_error
      xor ah, ah
cl_target_give_error:

      mov ah, 1
cl_target_end_func:
      
      pop es
      pop ds
      pop di
      pop edx
      pop cx
      pop bx             
      ret
clear_target endp

;c_fe_sp = cs:[dw1]
;c_fe_p + 64 = cs:[dw2] *<--attn
;dsm_n = cs:[dw3]
;ah is the status 1 if error
delete_file proc near
      push dword ptr cs:[dw1]
      push dword ptr cs:[dw2]
      push dword ptr cs:[dw3]
      push dword ptr cs:[dw4]
      push dword ptr cs:[current_file_entry_sec_ptr]
      push word ptr cs:[current_file_entry_ptr]
      push dword ptr cs:[dsm]
      push esi
      push edi
      push ebx
      push cx
       
      sub dword ptr cs:[dw2], 64
      mov ebx, dword ptr cs:[dw1]
      mov dword ptr cs:[current_file_entry_sec_ptr], ebx
      mov word ptr cs:[current_file_entry_ptr], 512
      push dword ptr cs:[dw3]
      pop dword ptr cs:[dsm]
      call get_file_entry
      cmp ah, 0
      jne _delete_file_give_error
      mov ebx, dword ptr cs:[dw2]
      mov eax, dword ptr cs:[file_entry_sec][ebx][60]
      mov dword ptr cs:[dw4], eax ;cs:[dw4] = st_block
      mov byte ptr cs:[file_entry_sec][ebx][47], DELETED
      cmp dword ptr cs:[dw3], 0ffffeeeeh
      jne _delete_file_dsm_n_ne20ffee
      mov edx, dword ptr cs:[dw1]
      jmp _delete_file_next_part
_delete_file_dsm_n_ne20ffee:
      mov edx, dword ptr cs:[dw3]
      add edx, dword ptr cs:[root_dir_end]
_delete_file_next_part:
      ;edx is set
       
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_entry_sec
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop ds
      ;;;;;;;;;;;
       
      cmp ah, 0
      jne _delete_file_give_error
      
      cmp dword ptr cs:[dw4], 0
      je _delete_file_end_func
_delete_file_loop_1:

      cmp dword ptr cs:[dw4], 0ffffffffh
      je _delete_file_end_func
      call clear_target
      mov esi, dword ptr cs:[dw4]
      call convert_hdd_fptt_index2sec
      ;edi is new index
      ;edx is set
       
      ;setting ds
      push ds
      push cs
      pop ds
      push edi
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call read_hdd_sector
      pop edi
      pop ds
      ;;;;;;;;;;;
       
      cmp ah, 0
      jne _delete_file_give_error
      
            
      ;sub di, 2
      dec edi
      mov eax, 4
      push edx
      mul edi ;We should remember that mul instruction will clear edx register
      pop edx
      mov edi, eax
      push dword ptr cs:[file_pt_table][edi]
      pop dword ptr cs:[dw4]
      mov dword ptr cs:[file_pt_table][edi], 0 ;my mean is the same dword ptr
      ;edx is set
       
      ;setting ds
      push ds
      push cs
      pop ds
      push edi
      mov di, file_pt_table
      mov cx, 1
      mov bl, byte ptr cs:[active_partition]
      call write_hdd_sector
      pop edi
      pop ds
      ;;;;;;;;;;;
      
      cmp ah, 0
      jne _delete_file_give_error          
      jmp _delete_file_loop_1
_delete_file_give_error:
       
      mov ah, 1              
_delete_file_end_func:
       
      pop cx
      pop ebx
      pop edi
      pop esi
      pop dword ptr cs:[dsm]
      pop word ptr cs:[current_file_entry_ptr]
      pop dword ptr cs:[current_file_entry_sec_ptr]
      pop dword ptr cs:[dw4]
      pop dword ptr cs:[dw3]
      pop dword ptr cs:[dw2]
      pop dword ptr cs:[dw1]
      ret  
delete_file endp

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
      push ebx
      push ecx
      push esi
      push edi
      push dword ptr cs:[dw0]
      push dword ptr cs:[dw1]
      push dword ptr cs:[dw2]
      push dword ptr cs:[dw3]
      push dword ptr cs:[dw4]
      push dword ptr cs:[dw5]
      push dword ptr cs:[dsm]
      push word ptr cs:[current_file_entry_ptr]
      push dword ptr cs:[current_file_entry_sec_ptr]      
      
      ;ds and si are set
      call check_path
      cmp ah, 1
      je delete_file_give_error
      ;ds and si are set
      call file_name_delim
      ;cs:[dw1] = dsm_n
      ;cs:[dw2] = p_f_c
      ;cs:[dw3] = p_dsm_n
      ;cs:[b1] = is file ?
      ;cs:fn2 = fn
      ;cs:eop2 = fe
      cmp ah, 1
      je delete_file_give_error

      push dword ptr cs:[dw1]
      pop dword ptr cs:[dsm]
      call make_cfe_sp_def
      call make_cfe_p_def
      
delete_file_loop_1:
      
      call get_file_entry
      cmp ah, 0
      jne delete_file_give_error
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      mov di, eop1
      call get_file_ext
      mov di, eop3
      call get_file_password
      pop es
      ;;;;;;;;;;;
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
      mov eax, dword ptr cs:[current_file_entry_sec_ptr]
      dec eax
      mov dword ptr cs:[st_val], eax ;real_c_fe_sp = c_fe_sp - 1 
      push word ptr cs:[current_file_entry_ptr]
      pop word ptr cs:[st_val][4]
      cmp dword ptr cs:[dw1], 0ffffeeeeh
      jne delete_file_dw1_isnot_e2ffee
      mov eax, dword ptr cs:[dw1] ; = 0ffffeeeeh
      jmp delete_file_final_perform_1
delete_file_dw1_isnot_e2ffee:
      
      push dword ptr cs:[dw1]
      pop dword ptr cs:[dw2]
      mov ecx, dword ptr cs:[dsm]
      call find_prev_block
      cmp eax, 0
      je delete_file_give_error
delete_file_final_perform_1:
      
      mov dword ptr cs:[st_val][6], eax
      
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
      
      call get_file_starting_block      
      cmp eax, 0
      je delete_file_final_works
      mov dword ptr cs:[dw1], eax

      ;Here it's a real folder and we want go inside it
      call make_cfe_sp_def
      call make_cfe_p_def
      mov dword ptr cs:[dsm], eax ;performing paragraph 1

delete_file_main_loop:
      
      call get_file_entry
      cmp dword ptr cs:[dsm], 0
      je delete_file_give_error
      cmp ah, 1
      je delete_file_give_error
      cmp ah, 0
      je delete_file_ml_file_got ;ml = main_loop
      
      ;Here surly ah = 2
      
      cmp word ptr cs:[st_pt2], 10
      je delete_file_final_works ;There is only one entry in the stack
      
      ;Here surly cs:[st_pt2] > 10
      
      mov di, st_val
      ;setting es
      push es
      push cs
      pop es
      call _pop_pathing
      pop es
      ;;;;;;;;;;;
      
      push dword ptr cs:[st_val]
      pop dword ptr cs:[current_file_entry_sec_ptr]
      call make_cfe_p_def
      push dword ptr cs:[st_val][6]
      pop dword ptr cs:[dsm]
      push dword ptr cs:[dsm]
      pop dword ptr cs:[dw1]
      
      call get_file_entry
      cmp ah, 0
      jne delete_file_give_error
      
      push word ptr cs:[st_val][4]
      pop word ptr cs:[current_file_entry_ptr]
      
      jmp delete_file_main_loop ;Return to parent folder
      
delete_file_ml_file_got:

      call get_file_attr
      mov byte ptr cs:[b3], al
      mov byte ptr cs:[b4], al
      and al, DELETED
      cmp al, DELETED
      je delete_file_main_loop

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Performing paragraph 2
      mov eax, dword ptr cs:[current_file_entry_sec_ptr]
      dec eax
      mov dword ptr cs:[st_val], eax ;real_c_fe_sp = c_fe_sp - 1 
      push word ptr cs:[current_file_entry_ptr]
      pop word ptr cs:[st_val][4]    
      push dword ptr cs:[dw1]
      pop dword ptr cs:[dw2]
      mov ecx, dword ptr cs:[dsm]
      call find_prev_block
      cmp eax, 0
      je delete_file_give_error
      mov dword ptr cs:[st_val][6], eax
      
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
      mov eax, dword ptr cs:[current_file_entry_sec_ptr]
      dec eax
      mov dword ptr cs:[st_val], eax ;real_c_fe_sp = c_fe_sp - 1 
      push word ptr cs:[current_file_entry_ptr]
      pop word ptr cs:[st_val][4]    
      push dword ptr cs:[dw1]
      pop dword ptr cs:[dw2]
      mov ecx, dword ptr cs:[dsm]
      call find_prev_block
      cmp eax, 0
      je delete_file_give_error
      mov dword ptr cs:[st_val][6], eax
      
      mov si, st_val
      push ds
      push cs
      pop ds
      call _push_pathing
      pop ds
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;>> An entry went in stack
      
      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      mov di, eop3
      call get_file_password
      pop es
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

      call get_file_starting_block
      cmp eax, 0
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
      call make_cfe_sp_def ;FOR ALL HACKERS!!!
      call make_cfe_p_def
      mov dword ptr cs:[dsm], eax
      mov dword ptr cs:[dw1], eax ;Parents st_blk
      jmp delete_file_main_loop
delete_file_ml_is_not_fold: ;is file

      ;setting es
      push es
      push cs
      pop es
      mov di, fn1
      call get_file_name
      mov di, eop3
      call get_file_password
      mov di, eop1
      call get_file_ext
      pop es
      ;;;;;;;;;;;
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
      
      push dword ptr cs:[st_val]
      pop dword ptr cs:[dw1]
      mov ax, word ptr cs:[st_val][4]
      movzx eax, ax
      mov dword ptr cs:[dw2], eax
      push dword ptr cs:[st_val][6]
      pop dword ptr cs:[dw3]
      
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

      pop dword ptr cs:[current_file_entry_sec_ptr]
      pop word ptr cs:[current_file_entry_ptr]
      pop dword ptr cs:[dsm]
      pop dword ptr cs:[dw5]
      pop dword ptr cs:[dw4]
      pop dword ptr cs:[dw3]
      pop dword ptr cs:[dw2]
      pop dword ptr cs:[dw1]
      pop dword ptr cs:[dw0]
      pop edi
      pop esi
      pop ecx
      pop ebx
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
      mov cx, 63
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
      mov cx, 41
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
      ;si is set
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
      push es
      
      push cs
      pop es
      mov di, file_entry_sec
      add di, bx
      cld
      ;ds and si are set
      mov cx, 3
      rep movsb
      
      pop es
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
      push ecx
      
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
      
      pop ecx
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
      ;cs:[dw3] = f_c
      ;cs:[dw4] = dsm_n
      ;cs:[dw5] = st_block
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
      mov cx, 41
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
      ;cs:[dw1] = dsm_n
      ;cs:[dw2] = p_f_c
      ;cs:[dw3] = p_dsm_n;
      ;cs:[b1] = is file ?
      ;cs:fn2 is set
      ;cs:eop2 is set 
       
      cmp dword ptr cs:[dw1], 0 ;THIS FOR WHEN FOLDER IS EMPTY
      je create_file_entry_crt_dsm
        
      ;Here cs:[dw1] = 0ffffeeeeh or cs:[dw1] # 0ffffeeeeh
      push dword ptr cs:[dw1]
      pop dword ptr cs:[dsm]
      call make_cfe_sp_def     
      call make_cfe_p_def
          
create_file_finding_eofe:                              
      call get_file_entry
      cmp ah, 1
      je create_file_entry_give_error
      cmp ah, 2
      jne create_file_finding_eofe
          
      ;ATTN : get_file_entry has read the sector and file_entry_sec is set
          
      mov bx, word ptr cs:[current_file_entry_ptr] ; +64
      cmp bx, 512
      jne create_file_entry_con_1
      cmp dword ptr cs:[dsm], 0ffffeeeeh
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
      add bx, 41
          
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
      add bx, 10 ;8
      add di, bx
      mov word ptr cs:[di], 512
      ;WE DON'T NEED THESE PARTS OF FILE ENTRY THEN WE SHOULD SET THEM TO ZERO (WE HAVE DONE)
      cmp dword ptr cs:[dsm], 0ffffeeeeh
      jne create_file_dsm_ne2ffee_1
      mov edx, dword ptr cs:[current_file_entry_sec_ptr]
      dec edx
      jmp create_file_con_0
create_file_dsm_ne2ffee_1:
      push dword ptr cs:[dw1]
      pop dword ptr cs:[dw2]
      mov ecx, dword ptr cs:[dsm]
      call find_prev_block
      cmp eax, 0
      je create_file_entry_give_error
      mov edx, eax
      add edx, dword ptr cs:[root_dir_end]
create_file_con_0:
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting ds
      push ds
      push cs
      pop ds
          
      mov di, file_entry_sec
      call write_hdd_sector
          
      pop ds
      ;;;;;;;;;;;
      pop di
      cmp ah, 0
      jne create_file_entry_give_error
      ;ah is set          
      jmp create_file_entry_end_func
create_file_new_dsm_needed_0:
      ;Here dsm # 0ffffeeeeh and cfe_p = 512
      push edi
      mov eax, dword ptr cs:[dw1]
      call find_eof
      mov dword ptr cs:[dw4], edi
      pop edi
      cmp edx, 0ffffffffh
      je create_file_entry_give_error
      ;now cs:[dw4] is CCS understandable fp index(eof)
      ;and edx is set (eof)
      push edx
      push di
      call find_blank_block
      mov dword ptr cs:[dw5], edi
      mov dword ptr cs:[dw7], edi
      mov dword ptr cs:[dw6], edx
      pop di
      pop edx
      cmp dword ptr cs:[dw6], 0ffffffffh
      je create_file_entry_give_error
      ;now cs:[dw5] is CCS understandable fp index(blank)
      ;and cs:[dw6] is set (blank)
      push edx
      mov eax, dword ptr cs:[dw5]
      add eax, 4
      mov dword ptr cs:[dw5], 4
      xor edx, edx
      div dword ptr cs:[dw5]
      mov dword ptr cs:[dw5], eax
      mov eax, dword ptr cs:[dw6]
      dec eax
      mov ebx, 128
      mul ebx
      add dword ptr cs:[dw5], eax
      pop edx
      ;;;;;;;;;;;;;;;;;;;;;;;;
      ;now cs:[dw5] is user understandable fp index
      ;edx is set
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting es
      push ds
      push cs
      pop ds
      mov di, file_pt_table
      call read_hdd_sector    
      pop ds
      ;;;;;;;;;;;
      pop di
         
      cmp ah, 0
      jne create_file_entry_give_error
      mov esi, dword ptr cs:[dw4]
      push dword ptr cs:[dw5]
      pop dword ptr cs:[file_pt_table][esi]
          
      ;edx is set
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_pt_table
      call write_hdd_sector    
      pop ds
      ;;;;;;;;;;;
      pop di
      cmp ah, 0
      jne create_file_entry_give_error
         
      mov edx, dword ptr cs:[dw6]
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
         
      push di
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_pt_table
      call read_hdd_sector
      pop ds
      ;;;;;;;;;;; 
      pop di
      cmp ah, 0
      jne create_file_entry_give_error
          
      mov esi, dword ptr cs:[dw7]
      mov dword ptr cs:[file_pt_table][esi], 0ffffffffh
      
      ;edx is set
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_pt_table
      call write_hdd_sector    
      pop ds
      ;;;;;;;;;;;
      pop di
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
          
      mov edx, dword ptr cs:[dw5]
      add edx, dword ptr cs:[root_dir_end]
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting es
      push ds
      push cs
      pop ds
      mov di, file_entry_sec
      call write_hdd_sector
      pop ds
      ;;;;;;;;;;;
      pop di
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
      add bx, 41
          
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
      add bx, 10;8
      add di, bx
      mov word ptr cs:[di], 512
      ;WE DON'T NEED THESE PARTS OF FILE ENTRY THEN WE SHOULD SET THEM TO ZERO (WE HAVE DONE)
      ;edx is set
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting ds
      push ds
      push cs
      pop ds
          
      mov di, file_entry_sec
      call write_hdd_sector
          
      pop ds
      ;;;;;;;;;;;
      pop di
      cmp ah, 0
      jne create_file_entry_give_error
      ;ah is set          
      jmp create_file_entry_end_func
create_file_entry_crt_dsm:
      ;This is for when parent folder is empty
      push di
      call find_blank_block
      mov dword ptr cs:[dw4], edi
      mov dword ptr cs:[dw6], edx
      pop di
      ;now cs:[dw4] is blank block's index #, cs:[dw6] is sector #
      mov eax, dword ptr cs:[dw4]
      add eax, 4
      mov ebx, 4
      xor edx, edx
      div ebx
      mov dword ptr cs:[dw5], eax
      mov eax, dword ptr cs:[dw6]
      dec eax
      mov ebx, 128
      mul ebx
      add dword ptr cs:[dw5], eax
      ;cs:[dw5] is brown index #
          
      call make_cfe_sp_def
      call make_cfe_p_def
      push dword ptr cs:[dw3]
      pop dword ptr cs:[dsm]
          
      mov ecx, dword ptr cs:[dw2]
create_file_crt_dsm_loop_0:
      call get_file_entry
      cmp ah, 1
      je create_file_entry_give_error                  
      loop create_file_crt_dsm_loop_0
          
      mov si, word ptr cs:[current_file_entry_ptr]
      sub si, 64 
      push dword ptr cs:[dw5]
      pop dword ptr cs:[file_entry_sec][esi][60]
          
      cmp dword ptr cs:[dsm], 0ffffeeeeh
      jne create_file_crt_dsm_ne_ffee
      mov edx, dword ptr cs:[current_file_entry_sec_ptr]
      dec edx
      jmp crt_file_crt_dsm_ne_ffee_con0
create_file_crt_dsm_ne_ffee:
      push dword ptr cs:[dw3]
      pop dword ptr cs:[dw2]
      mov ecx, dword ptr cs:[dsm]
      call find_prev_block
      cmp eax, 0
      je create_file_entry_give_error
      mov edx, eax
      add edx, dword ptr cs:[root_dir_end]
crt_file_crt_dsm_ne_ffee_con0:                                          
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_entry_sec
      call write_hdd_sector
      pop ds
      ;;;;;;;;;;;
      pop di          
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
          
      mov edx, dword ptr cs:[dw5]
      add edx, dword ptr cs:[root_dir_end]
      mov dword ptr cs:[dw7], edx
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_entry_sec
      call write_hdd_sector
      pop ds
      ;;;;;;;;;;;
      pop di
      cmp ah, 0
      jne create_file_entry_give_error
          
      mov edx, dword ptr cs:[dw6]
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
           
      push di
      ;setting ds
      push ds
      push cs
      pop ds
      mov di, file_pt_table
      call read_hdd_sector
      pop ds
      ;;;;;;;;;;;
      pop di
      cmp ah, 0
      jne create_file_entry_give_error
          
      mov esi, dword ptr cs:[dw4]
      mov dword ptr cs:[file_pt_table][esi], 0ffffffffh
          
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
           
      push di
      ;setting es
      push ds
      push cs
      pop ds
      mov di, file_pt_table
      call write_hdd_sector
      pop ds
      ;;;;;;;;;;;
      pop di
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
      add bx, 41
          
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
      add bx, 10;8
      add di, bx
      mov word ptr cs:[di], 512
      ;WE DON'T NEED THESE PARTS OF FILE ENTRY THEN WE SHOULD SET THEM TO ZERO (WE HAVE DONE)
      mov edx, dword ptr cs:[dw7]
      mov bl, byte ptr cs:[active_partition]
      mov cx, 1
          
      push di
      ;setting es
      push ds
      push cs
      pop ds
          
      mov di, file_entry_sec
      call write_hdd_sector
          
      pop ds
      ;;;;;;;;;;;
      pop di
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
;file attributes = cs:b7
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
;folder attributes = cs:b7
;ah = status 1 if error
createfolder proc near
      ;ds:si is set
      ;es:di is set
      or byte ptr cs:[b7], FOLDER
      call create_file_entry
      ret
createfolder endp

;ax = the integer number
disp_num2 proc near
          push bx
          push dx
          mov bx, 10000
          call to_deci2
          mov bx, 1000
          call to_deci2
          mov bx, 100
          call to_deci2
          mov bx, 10
          call to_deci2
          add al, 30h
          call put_char
          pop dx
          pop bx
          ret
to_deci2:
          xor dx, dx
          div bx
          add al, 30h
          push dx
          call put_char
          pop ax
          ret
disp_num2 endp

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
      mov dword ptr cs:[dsm], 0ffffeeeeh
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
      push dword ptr cs:[dw5]          
      call file_name_delim
      pop dword ptr cs:[dw5]
      cmp byte ptr cs:[b1], IS_FILE
      je show_dir_give_error
      cmp dword ptr cs:[dw5], 0
      je show_dir_give_error
      push dword ptr cs:[dw5]
      pop dword ptr cs:[dsm]
show_dir_04:
      call make_cfe_sp_def
      call make_cfe_p_def
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
      push es
      push cs
      pop es          
      mov di, fn0
      call get_file_name
      mov di, eop0
      call get_file_ext    
      mov di, fdate0
      call get_file_date
      pop es
          
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
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][2]
      xor ah, ah
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][3]
      xor ah, ah
      call disp_num2
      mov al, ' '
      call put_char
      mov al, byte ptr cs:[fdate0][4]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][5]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][6]
      xor ah, ah
      call disp_num2          
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
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][2]
      xor ah, ah
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][3]
      xor ah, ah
      call disp_num2
      mov al, ' '
      call put_char
      mov al, byte ptr cs:[fdate0][4]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][5]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][6]
      xor ah, ah
      call disp_num2                    
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
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][2]
      xor ah, ah
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][3]
      xor ah, ah
      call disp_num2
      mov al, ' '
      call put_char
      mov al, byte ptr cs:[fdate0][4]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][5]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][6]
      xor ah, ah
      call disp_num2
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
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][2]
      xor ah, ah
      call disp_num2
      mov al, '/'
      call put_char
      mov al, byte ptr cs:[fdate0][3]
      xor ah, ah
      call disp_num2
      mov al, ' '
      call put_char
      mov al, byte ptr cs:[fdate0][4]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][5]
      xor ah, ah
      call disp_num2
      mov al, ':'
      call put_char
      mov al, byte ptr cs:[fdate0][6]
      xor ah, ah
      call disp_num2
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

int21h:
      pop word ptr cs:[_ip_val]
      pop word ptr cs:[_cs_val]
      pop word ptr cs:[_flags]
      mov word ptr cs:[_sp_val], sp
          
      mov dword ptr cs:[dw1], eax
      mov ax, cs
      cli
      mov ss, ax
      mov sp, 0ffeeh
      sti
      mov eax, dword ptr cs:[dw1]
         
      cmp ah, 0
      jne int21h_next_1
      call put_char
      jmp _IRET
int21h_next_1:  ;cx = returns number of printed characters
      cmp ah, 1
      jne int21h_next_2
      call str_len
      jmp _IRET
int21h_next_2:
      cmp ah, 2
      jne int21h_next_3
      call getch
      jmp _IRET
int21h_next_3:
      cmp ah, 3
      jne int21h_next_4
      call getche
      jmp _IRET
int21h_next_4:
      cmp ah, 4
      jne int21h_next_5
      call get_str
      jmp _IRET
int21h_next_5:
      cmp ah, 5
      jne int21h_next_6
      call get_pass
      jmp _IRET
int21h_next_6:
      cmp ah, 6
      jne int21h_next_7
      call get_comp_pass
      jmp _IRET
int21h_next_7:
      cmp ah, 7
      jne int21h_next_8
      push eax
      mov eax, ecx
      call disp_num
      pop eax
      jmp _IRET
int21h_next_8:
      cmp ah, 8
      jne int21h_next_9
      mov byte ptr cs:[active_partition], al
      call make_def_fids
      jmp _IRET
int21h_next_9:
      cmp ah, 9
      jne int21h_next_a
      call make_def_fids
      jmp _IRET
int21h_next_a:
      cmp ah, 0ah
      jne int21h_next_b
      call openfile
      jmp _IRET
int21h_next_b:
      cmp ah, 0bh
      jne int21h_next_c
      call readfile
      jmp _IRET
int21h_next_c:
      cmp ah, 0ch
      jne int21h_next_d
      call writefile
      jmp _IRET
int21h_next_d:
      cmp ah, 0dh
      jne int21h_next_e
      call deletefile
      jmp _IRET
int21h_next_e:
      cmp ah, 0eh
      jne int21h_next_f
      mov byte ptr cs:[b7], al
      call createfile
      jmp _IRET
int21h_next_f:
      cmp ah, 0fh
      jne int21h_next_10
      mov byte ptr cs:[b7], al
      call createfolder
      jmp _IRET
int21h_next_10:
      cmp ah, 10h
      jne int21h_next_11
      call get_str
      jmp _IRET
int21h_next_11:
      cmp ah, 11h
      jne int21h_next_12
      call get_pass
      jmp _IRET
int21h_next_12:
      cmp ah, 12h
      jne int21h_next_13
      call show_dir
      jmp _IRET
int21h_next_13:
     
     

_IRET:
      mov dword ptr cs:[dw1], eax
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
      mov eax, dword ptr cs:[dw1]
      iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;BEFORE CALLING MOST OF FUNCTIONS WE MUST SET ACTIVE PATITION VALUE

_main proc near ;the main function
      mov si, welcome_msg
      call print_str
      mov byte ptr cs:[active_partition], 0
      call check_extentions
      cmp ah, 1
      jne _exit_hdd_not_supported
      call check_mbr
      cmp ah, 0
      jne _exit_mbr_error
      call make_def_fids
      mov si, hdd_supported_msg
      call print_str
      ;installing interrupts
      mov si, install_int21h_msg
      call print_str
      ;ds is set
      mov si, int21h
      mov al, 21h
      call install_service      
      jmp _exit
_exit_hdd_not_supported:
      mov si, hdd_not_supported
      call print_str
      jmp _exit_bun_hdd
_exit_mbr_error:
      mov si, mbr_error_msg
      call print_str
      mov si, prs_any_key_msg
      call print_str
      call getch
_exit_bun_hdd:
      mov si, hdd_been_unknown
      call print_str    
_exit:
      ret
_main endp

end _file_entry