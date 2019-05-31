assume cs:code,ds:data
code segment
start:
    mov ax,data
    mov es,ax
    mov bx,0

    mov ah,3  ; 功能号,2:读扇区, 3:写扇区
    mov al,4  ; 扇区数
    mov ch,0  ; 磁道号
    mov cl,1  ; 扇区号
    mov dl,0  ; 驱动号
    mov dh,0  ; 磁头号
    int 13h

    ; mov ax,data
    ; mov ds,ax
    ; mov si,0
    ; mov ax,0h
    ; mov es,ax
    ; mov di,7c00h

assume cs:data
    mov cx,offset over - offset boot
    cld 
    rep movsb

    mov ax,4c00h
    int 21h
code ends

data segment
boot:
    mov ax,07c0h
    mov ds,ax

    mov ax,07c0h
    push ax
    mov ax,offset boot_start
    push ax
    retf

    func  dw offset menu 
          dw offset reboot 
          dw offset start_system 
          dw offset clock 
          dw offset setclock 
boot_start:
    mov bx,7c00h+200h
    mov al,2    ; 扇区号 al 代替
    mov dl,0    ; 软盘
    mov cx,3    ; 另外拷贝的扇区数
    boot_start_s:
        push cx
        mov cl,al
        call copy_disk
        add bx,200h
        add al,1
        pop cx
        loop boot_start_s


boot_input:
    mov ax,func[0]
    call ax

    mov ah,0
    int 16h
    cmp al,'4'
    ja boot_input
    cmp al,'1'
    jb boot_input

    sub al,'0'
    mov ah,0
    mov si,ax
    add si,si

    call clear
    call func[si]
    call clear
    jmp boot_input

    mov ax,4c00h
    int 21h

; some little function
; ===============  显示菜单 ==================
menu:
    jmp menu_start
    menu_showsite db 10,25  ; 显示菜单的行,列
    menu_info db '1) reset pc',1
              db '2) start system',1
              db '3) clock',1
              db '4) set clock',1
              db 1
              db 'Press (1-4) key to choose.',1
menu_start:
    mov dl,menu_showsite[0]
    mov dh,menu_showsite[1]
    mov cx,offset menu_start - offset menu_info 
    mov si,offset menu_info
    call show_info
    ret

; -------------[ Show Info ]---------------
show_info:   ; input: dx:row,column cx:length   si:info_site
    push ax
    push bx
    push cx
    push es
    push di
    push si

    mov ax,0b800h
    mov es,ax
    ; 设置显示位置
    mov al,dl  ; row
    mov bl,160
    mul bl
    mov di,ax

    mov al,dh  ; column
    add al,al
    mov ah,0
    add di,ax
    mov bx,di   ; backup 
    show_info_s:
        mov al,cs:[si]
        cmp al,1
        jne show_info_currentline
            mov di,bx
            add di,160
            mov bx,di
            jmp show_info_so
        show_info_currentline:
        mov es:[di],al
        mov byte ptr es:[di+1],7
        add di,2
        show_info_so:
        add si,1
    loop show_info_s
    pop si
    pop di
    pop es
    pop cx
    pop bx
    pop ax
    ret

; ========= 清屏 ==================
clear:
    push cx
    push di
    push es 
    mov cx,0b800h
    mov es,cx
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
    ret

; ================= 拷贝磁盘 ======================
;  拷贝到 0:7c00h 处
;  传入参数: dl  驱动号  bx 地址  cl  扇区号
copy_disk:
    push ax
    push cx
    push dx
    push es 

    mov ax,0
    mov es,ax

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
    pop ax
    ret 

; now let's happy 
; =============================================
; ============ 1. 重启 =========================
; =============================================
reboot:
    mov ax,0ffffh
    push ax
    mov ax,0
    push ax
    retf
    
; ============== 2.引导操作系统 ===============
; look up downstairs


; ===================================================
; =================== [ 3. 显示时间 ] ================
; ===================================================
clock_print  db 'yy/mm/dd hh:mm:ss '
clock_site   db 9,8,7,4,2,0
clock_info db 'Press F1 to Change color.',1
            db 'Press Esc to Exit.',1
