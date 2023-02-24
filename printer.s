section .rodata
    drone_data_print_format: db "%d,%.2lf,%.2lf,%.2lf,%.2lf%d",10,0
    target_data_print_format: db "%.2lf %.2lf",10,0

    %macro push_floating_into_stack
        fld dword [%1]                              ;push the floating point we got to the stack 
        sub esp,8                                   
        fstp qword [esp]                           
    %endmacro


section .text
  global printer
  extern target_y
  extern target_x
  extern printf
  extern drones_info
  extern number_of_drones
  extern restart_coroutine
  extern schedualer_pos
  extern active_drones_array


printer:
    pushad
    push_floating_into_stack target_y
    push_floating_into_stack target_x
    push target_data_print_format
    call printf
    add esp,20
    popad

    mov ebx,0                                   ;drones counter
    mov eax,dword[drones_info]
    mov ecx,dword[active_drones_array]

    .loop:
        cmp ebx,dword[number_of_drones]
        je .done
        inc ebx
        cmp byte[ecx+ebx-1],1
        je .next_drone
        pushad

        push dword[eax+16]                  ;number of target destroyed in the current drone
        push_floating_into_stack eax+12     ;drone's speed 
        push_floating_into_stack eax+8      ;drone's degree
        push_floating_into_stack eax+4      ;drone's y's cordiante
        push_floating_into_stack eax        ;drone's x's cordinate
        push ebx                            ;drone's id
        push drone_data_print_format
        call printf
        add esp,44

        popad


    .next_drone:
        add eax,20                          ;drone's info is of size 20
        jmp .loop


    .done:
        mov ebx,dword[schedualer_pos]       ;going back to schedualer co-routine
        call restart_coroutine
        jmp printer
    

