board_size equ 100

section .rodata

dec_string:db "%d",0
float_string:db "%f",0
stack_size:dd 16384             ;16*1024
spp:dd 8

section .bss

global number_of_drones
global number_of_cycles
global number_of_steps_target
global number_of_steps_bprinting
global max_distance
global seed
global number_of_active_drones
global drones_array
global drones_info
global number_of_coroutines
global coroutine_array
global active_drones_array
global schedualer_pos
global target_pos
global printer_pos
global schedualer_stack
global target_stack
global printer_stack

number_of_drones:resd 1
number_of_cycles:resd 1
number_of_steps_target:resd 1
number_of_steps_bprinting:resd 1
max_distance:resd 1
seed:resd 1
number_of_active_drones:resd 1
drones_array:resd 1
drones_info:resd 1
number_of_coroutines: resd 1
coroutine_array:resd 1
active_drones_array:resd 1
schedualer_pos:resd 1
target_pos:resd 1
printer_pos:resd 1
schedualer_stack:resb 16384
target_stack:resb 16384
printer_stack:resb 16384


section .data

temp_stack_ptr:db 0x0

%macro scanCmd 3
    pushad
    push %1
    push %2
    push %3
    call sscanf
    add esp,12
    popad
%endmacro

%macro create_array 3
    mov eax,dword[%1]
    mov ebx,%2
    mul ebx
    push eax
    call malloc
    mov dword[%3],eax
    add esp,4
%endmacro

%macro initialize_coroutines 3
    mov eax,%1                          ;ptr to the start adress of the coroutine
    mov dword[%2],edx                   ;save the position in the coroutines array
    mov esi,%3
    add esi,dword[stack_size]
    mov dword[ecx+edx*8],eax
    mov dword[ecx+edx*8+4],esi
%endmacro


section .text

extern malloc
extern sscanf
extern create_target
extern schedualer
extern target
extern printer
extern drone
extern start_coroutine


main:
    push ebp
    mov ebp,esp

    mov ecx,[esp+12]
    scanCmd number_of_drones,dec_string,dword[ecx+4]
    scanCmd number_of_cycles,dec_string,dword[ecx+8]
    scanCmd number_of_steps_target,dec_string,dword[ecx+12]
    scanCmd number_of_steps_bprinting,dec_string,dword[ecx+16]
    scanCmd max_distance,float_string,dword[ecx+20]
    scanCmd seed,dec_string,dword[ecx+24]

    mov ebx,dword[number_of_drones]
    mov dword[number_of_active_drones],ebx
    
    pushad
    call create_target
    popad

    create_array number_of_drones,dword[stack_size],drones_array
    create_array number_of_drones,20,drones_info                ;20 because we have 5 params for each drone each of size 4

    call initialize_drones

    ;initialize our co-routines 

    mov edx,dword[number_of_drones]
    add edx,3                                                   ;except the drones co-routines we have printer, schedualer and target co-routines
    mov dword[number_of_coroutines],edx
    create_array number_of_coroutines, spp, coroutine_array
    dec dword[number_of_coroutines]                             ;???

    push dword[number_of_drones]
    call malloc
    add esp,4
    mov dword[active_drones_array],eax                         
    
     ; 0 means active 1 means non active


    mov ebx,0
initialize_active_drones:
    mov byte[eax+ebx],0                                         ;loop to update all the drones to be active
    inc ebx
    cmp ebx,dword[number_of_drones]
    jl initialize_active_drones

    mov ecx,dword[coroutine_array]
    mov edx,dword[number_of_coroutines]

    initialize_coroutines schedualer,schedualer_pos,schedualer_stack
    dec edx
    initialize_coroutines printer,printer_pos,printer_stack
    dec edx
    initialize_coroutines target,target_pos,target_stack
    dec edx

    mov eax,dword[number_of_drones]
    mov ebx,dword[stack_size]
    mul ebx
    mov ebx,dword[drones_array]
    add eax,ebx                         ;eax points to the end of the drones array

    mov ecx,dword[coroutine_array]
    mov edx,dword[number_of_drones]
    dec edx


drone_initialize_loop:
    mov dword[ecx+edx*8],drone              ;updating the info of the drone into the coroutine array
    mov dword[ecx+edx*8+4],eax
    sub eax,dword[stack_size]
    dec edx
    cmp edx,0
    jnl drone_initialize_loop

    mov ecx,dword[number_of_coroutines]


initiate_coroutines:
    pushad
    push ecx
    call initiate_one_coroutine
    add esp,4
    popad
    dec ecx
    cmp ecx,0
    jge initialize_coroutines
    call start_coroutine


initiate_one_coroutine:
    push ebp
    mov ebp,esp
    mov ecx,dword[ebp+8]                ;now ecx represent each coroutine's id
    mov eax,dword[coroutine_array]
    mov ebx,dword[ecx*8+eax]            ;now ebx points to the start of the coroutine's code
    mov dword[temp_stack_ptr],esp
    mov esp,dword[ecx*8+eax+4]          ;now esp has the pointer to the stack of the coroutine
    push ebx
    pushfd                              ;push all the flags into the stack of the coroutine
    pushad
    mov dword[8*ecx+eax+4],esp          ;??
    mov esp,dword[temp_stack_ptr]
    mov esp,ebp
    pop ebp
    ret


initialize_drones:
    push ebp
    mov ebp,esp
    pushad
    mov ebx,dword[drones_info]
    mov edx,1
    .loop:
        push board_size
        call random_number
        add esp,4
        mov dword[ebx],eax                  ;x
        push board_size
        call random_number
        add esp,4
        mov dword[ebx+4],eax                ;y
        push board_size
        call random_number
        add esp,4
        mov dword[ebx+12],eax               ;speed
        push 360
        call random_number
        add esp,4
        mov dword[ebx+8],eax                ;angel
        mov dword[ebx+16],0                 ;number of hits
        cmp ebx,dword[number_of_drones]
        je .done_init
        inc edx
        add ebx,20
        jmp .loop


    .done_init:
        popad
        mov esp,ebp
        pop ebp
        ret


;TODO: understand floating point and then do this func+ fibonacci_lfsr func
random_number:




