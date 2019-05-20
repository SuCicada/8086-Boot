assume cs:code
code segment
start:
    ; mov ax,cs
    ; mov es,ax
    ; mov bx,offset boot

    ; mov ah,3  ; 功能号,2:读扇区, 3:写扇区
    ; mov al,4  ; 扇区数
    ; mov ch,0  ; 磁道号
    ; mov cl,1  ; 扇区号
    ; mov dl,0  ; 驱动号
    ; mov dh,0  ; 磁头号
    ; int 13h

    mov ax,cs
    mov ds,ax
    mov si,offset boot
    mov ax,0h
    mov es,ax
    mov di,7c00h
    mov cx,offset over - offset boot
    cld 
    rep movsb

    mov ax,4c00h
    int 21h

; ======= 以下都是软盘里的东西了 ======
;    0:7c00h 
boot:
    jmp short boot_start
    ; func      dw offset menu - offset boot + 7c00h
    offsetsit dw (offset boot)-7c00h     ; 偏移量 要减去
    ; offsetsit dw (offset boot)-200h     ; 偏移量 要减去
    func      dw offset menu ;- offset boot + 200h
              dw offset reboot 
              dw offset start_system 
              dw offset clock 
              dw offset setclock 
boot_start:
    ; mov bx,7c00h+200h
    ; mov al,2    ; 扇区号 al 代替
    ; mov dl,0    ; 软盘
    ; mov cx,3    ; 另外拷贝的扇区数
    ; boot_start_s:
    ; push cx
    ; mov cl,al
    ; call copy_disk
    ; add bx,200h
    ; add al,1
    ; pop cx
    ; loop boot_start_s


    ; cli
    mov ax,cs:[7c02h]   ; 偏移量
    ; mov ax,cs:[202h]   ; 偏移量  
    mov bx,0
    sub bx,ax

    ; mov si,0
    ; mov ax,'0'  

boot_input:
    mov ax,func[bx][0]
    add ax,bx
    call ax    
    ; sti    
    mov ah,0
    int 16h
    ; cli 
    cmp al,'4'
    ja boot_input
    cmp al,'1'
    jb boot_input

    sub al,'0'
    mov ah,0
    mov si,ax
    add si,si

    call clear
    mov ax,func[bx][si]
    add ax,bx
    call ax
    call clear
    ; call word ptr cs:[func][bx] ; -offset boot+7c00h]
    ; cmp al,'1'
    ; add ax,bx
    ; call word ptr func[bx][si]

    ; cmp al,'2'
    ; call start_system
    ; call word ptr cs:[202h]
    jmp boot_input


    mov ax,4c00h
    int 21h

; ===============  显示菜单 ==================
menu:
    jmp menu_start
    showsite: db 10,25  ; 显示菜单的行,列
    info:   
        db '1) reset pc',1
        db '2) start system',1
        db '3) clock',1
        db '4) set clock',1
menu_start:
    push ax
    push cx
    push dx
    push di
    push si
    push bp
    push es
    push ds


    mov ax,0b800h
    mov es,ax
    ; 设置显示位置
    ; mov al,showsite[0] - offset boot + 7c00h
    mov bp,bx
    add bp,offset showsite; - offset boot + 7c00h
    mov al,cs:[bp]
    mov cl,160
    mul cl   
    mov di,ax
    mov al,cs:[bp][1]
    add al,al
    mov ah,0
    add di,ax
    
    mov ax,cs
    mov ds,ax
    mov si,offset info; - offset boot + 7c00h
    add si,bx
    mov cx,4
    ms_s:
        push di  ; 保存di, 用于定位显存的下一行直接+160即可
        ms_row:
        mov al,ds:[si]
        cmp al,1
        je nextline
        mov ah,00000111b
        mov es:[di],ax
        add di,2
        add si,1
        jmp ms_row
    nextline:
    pop di
    add si,1
    add di,160
    loop ms_s
menu_end:
    pop ds
    pop es
    pop bp
    pop si
    pop di
    pop dx
    pop cx
    pop ax
    ret