clock:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    mov dl,8
    mov dh,20
    mov cx,offset clock - offset clock_info
    mov si,offset clock_info
    call show_info
    ; bx 要被传入  作为偏移量
    call int9_install  ; 返回值 al, 1: 不退出, 0: 退出
    jmp clock_start


clock_start:
    ; 比较 int9 返回值是不是要退出
    push es
    mov ax,0
    mov es,ax
    mov al,es:[204h]
    pop es
    cmp al,0
    je clock_over

    mov ax,cs
    mov ds,ax
    mov si,0  ; index of clock_print    

    mov cx,6  ; 共6个时间段
    mov di,0  ; index of clock_site
    s:
        mov al,clock_site[di]
        out 70h,al
        in al,71h

        mov ah,al
        shr ah,1          ; 十位
        shr ah,1         
        shr ah,1         
        shr ah,1         
        and al,00001111b  ; 个位

        add al,30h
        add ah,30h

        mov clock_print[si],ah
        mov clock_print[si+1],al

        inc di   ; site 记录加一
        add si,3
        loop s

    mov ax,0b800h
    mov es,ax
    mov di,160*12+20*2

    mov si,0   ; index of clock_prints
    mov cx,offset clock_site - offset clock_print
    clock_show_s:
        mov al,clock_print[si]
        mov es:[di],al
        add si,1
        add di,2
        loop clock_show_s
    jmp clock_start

clock_over:
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
    
; !!!!!!!!!!!!!!!!!!!  512 bytes !!!!!!!!!!!!!!!!!!!!!!!!!
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
    
    mov ax,0
    mov es,ax
    mov di,205h
    
    mov ax,cs
    mov ds,ax
    mov si,offset int9

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

    mov byte ptr es:[204h],1    ; 将结束标志 默认为1
    
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
int9_1:   ; press esc 
    mov byte ptr cs:[204h],0  ; 返回  <- 0
    jmp int9_iret   
int9_2:   ; press F1
    mov ax,0b800h
    mov es,ax
    mov bx,1
    mov cx,25*80
    int9_s:
        inc byte ptr es:[bx]
        add bx,2
        loop int9_s
    jmp int9_iret
int9_iret:
    pop es
    pop cx
    pop bx
    pop ax
    iret   
    
int9_end:
    nop

; =======================================================
; ============== 2.Start the System ===========================
; =======================================================
; Put this part of code here, for avoid the recover of hard disk  
start_system:
    mov ax,0
    mov es,ax
    mov bx,7c00h 
    mov ah,2  ; 功能号,2:读扇区, 3:写扇区
    mov al,1  ; 扇区数
    mov ch,0  ; 磁道号
    mov cl,1  ; 扇区号
    mov dl,80h  ; 驱动号
    mov dh,0  ; 磁头号   
    int 13h

    pop ax
    mov ax,0h
    push ax
    mov ax,7c00h
    push ax
    retf

; =======================================================
; ================== 4. Set Time ========================
; =======================================================

setclock:
    jmp setclock_start
    setclock_info db 1
        db 'Press Backspace to delete current number.',1
        db 'Press Enter to Set Time.',1
        db 'Press Esc to Exit.',1
        db 'The character ',39,'-',39,' will not be set.',1
        db 'yy/mm/dd hh:mm:ss.',1,1
    timeform db '--/--/-- --:--:-- '
setclock_start:
    mov dl,6
    mov dh,20
    mov cx,offset timeform - offset setclock_info
    mov si,offset setclock_info
    call show_info
    call getstr
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
    top   dw 0    ; top of timeform
    nodig dw 0    ; calculate for space in every port which hold 2 char
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
    mov dx,table[bx]   ; 第一个偏移量只能找见存储单元正确的位置
    jmp dx   

; --------- (0) Push Char --------------
charpush:
    cmp top, offset setclock_start - offset timeform - 1
    jnb charret_c

    charpush_c:
        mov bx,top
        mov timeform[bx],al

        add nodig, 1    
        add top, 1

        cmp nodig, 2
        jne charret_c
            mov nodig, 0    
            add top, 1

        jmp charret

charret_c:
    jmp charret 

; --------- (1) Pop Char --------------
charpop:
    cmp top,0
    je charret_c
    

    sub nodig, 1
    sub top, 1

    cmp nodig, 0ffffh
    jne charpop_s
    sub top, 1
    mov nodig, 1
