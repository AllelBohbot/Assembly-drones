board_size equ 100

%macro move_target 2
    push 20
    call get_random_number
    add esp,4
    mov dword[%1],eax
    fld dword[%1]
    fisub word[the_number_ten]                                      ;sub 10 from the floating point we got from get_random_number
    fstp dword[%1]                                                  ;now cordinate_x/y_temp is a random number in the range [-10,10]
    fld dword[%2]
    fadd dword[%1]                                                  ;the updated coordinate
    fild dword[the_number_one_hundred]
    fcomip                                                          ;check if we still in the board bounderies,compare ST[0] with ST[1]
    ja %%smaller_then_100
    fisub dword[the_number_one_hundred]                             ;the coordinate is bigger then 100 so we sub 100
    jmp %%save_the_cordinate

    %%smaller_then_100:
        fild dword[the_number_zero]
        fcomip  
        jb %%save_the_cordinate
        fiadd dword[the_number_one_hundred]
    
    %%save_the_cordinate:
        fstp dword[%2]                                             ;update the cordinate with the new value
%endmacro


section .rodata

the_number_ten:dd 10
the_number_one_hundred:dd 100
the_number_zero:dd 0


section .data

global called_by_schedualer_flag
global target_y
global target_x
called_by_schedualer_flag: dd 1
cordinate_x_temp: dd 0
cordiante_y_temp: dd 0
target_x: dd 0
target_y: dd 0


section .text

align 16
extern get_random_number
extern schedualer_pos
extern restart_coroutine
global create_target
global target

target:
    cmp dword[called_by_schedualer_flag],0
    je .called_by_drone
    move_target cordinate_x_temp, target_x
    move_target cordinate_y_temp, target_y
    jmp .finish_target


    .called_by_drone:
        call create_target
        mov dword[called_by_schedualer_flag],1


    .finish_target:
        mov ebx,dword[schedualer_pos]
        call restart_coroutine
        jmp target


create_target:
    push ebp
    mov ebp,esp
    pushad

    push board_size
    call get_random_number
    mov dword[target_x],eax
    add esp,4
    push board_size
    call get_random_number
    mov dword[target_y],eax
    add esp,4
    
    popad
    mov esp,ebp
    pop ebp
    ret