; ============ 重启 =========================
reboot:
    pop ax
    pop ax
    mov ax,0ffffh
    push ax
    mov ax,0
    push ax
    retf

;  ============== 显示(用于debug) ==============
show_debug:
    push ax
    push bx
    push es

    mov bx,0b800h
    mov es,bx
    mov al,al
    mov ah,32
    mov es:[160*2+20*2],ax

    pop es
    pop bx
    pop ax
    ret
    
    ; push ax
    ; push es
    ; mov ax,0b800h
    ; mov es,ax
    ; mov al,'!'
    ; mov ah,32+128
    ; mov es:[120h],ax
    ; pop es
    ; pop ax

; ============== 引导操作系统 ===============
start_system:
    ; 两段程序一块拷贝
    mov si,offset ss_backup
    add si,bx   ; bx 是偏移量, 要加上
    mov cx,offset cd_over - ss_backup       
    call copy_code

    
    mov ax,0
    push  ax
    mov ax,200h
    push ax
    retf
ss_backup:

    mov bx,7c00h
    ; mov al,1
    mov dl,80h
    mov cl,1
    call copy_disk
    

    call clear

    ; pop ax
    ; pop ax
    mov ax,0h
    push ax
    mov ax,7c00h
    push ax
    retf    
; ========= 清屏 ==================
clear:
    push ax
    push cx
    push di
    push es 
    mov ax,0b800h
    mov es,ax
    mov di,0
    mov cx,80*25
    clear_s:
        mov byte ptr es:[di],0
        mov byte ptr es:[di+1],7
        add di,2
        loop clear_s
    pop es
    pop di
    pop cx
    pop ax
    ret

    
; ================= 拷贝磁盘 ======================
;  拷贝到 0:7c00h 处
;  传入参数: dl  驱动号  bx 地址  cl  扇区号
copy_disk:
    push ax
    ; push bx
    push cx
    push dx
    push es 


    mov ax,0
    mov es,ax
    ; mov bx,7c00h

    mov ah,2  ; 功能号,2:读扇区, 3:写扇区
    mov al,1  ; 扇区数
    mov ch,0  ; 磁道号
    ; mov cl,1  ; 扇区号
    ; mov dl,80h  ; 驱动号
    mov dh,0  ; 磁头号   
    int 13h


    pop es
    pop dx
    pop cx
    ; pop bx
    pop ax
    ret 
cd_over:
    nop

; ================== 拷贝程序 ================
;  参数: si 起始位置    cx 长度
copy_code:
    push ax
    push es
    push ds
    push di
    mov ax,cs
    mov ds,ax
    ; mov si,offset boot

    mov ax,0h
    mov es,ax
    mov di,200h

    ; mov cx,offset over - offset boot
    cld 
    rep movsb  
    pop di
    pop ds
    pop es
    pop ax
    ret




; =================== [ 3. 显示时间 ] ================
print:  db 'yy/mm/dd hh:mm:ss '
site:   db 9,8,7,4,2,0
clock:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    ; bx 要被传入  作为偏移量
    call int9_install  ; 返回值 al, 1: 不退出, 0: 退出
    ; call clear



clock_start:
    ; 比较 int9 返回值是不是要退出
    cmp byte ptr cs:[204h],0
    je clock_over

    mov ax,cs
    mov ds,ax
    mov si,offset print    
    add si,bx

    ; mov dx,0
    mov cx,6
    mov bp,offset site   ; 记录site
    add bp,bx    ; 加上偏移量
    s:
        push cx

        ; add bx,dx
        mov al,cs:[bp]
        out 70h,al
        in al,71h

        mov ah,al
        mov cl,4
        shr ah,cl         ; 十位
        and al,00001111b  ; 个位

        add al,30h
        add ah,30h

        ; mov cl,00001010b
        mov ds:[si],ah
        ; mov ds:[si+1],cl
        mov ds:[si+1],al
        ; mov ds:[si+3],cl
        ; mov ds:[si+5],cl

        inc bp   ; site 记录加一
        add si,3
        pop cx
        loop s

    mov ax,0b800h
    mov es,ax
    mov di,160*12+20*2

    ; mov ax,cs
    ; mov ds,ax
    mov si,offset print
    add si,bx
    mov cx,offset site - offset print
    clock_show_s:
        mov al,cs:[si]
        mov es:[di],al
        add si,1
        add di,2
        loop clock_show_s
    jmp clock_start