charpop_s:    
    mov bx,top
    mov byte ptr timeform[bx],'-'
    jmp charret

; --------- (2) Show Time --------------
charshow:
    mov dl,13
    mov dh,20
    mov cx,offset setclock_start - offset timeform
    mov si,offset timeform
    call show_info

    mov al,160
    mov ah,0
    mul dl
    mov di,ax
    mov dl,dh
    add dl,dl
    mov dh,0
    add di,dx
    add di,top
    add di,top
    mov ax,0b800h
    mov es,ax
    or byte ptr es:[di+1],10000000b 
    jmp charret

; --------- (3) Get Current Time --------------
charCurrentTime:
    mov si,0       ; index of timeform
    mov di,0  ; index of clock_site
    mov cx,6
    charCurrentTime_s:
        mov al,clock_site[di]
        out 70h,al
        in al,71h

        mov ah,al
        shr ah,1          ; 十位
        shr ah,1         
        shr ah,1         
        shr ah,1           
        and al,00001111b  ; 个位

        add al,30h
        add ah,30h

        mov timeform[si],ah
        mov timeform[si+1],al

        inc di   ; site 记录加一
        add si,3
        loop charCurrentTime_s
    jmp charret

; --------- (4) Restore the Cursor --------------
charclear:
    mov top,0
    mov nodig,0
    jmp charret
    
; --------- (5) Write Time into the CMOS Port --------------
charWriteTime:
    mov si,0       ; index of timeform
    mov di,0       ; index of clock_site
    mov cx,6
    charWriteTime_s:
        push cx

        mov ah,timeform[si]    ; 高位
        mov al,timeform[si+1]  ; 低位
        cmp ah,'-'
        je charWriteTime_s_continue
        cmp al,'-'
        je charWriteTime_s_continue

        sub ah,30h
        sub al,30h
        mov cl,4
        shl ah,cl         ; 十位

        and al,00001111b
        add al,ah         ; 个位

        mov ah,al

        mov al,clock_site[di]
        out 70h,al
        mov al,ah
        out 71h,al   ; 写入的时间
        charWriteTime_s_continue:
        inc di
        add si,3
        pop cx
        loop charWriteTime_s
    jmp charret


; --------- (6) Check Time --------------
charCheck:
;------------------------ 
; input: al   output: al 
;------------------------
    jmp short charCheck_c
    year db 0   ;  闰年:1  平年:0
    month db 0  ;  第几月  从0开始
    day db 1,8,1,0,1,0,1,1,0,1,0,1
    charCheck_func dw charCheck_year,charCheck_month,charCheck_day
                   dw charCheck_hour,charCheck_minute_second,charCheck_minute_second
                   ; 这里为了让分和秒都执行同一个函数,故记录两次分秒检查函数
charCheck_c:        
    mov dl,al   ; 备份 al 写下的数字
 
    ; 通过除以3, 计算需要使用哪一个函数
    mov ax,top   ; ax(top) / bl(3) = al ..  ah
    mov bl,3
    div bl       ; 商 al   余数 ah
    cmp al,5
    ja charCheck_o   ; 注意这里, 因为是先检查输入再入栈的, 所以要在在这里先检查输入个数有没有超出  
    mov bl,al    
    mov bh,0
    add bx,bx    ; 很重要, 因为我地址是用的 dw 存的
    mov bx,charCheck_func[bx]
    mov al,dl   ; 写下的数字 还给al  (字符)

    call bx  ; 传入: al:写下的数字(字符), ah: 是十位(0)还是个位(1)
             ; 传出: al(改后)  or void(不需要改) 
    mov bx,ss
    mov es,bx
    mov bx,sp
    mov es:[bx][2*8],al  ; 直接改栈
charCheck_o:
    jmp charret

charCheck_year:  ; ----[ output: void ]----
    push ax
    push cx
    push dx
    push si
    cmp ah,0
    je charCheck_year_o

    mov si,top
    mov dl,timeform[si-1]    ; 十位的数字
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
    mov year,0   ; 先默认为平年
    cmp ah,0   ; 真则为闰年 
    jne charCheck_year_o   ; 不是闰年则直接结束, 就是0
        mov year,1    ; 是则会执行这一句

    charCheck_year_o:   ;------------------  over ------
    pop si
    pop dx
    pop cx 
    pop ax
    ret

