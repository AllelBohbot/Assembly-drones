%macro eliminate_minimal_drone 0 
    mov ecx, dword[active_drones_array]
    mov edx, dword[drones_info]
    dec dword[number_of_drones]             ;to help us deal with the loop indexes
    mov ebx,0
    %%find_first_active_drone:
        cmp byte[ecx+ebx],0
        je %%found_first_active_drone 
        inc ebx
        add edx,20
        jmp %%find_first_active_drone
    %%found_first_active_drone:
        mov esi , dword[edx+16]
        mov dword[min_target_hit],esi
        mov dword[min_target_hit_drone],ebx
    %%find_min_target_hit_loop:
        inc ebx
        add edx,20
        cmp byte[ecx+ebx],0                
        jne %%next_drone
        mov esi, dword[edx+16] 
        cmp dword[min_target_hit],esi
        jle %%next_drone
        mov dword[min_target_hit],esi
        mov dword[min_target_hit_drone],ebx
    %%next_drone:
        cmp ebx, dword[number_of_drones]
        je %%done_search
        jmp %%find_min_target_hit_loop
    %%done_search:
        dec dword[number_of_active_drones]
        inc dword[number_of_drones]
        mov ebx, dword[min_target_hit_drone]
        mov byte[ecx+ebx],1 
%endmacro


section .bss  
    stack_pointer_main:resd 1
    curr_schedualer:resd 1
   

section .rodata
    winner_string:db "winner is drone: %d",10,0

section .data
    global round_robin_counter
    count_drone_steps_k : dd 0
    count_drone_steps_T: dd 0
    count_rounds: dd 0
    round_robin_counter:dd 0
    min_target_hit: dd 0
    min_target_hit_drone: dd 0


section .text
    align 16                                
    extern coroutine_array
    extern number_of_drones
    extern drones_array
    extern number_of_steps_bprinting
    extern number_of_steps_target
    extern active_drones_array
    extern number_of_active_drones
    extern number_of_cycles
    extern drones_info
    extern target_pos
    extern printer_pos
    extern schedualer_pos
    extern sscanf
    extern printf 
    extern malloc 
    extern free 
    extern exit 
    extern number_of_coroutines
    global scheduler
    global start_coroutine
    global restart_coroutine
    global done_schedualer


    start_coroutine:
        pushad
        mov dword[stack_pointer_main],esp
        mov ebx,dword[schedualer_pos]
        jmp do_restart_coroutine


    schedualer:
        mov ecx,dword[active_drones_array]
        mov ebx,dword[round_robin_counter]
        cmp dword[number_of_active_drones],1
        je winner

        cmp byte[ecx+ebx],0
        jne .check_print_coroutine
        call restart_coroutine                  ;for drone
        
        
        .check_print_coroutine:
            inc dword[count_drone_steps_k]
            mov eax, dword[count_drone_steps_k]
            cmp eax,dword[number_of_steps_bprinting]
            jne .check_target_coroutine 
            
            mov dword[count_drone_steps_k],0
            mov ebx,dword[printer_pos]
            call restart_coroutine


        .check_target_coroutine:
            inc dword[count_drone_steps_T]
            mov eax,dword[count_drone_steps_T]
            cmp eax,dword[number_of_steps_target]
            jne .next_by_round_robin
            
            mov dword[count_drone_steps_T],0
            mov ebx,dword[target_pos]
            call restart_coroutine


        .next_by_round_robin:
            inc dword[round_robin_counter]
            mov ebx,dword[round_robin_counter]
            cmp ebx,dword[number_of_drones]
            jl schedualer

            mov dword[round_robin_counter],0
            inc dword[count_rounds]
            mov eax,dword[count_rounds]
            cmp eax,dword[number_of_cycles]
            jne schedualer

            mov dword[count_rounds],0
            eliminate_minimal_drone
            cmp dword[number_of_active_drones],1
            je winner

            eliminate_minimal_drone                         ;we have more then two drones in the game so we kill two
            jmp schedualer


    winner:
        mov ebx,0

        .loop:
            cmp byte[ecx+ebx],0
            je .found_the_winner

            inc ebx
            jmp .loop


        .found_the_winner:
            inc ebx
            push ebx
            push winner_string
            call printf
            add esp,8
            call finish_game


    restart_coroutine:
        pushfd
        pushad
        mov edx,dword[curr_schedualer]
        mov eax,dword[coroutine_array]
        mov dword[eax+8*edx+4],esp                          ;save in the array the schedualer state before we restart the coroutine we want to restart


    do_restart_coroutine: 
        mov eax,dword[coroutine_array]                      ;get the coroutines
        mov esp,dword[ebx*8+eax+4]                          ;we get the current schedualer pos in the coroutines array and we get to the stack of this coroutine(i.e of the scedualer)
        mov dword[curr_schedualer],ebx
        popad                                               ;restore the registers of schedualer
        popfd
        ret


    finish_game:
        push dword[drones_array]
        call free
        add esp,4
        push dword[drones_info]
        call free
        add esp,4
        push dword[coroutine_array]
        call free
        add esp,4
        push dword[active_drones_array]
        call free
        push 0
        call exit
        add esp,4


    done_schedualer:
        mov esp,dword[stack_pointer_main]
        popad