clock_over:
    ; call clear 

    call int9_remove

    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ----------------- int9 中断 ------------------------
; bx 是偏移量  返回 0:0204
; 空间分配说明
; 0:200 - 0:203 原ip.cs  0:204 int9中断返回值
; 0:205  int9中断开始
int9_install:
    push ax
    push cx
    push si
    push di
    push ds
    push es 


    ; push cs
    ; pop ds

    
    mov ax,0
    mov es,ax
    mov ax,cs
    mov ds,ax

    mov si,offset int9
    add si,bx
    mov di,205h

    mov cx,offset int9_end - offset int9
    cld
    rep movsb

    push es:[9*4]
    pop es:[200h]
    push es:[9*4+2]
    pop es:[200h+2]

    cli 
    mov word ptr es:[9*4],205h
    mov word ptr es:[9*4+2],0
    sti

    mov byte ptr cs:[204h],1    ; 将标志 默认为1
    
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
int9_remove:
    push ax
    push es

    mov ax,0
    mov es,ax
    cli 
    push es:[200h]
    pop es:[9*4]
    push es:[200h+2]
    pop es:[9*4+2]
    sti
    pop es
    pop ax
    ret
; origin: dw 0,0  ;ip  cs
int9:
    push ax
    push bx
    push cx
    push es

    in al,60h
    pushf
    call dword ptr cs:[200h]  ; care cs

    cmp al,1
    je int9_1 
    cmp al,3bh
    je int9_2
    jmp int9_iret
int9_1:
    mov byte ptr cs:[204h],0  ; 返回  <- 0
    jmp int9_iret   
int9_2:
    mov ax,0b800h
    mov es,ax
    mov bx,1
    mov cx,25*80
    int9_s:
        inc byte ptr es:[bx]
        add bx,2
        loop int9_s
    ; mov byte ptr cs:[204h],1    ; 返回  <- 1
    jmp int9_iret
int9_iret:
    ; call show_debug
    pop es
    pop cx
    pop bx
    pop ax
    iret   
    
int9_end:
    nop

; =======================================================
; ================== 4. Set Time ========================
; =======================================================

setclock:
    jmp setclock_start
    setclock_info:
        db 'press Backspace to delete current number.',1
        db 'press Enter to Set Time.',1
        db 'press Esc to Exit.',1
        db 'yy/mm/dd hh:mm:ss.',1
    timeform: db '--/--/-- --:--:-- '
    newtime: ; db 'xxxxxxxxxx '
    ; site:   db 9,8,7,4,2,0
setclock_start:
    push bp

    mov bp,0
    sub bp,cs:[7c02h]   ; 偏移量, bp 绝对不会改变, 诚不欺你

    call showform    
    call getstr

    pop bp
    ret 

showform:
    push ax
    push bx
    push cx
    push es
    push di
    push si
    mov ax,0b800h
    mov es,ax
    mov cx,offset timeform - offset setclock_info
    mov di,160*8+20*2
    mov si,0
    mov bx,di   ; backup 
    showform_s:
        mov al,cs:[offset setclock_info][bp][si]
        cmp al,1
        jne showform_currentline
        mov di,bx
        add di,160
        mov bx,di
        jmp showform_so
        showform_currentline:
        mov es:[di],al
        mov byte ptr es:[di+1],7
        add di,2
        showform_so:
        add si,1
    loop showform_s
    pop si
    pop di
    pop es
    pop cx
    pop bx
    pop ax
    ret


getstr:
    push ax
    push bx
    push cx
    push ds
    push si

    mov ah,3
    call charstack
    mov ah,2
    call charstack
getstrs:
    mov ah,0
    int 16h
    cmp al,'0'
    jb nonum
    cmp al,'9'
    ja nonum

    mov ah,6   ; charCheck
    call charstack
    mov ah,0   ; charpush
    call charstack
    mov ah,2   ; charshow
    call charstack
    
    jmp getstrs