charCheck_month:
    push cx
    push dx
    push si
    sub al,'0'

    cmp ah,0    ; 十位 ?
    jne charCheck_month_bits ; 不是十位, 那就是个位
        cmp al,1
        jna charCheck_month_o
            mov al,1
            jmp charCheck_month_o
    charCheck_month_bits:   ; 个位
    mov si,top
    mov ah,timeform[si-1]    ; 十位的数字
    sub ah,'0'
    cmp ah,1    ; 看看十位是 1 吗
    jne charCheck_month_00    ;  十位1,个位最大2, 超过设置个位为2
        cmp al,2
        jna charCheck_month_save  ; 没有大过12, 平安无事
            mov al,2
        jmp charCheck_month_save    
    charCheck_month_00:   ; 十位是0, 所以个位最小1
        cmp al,0
        jne charCheck_month_save
            mov al,1
        jmp charCheck_month_save
    charCheck_month_save:         ; 保存   
        mov dl,al   ; 个位
        mov cl,8
        shr ax,cl   ; 将高位降到低位,ax = 十位
        mov dh,10
        mul dh
        add al,dl   ; 十位 * 10 + 个位
        sub al,1
        mov month,al
        mov al,dl   ;  将个位还给al
    charCheck_month_o:
    add al,'0'
    pop si
    pop dx
    pop cx
    ret

charCheck_day:
    push bx
    push dx
    push si

    sub al,'0'
    mov bl,month         ; 月份(0-11)
    mov dl,bl            ; 备份给dl
    mov bh,0
    mov dh,day[bx]       ; 当月的天数的个位
    mov bl,dl            ; 还原给bl
    mov dl,3             ; 当月的天数的十位(默认3)
    cmp bl,1             ; 2月吗
    jne notFebruary  
        mov dl,2  
        ; mov bh,day[bp][1]  ; 二月默认天数, 可以直接8
        add dh,year          ; 加上闰年(1)或平年(0)
    notFebruary:    ; 不是二月
        cmp ah,0    ; 十位吗
        jne charCheck_day_bits  ; 那就是个位
            cmp al,dl       ; 比较这个月的天数的十位
            jna charCheck_day_o
                mov al,dl
                jmp charCheck_day_o
        charCheck_day_bits: 
        mov si,offset timeform
        add si,top
        mov ah,ds:[si-1]    ; 十位的数字
        sub ah,'0'
        cmp ah,dl             ; 和当月最大天数的十位比较
        jne charCheck_day_00  ; 十位不是最大, 看看十位是不是0
            cmp al,dh         ; 和dh(最大个位)比较
            jna charCheck_day_o  
                mov al,dh  
            jmp charCheck_day_o
        charCheck_day_00:
        cmp ah,0  ; 看是不是0
        jne charCheck_day_o   ; 打扰了
            cmp al,0          ; 在十位是0的情况下,看个位是不是0
            jne charCheck_day_o
                mov al,1      ; 给你点颜色康康
    charCheck_day_o:
    add al,'0'
    pop si
    pop dx
    pop bx
    ret

charCheck_hour:
    push si

    sub al,'0'
    cmp ah,0    ; 十位吗
    jne charCheck_hour_bits
        cmp al,2    ; 十位数是2?
        jna charCheck_hour_o  ; 不大于2 没问题
            mov al,2  ; 纠正你的狂妄
        jmp charCheck_hour_o
    charCheck_hour_bits:
    mov si,top
    mov ah,timeform[si-1]    
    sub ah,'0'       ; 十位的数字
    cmp ah,2
    jne charCheck_hour_o  ; 十位不为2, 完好
        cmp al,3
        jna charCheck_hour_o   ; 十位为2时, 个位不能超过3 
            mov al,3
    charCheck_hour_o:
    add al,'0'    
    pop si
    ret

charCheck_minute_second:
    sub al,'0'
    cmp ah,0    ; 十位吗
    jne charCheck_minute_second_o 
        cmp al,5   ; 看看十位大于5吗
        jna charCheck_minute_second_o
            mov al,5
    charCheck_minute_second_o:
    add al,'0'    
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

data ends
end start