nonum:
    cmp ah,1   ; esc exit
    je setclock_end
    cmp ah,0eh
    je backspace
    cmp ah,1ch
    je enter
    jmp getstrs

backspace:
    mov ah,1
    call charstack
    mov ah,2
    call charstack
    jmp getstrs
    
enter:
    ; mov al,0
    ; mov ah,0
    ; call charstack
    mov ah,5
    call charstack
    
    jmp setclock_end

setclock_end:
    mov ah,4    
    call charstack

    pop si
    pop ds 
    pop cx
    pop bx
    pop ax
    ret
; ------------------ 字符入出栈 ---------------
charstack:
    jmp short charstart
    table dw charpush,charpop,charshow
          dw charCurrentTime,charclear,charWriteTime
          dw charCheck
    ; top dw 0 ; top of newtime
    top2 dw 0    ; top of timeform
    nodig dw 0
charstart:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push bp
    push es
    push ds


    cmp ah,6
    ja charret_c
    mov bl,ah
    mov bh,0 
    add bx,bx
    add bx,bp      ; 要带上偏移量
    mov dx,table[bx]   ; 第一个偏移量只能找见存储单元正确的位置
    add dx,bp          ; 第二个偏移量才能从正确的存储单元里的值,算出正确的值
    jmp dx   

charpush:
    cmp top2[bp], offset newtime - offset timeform-1
    jnb charret_c

charpush_c:
    ; mov si,offset newtime
    ; add si,bp
    ; mov bx,top[bp]
    ; mov ds:[si][bx],al

    mov si,offset timeform
    add si,bp
    mov bx,top2[bp]
    mov ds:[si][bx],al

    ; add top[bp], 1
    add nodig[bp], 1    
    add top2[bp], 1

    cmp nodig[bp], 2
    jne charret_c
    mov nodig[bp], 0    
    add top2[bp], 1

    jmp charret

charret_c:
    jmp charret 
charpop:
    cmp top2[bp], 0
    je charret_c
    

    sub nodig[bp], 1
    sub top2[bp], 1

    cmp nodig[bp], 0ffffh
    jne charpop_s
    sub top2[bp], 1
    mov nodig[bp], 1
charpop_s:    
    mov si,offset timeform
    add si,bp
    mov bx,top2[bp]
    mov byte ptr ds:[si][bx],'-'

    ; dec top[bp]

    jmp charret

charshow:
    mov dh,13   ; row
    mov dl,20   ; column
    mov bx,0b800h
    mov es,bx
    mov al,160
    mov ah,0
    mul dh
    mov di,ax
    add dl,dl
    mov dh,0
    add di,dx

    mov cx,offset newtime - offset timeform
    mov si,offset timeform
    add si,bp
    charshow_s:
        mov al,cs:[si]
        mov es:[di],al
        mov byte ptr es:[di+1],7
        add si,1
        add di,2
    loop charshow_s

    ; 最后字符闪烁,模拟光标
    mov ax,offset newtime - offset timeform
    sub ax,top2[bp]
    add ax,ax
    sub di,ax
    or byte ptr es:[di+1],10000000b 
    jmp charret

charCurrentTime:
    mov bx,offset site   ; 记录site
    add bx,bp    ; 加上偏移量
    mov si,offset timeform
    add si,bp
    mov cx,6
    charCurrentTime_s:
        push cx
        mov al,cs:[bx]
        out 70h,al
        in al,71h

        mov ah,al
        mov cl,4
        shr ah,cl         ; 十位
        and al,00001111b  ; 个位

        add al,30h
        add ah,30h

        mov cs:[si],ah
        mov cs:[si+1],al

        inc bx   ; site 记录加一
        add si,3
        pop cx
        loop charCurrentTime_s
    jmp charret
    
charWriteTime:
    ; mov dx,0    ; site中的第几个
    mov ax,cs
    mov ds,ax
    mov si,offset timeform   
    add si,bp

    mov bx,offset site
    add bx,bp
    mov cx,6
    charWriteTime_s:
        push cx

        mov ah,ds:[si]    ; 高位
        mov al,ds:[si+1]  ; 低位
        ; call show_debug
        ; push ax
        ; mov ah,0
        ; int 16h
        ; pop ax

        sub ah,30h
        sub al,30h
        mov cl,4
        shl ah,cl         ; 十位

        and al,00001111b
        add al,ah         ; 个位

        mov ah,al

        mov al,cs:[bx]
        out 70h,al
        mov al,ah
        out 71h,al   ; 写入的时间
        inc bx
        add si,3
        pop cx
        loop charWriteTime_s
    jmp charret

charclear:
    ; mov top[bp],0
    mov top2[bp],0
    jmp charret

charCheck:
;------------------------ 
; input: al   output: al 
;-----------------------
    jmp short charCheck_c
    year db 0   ;  闰年:1  平年:0
    month db 0  ;  第几月  从0开始
    day db 1,0eh,1,0,1,0,1,1,0,1,0,1
    charCheck_func dw charCheck_year,charCheck_month,charCheck_day
                   dw charCheck_hour,charCheck_minute_second
charCheck_c:
    mov dl,al   ; 备份 al 写下的数字
 
    ; 通过除以3, 计算需要使用哪一个函数
    mov ax,top2[bp]   ; ax(top2) / bl(3) = al ..  ah
    mov bl,3
    div bl       ; 商 al   余数 ah
    mov bl,al    
    mov bh,0
    add bx,bx    ; 很重要, 因为我地址是用的 dw 存的
    add bx,bp
    mov bx,charCheck_func[bx]
    add bx,bp
    mov al,dl   ; 写下的数字 还给al

    call bx  ; 传入: al:写下的数字, ah: 是十位(0)还是个位(1)
             ; 传出: al(改后)  or void(不需要改) 
    ; add al,'0'
    ; call show_debug
    ; sub al,'0'

    mov bx,ss
    mov es,bx
    mov bx,sp
    mov es:[bx][2*8],al  ; 直接改栈
    jmp charret

charCheck_year:  ; ----[ output: void ]----
    push ax
    push cx
    push dx
    push si
    cmp ah,0
    je charCheck_year_o

    mov si,offset timeform
    add si,bp
    add si,top2[bp]
    mov dl,ds:[si-1]    ; 十位的数字
    sub dl,'0'
    mov dh,al
    ; 以下  dl*10+dh(al)
    mov al,dl
    mov ah,0
    mov cl,10
    mul cl     ;  ax = dl*10 
    add al,dh 

    ; 以下 al / 4 
    mov cl,4
    div cl     ; ax / cl(4) = al ... ah
    mov year[bp],0   ; 先默认为平年
    cmp ah,0   ; 真则为闰年 
    jne charCheck_year_o   ; 不是闰年则直接结束, 就是0
    mov year[bp],1    ; 是则会执行这一句

    charCheck_year_o:   ;------------------  over ------
    ; mov al,year[bp]    
    ; add al,'0'
    ; call show_debug
    pop si
    pop dx
    pop cx 
    pop ax
    ret

charCheck_month:
    call show_debug
    push si

    cmp ah,0    ; 十位 ?
    jne charCheck_month_bits ; 不是十位, 那就是个位
        cmp al,1
        jna charCheck_month_o
            mov al,1
            jmp charCheck_month_o
    charCheck_month_bits:   ; 个位
    mov si,offset timeform
    add si,bp
    add si,top2[bp]
    mov ah,ds:[si-1]    ; 十位的数字
    sub ah,'0'
    cmp ah,1    ; 看看十位是 1 吗
    jne charCheck_month_o    ;  最大12, 超过设置个位为2
        cmp al,2
        jna charCheck_month_o  ; 没有打过12, 平安无事
            mov al,2
    charCheck_month_o:
    add al,'0'
    pop si
    ret
charCheck_day:
    ret
charCheck_hour:
    ret
charCheck_minute_second:
    ret
charret:
    pop ds
    pop es
    pop bp
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ================== 一切又都结束了 ==================
over:
    nop


code ends
end start
