.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; sectiunile programului, date, respectiv cod
.data
; aici declaram date

; sarpe_vec DD 100 dup(0)

sarpe_h DD 5,5
sarpe_h2 DD 5,5

sarpe_t DD 5,5
directie_t DD 2

window_title DB "Proiect PLA- SNAKE",0
area_width EQU 1000
area_height EQU 600
area DD 0
asd DD 0


score DD 1
directie DB 1
directie2 DB 1
nr_prim DW 53
buton_start DD 0
game_over DD 0

nsarpe DD 2
n5 DD 5
n3 DD 3
n10 DD 10
n40 DD 40
n400 DD 400

bloc_rosu_count DD 0
mancare_count DD 0
m_b_count DD 0
m7_count DD 0

ciorna DD 0
counter DD 0 ; numara evenimentele de tip timer

arie_bloc_rand DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20


include digits.inc
include letters.inc
include sarpe_lib.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_line
	sub eax, '0'
	lea esi, digits
	jmp draw_text
	
make_line:
	cmp eax, '~'
	jne make_sageata
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e linie
	lea esi, letters
	jmp draw_text
	
make_sageata:
	cmp eax, '\'
	jne make_s2
	mov eax, 27 ; de la 0 pana la 25 sunt litere, 26 e linie
	lea esi, letters
	jmp draw_text
	make_s2:
	cmp eax, '['
	jne make_s3
	mov eax, 28 ; de la 0 pana la 25 sunt litere, 26 e linie
	lea esi, letters
	jmp draw_text
	make_s3:
	cmp eax, '='
	jne make_s4
	mov eax, 29 ; de la 0 pana la 25 sunt litere, 26 e linie
	lea esi, letters
	jmp draw_text
	make_s4:
	cmp eax, ']'
	jne make_space
	mov eax, 30 ; de la 0 pana la 25 sunt litere, 26 e linie
	lea esi, letters
	jmp draw_text
make_space:	
	mov eax, 31 ; de la 0 pana la 25 sunt litere, 27 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0C0C0C0h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

cap_sarpe proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	lea esi, sarpe_lib
	
	mov ebx, 10
	mul ebx
	mov ebx, 10
	mul ebx
	add esi, eax
	mov ecx, 10
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, 10
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, 10
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	cmp byte ptr [esi], 2
	je simbol_pixel_rosu
	cmp byte ptr [esi], 3
	je simbol_pixel_negru
	mov dword ptr [edi], 0FFFF00h
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFh
	jmp simbol_pixel_next
simbol_pixel_rosu:
	mov dword ptr [edi], 0FF0000h
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
cap_sarpe endp
	
; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x, y, len, color
LOCAL lop
	pusha
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x 
	shl eax, 2
	add eax, area
	mov ecx, len
	lop:
	mov dword ptr [eax], color
	add eax, 4
	loop lop
	popa
endm

line_verticala macro x, y, len, color
LOCAL lop
	pusha
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x 
	shl eax, 2
	add eax, area
	mov ecx, len
	lop:
	mov dword ptr [eax], color
	add eax, area_width*4
	loop lop
	popa
endm

dreptunghi macro x,y, L, g , color
	LOCAL lop1
	pusha
	mov ecx, g
	mov esi,x
	lop1:
	line_verticala esi, y, L ,color
	add esi, 1
	cmp esi, ecx
	loop lop1
	popa
endm

modulo10_2nr proc

	push ebp
	mov ebp, esp
	push EDX
	
	mov eax, [ebp + 8]
	mov EDX, 0
	div n10
	mul n10
	mov ebx, eax
	mov eax, [ebp + 12]
	mov EDX, 0
	div n10
	mul n10
	
	pop EDX
	mov esp, ebp
	pop ebp
	ret
modulo10_2nr endp

arie_bloc proc
	push ebp
	mov ebp, esp
	push eax
	push ebx
	push edx
	
	mov eax, [ebp + arg1]
	mov ebx, area_width
	mov edx, 0
	mul ebx
	add eax, [ebp + arg2] 
	shl eax, 2
	add eax, area
	
	mov esi, eax
	
	pop edx
	pop ebx
	pop eax
	mov esp, ebp
	pop ebp
	ret
arie_bloc endp

rand_bloc_proc proc 
	push ebp
	mov ebp, esp
	pusha
	
	mov edi, [ebp+ 24]
	dreptunghi [ebp + arg1], [ebp+ arg2], [ebp + arg3], [ebp+ arg4], edi
	
	popa
	mov esp, ebp
	pop ebp
	ret
rand_bloc_proc endp	
	
inter proc
	push ebp
	mov ebp, esp
	pusha
	
	mov esi, [sarpe_h]
	mov edi, [sarpe_h + 4]
	mov [sarpe_h2], esi
	mov [sarpe_h2 + 4], edi

	popa
	mov esp, ebp
	pop ebp
	ret
inter endp
	
rand_bloc proc
	push ebp
	mov ebp, esp
	pusha
	

	mov edi, [ebp+ arg4]
	mov ecx, [ebp+ arg3]
	
	lopitura:
	rdtsc
	
	xor ebx, ebx
	mov bx, ax
	imul bx, nr_prim
	ror eax, 4
	mov dx, ax
	xor eax, eax
	mov ax, dx
	
	push ebx
	push eax
	call modulo10_2nr
	add esp, 8
	
	
	; imul ax, nr_prim
	cmp ebx, 100
	jb lopitura
	cmp ebx, 790
	ja lopitura
	cmp eax, 50
	jb lopitura
	cmp eax, 390
	ja lopitura
	
	sub eax, [ebp+arg2]
	sub ebx, [ebp+arg1]
	
	push ebx
	push eax
	call arie_bloc
	add esp, 8
	
	cmp dword ptr [esi], 0FFh
	je lopitura1
	cmp dword ptr [esi], 0FFFFFFh
	jne lopitura
	cmp dword ptr [esi], 0FF0000h
	jne lopitura
	cmp dword ptr [esi], 000FF00h
	jne lopitura
	lopitura1:
	
	push edi
	push [ebp+ arg2]
	push [ebp + arg1]
	push eax
	push ebx
	call rand_bloc_proc
	add esp, 20

	f1:
	
	loop lopitura
	
	
	cmp edi, 0FF00h
	jne fl
	
	mov [sarpe_h], ebx
	mov [sarpe_h + 4], eax
	
	add ebx, 20
	mov [sarpe_t],ebx
	mov [sarpe_t + 4], eax   ; primul argument x si al doilea ii y
	
	call inter
	
	; dreptunghi [sarpe_h], [sarpe_h + 4], 10, 10, 0FFFF00h
	; dreptunghi [sarpe_h], [sarpe_h + 4], 5, 5, 0FF0000h
	push [sarpe_h + 4]
	push [sarpe_h]
	push area
	push dword ptr 0
	call cap_sarpe
	add esp, 16
	
	fl:
	
	
	
	popa
	mov esp, ebp
	pop ebp
	ret
rand_bloc endp

make_sarpe_start macro 
	
	push 0FF00h
	push 1
	push 30
	push 10
	call rand_bloc
	add esp,16
endm

stergere_t proc
	push ebp
	mov ebp, esp
	pusha
	
	
	
	dreptunghi [sarpe_t], [sarpe_t + 4], 10, 10, 0ffh
	mov eax, [sarpe_t]
	mov ebx, [sarpe_t + 4]
	cmp directie_t, 0
	je sus_t
	inapoi:
	mov eax, [sarpe_t]
	mov ebx, [sarpe_t + 4]
	sub eax, 10
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	mov directie_t, 1
	cmp dword ptr [esi], 0FF00h
	je c1
	add eax, 20
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	cmp dword ptr [esi], 0FF00h
	je c1
	sub eax, 10
	sus_t:
	add ebx, 10
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	mov directie_t , 0
	cmp dword ptr [esi], 0FF00h
	je c1
	sub ebx, 20
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	cmp dword ptr [esi], 0FF00h
	je c1
	mov directie_t, 1
	jmp inapoi
	
	dreptunghi 0 , 0, 10, 10, 0FFFFFFh
	c1:
	mov [sarpe_t], eax
	mov [sarpe_t + 4], ebx
	
	popa
	mov esp, ebp
	pop ebp
	ret
stergere_t endp

make_sarpe_macro macro cap,myarea, x, y
	pusha
	
	
	push y
	push x
	push myarea
	push cap
	call cap_sarpe
	add esp, 16
	
	popa
endm
	
move_sarpe proc
	push ebp
	mov ebp, esp
	pusha
	
	
	call inter
	
	mov al ,directie
	cmp al, 2
	jae ppppp
	add al, 2
	jmp ppppp1
	ppppp:
	sub al, 2
	ppppp1:
	cmp directie2, al
	jne plapsda
	mov bl, directie2
	mov directie, bl
	plapsda:
	
	cmp directie,0
	jne stanga

	mov edi, [sarpe_h + 4]
	sub edi, 10
	mov dword ptr [sarpe_h + 4], edi
	mov eax, [sarpe_h]
	mov ebx, [sarpe_h + 4]
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	cmp dword ptr [esi], 0FFh
	jne str1
	call stergere_t
	str1:
	cmp dword ptr [esi], 0FF0000h
	je final1
	cmp dword ptr [esi], 0FF00h
	je final1
	cmp dword ptr [esi], 0FF8C00h
	jne w1
	call stergere_t
	call stergere_t
	dec score
	dec m_b_count
	w1:
	cmp dword ptr [esi], 0FFFFFFh
	jne q1
	dec mancare_count
	inc score
	q1:
	
	
	dreptunghi [sarpe_h2] , [sarpe_h2 + 4], 10, 10, 0FF00h
	; dreptunghi [sarpe_h] , [sarpe_h + 4], 10, 10, 0FFFF00h
	make_sarpe_macro 1, area , [sarpe_h] , [sarpe_h + 4]
	
	stanga:
	
	cmp directie,1
	jne jos
	
	mov edi, [sarpe_h]
	sub edi, 10
	mov dword ptr [sarpe_h], edi
	mov eax, [sarpe_h]
	mov ebx, [sarpe_h + 4]
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	cmp dword ptr [esi], 0FFh
	jne str2
	call stergere_t
	str2:
	cmp dword ptr [esi], 0FF0000h
	je final1
	cmp dword ptr [esi], 0FF00h
	je final1
	
	cmp dword ptr [esi], 0FF8C00h
	jne w2
	call stergere_t
	call stergere_t
	dec score
	dec m_b_count
	w2:
	cmp dword ptr [esi], 0FFFFFFh
	jne q2
	dec mancare_count
	inc score
	q2:
	
	dreptunghi [sarpe_h2] , [sarpe_h2 + 4], 10, 10, 0FF00h
	make_sarpe_macro 0, area , [sarpe_h] , [sarpe_h + 4]
	; dreptunghi [sarpe_h] , [sarpe_h + 4], 10, 10, 0FFFF00h
	
	jos:
	
	cmp directie,2
	jne dreapta
	
	mov edi, [sarpe_h + 4]
	add edi, 10
	mov dword ptr [sarpe_h + 4], edi
	mov eax, [sarpe_h]
	mov ebx, [sarpe_h + 4]
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	cmp dword ptr [esi], 0FFh
	jne str3
	call stergere_t
	str3:
	cmp dword ptr [esi], 0FF0000h
	je final1
	cmp dword ptr [esi], 0FF00h
	je final1
	
	cmp dword ptr [esi], 0FF8C00h
	jne w3
	call stergere_t
	call stergere_t
	dec score
	dec m_b_count
	w3:
	cmp dword ptr [esi], 0FFFFFFh
	jne q3
	dec mancare_count
	inc score
	q3:
	
	dreptunghi [sarpe_h2] , [sarpe_h2 + 4], 10, 10, 0FF00h
	; dreptunghi [sarpe_h] , [sarpe_h + 4], 10, 10, 0FFFF00h
	make_sarpe_macro 3, area , [sarpe_h] , [sarpe_h + 4]
	
	dreapta:
	
	cmp directie,3
	jne final
	mov edi, [sarpe_h]
	add edi, 10
	mov dword ptr [sarpe_h], edi
	mov eax, [sarpe_h]
	mov ebx, [sarpe_h + 4]
	push eax
	push ebx
	call arie_bloc 
	add esp, 8
	cmp dword ptr [esi], 0FFh
	jne str4
	call stergere_t
	str4:
	cmp dword ptr [esi], 0FF0000h
	je final1
	cmp dword ptr [esi], 0FF00h
	je final1
	
	cmp dword ptr [esi], 0FF8C00h
	jne w4
	call stergere_t
	call stergere_t
	dec score
	dec m_b_count
	w4:
	
	cmp dword ptr [esi], 0FFFFFFh
	jne q4
	dec mancare_count
	inc score
	q4:
	
	dreptunghi [sarpe_h2] , [sarpe_h2 + 4], 10, 10, 0FF00h
	; dreptunghi [sarpe_h] , [sarpe_h + 4], 10, 10, 0FFFF00h
	make_sarpe_macro 2, area , [sarpe_h] , [sarpe_h + 4]
	
	jmp final
	final1:
	mov game_over, 1
	mov directie, 1
	mov eax, counter
	mov edx,0
	div n5
	add eax, score
	mov score, eax
	mov counter, 1
	final:
	mov al, directie
	mov directie2, al
	popa
	mov esp, ebp
	pop ebp
	ret
move_sarpe endp


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	; mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 190
	push area
	call memset
	add esp, 12
	
	
	
	
	jmp afisare_litere
	
	
evt_click:
	
	; add counter, 100
	cmp buton_start, 0
	jne continue
	mov eax, [ebp + arg3]
	cmp eax, area_height/4
	jb continue
	cmp eax, area_height/4+ 100
	ja continue
	mov eax, [ebp + arg2]
	cmp eax, area_width/3
	jb continue
	cmp eax, area_width/3 + 200
	ja continue
	
	dreptunghi 100, 50, 370, 700, 0FFh
	dreptunghi 90, 40, 390, 10, 0FF0000h
	dreptunghi 100, 40, 10, 710, 0FF0000h
	dreptunghi 800, 50, 380, 10, 0FF0000h
	dreptunghi 100, 420, 10, 700, 0FF0000h
	
	mov edx, 0FF0000h 
	mov eax, 10
	mov ebx, 50
	mov esi, 7
	
	push edx
	push esi
	push ebx
	push eax
	call rand_bloc
	add esp,16
	
	
	push edx
	push esi
	push eax
	push ebx
	call rand_bloc
	add esp,16
	
	make_sarpe_start
	
	mov counter, 0
	mov buton_start, 1
	
	continue:
	
	mov eax, [ebp + arg3]
	cmp eax, 510
	ja fail
	
	cmp eax, 450
	jb fail
	cmp eax, 480
	ja buton_stanga
	buton_sus:
	mov eax, [ebp + arg2]
	cmp eax, 450
	jb fail
	cmp eax, 480
	jg fail
	
	mov directie, 0
	; inc counter
	; call move_sarpe
	
	; dreptunghi 400 , 500 ,10 ,10 , 0FFFFFFh
	; push 0FFFFFFh
	; push 1
	; push 10
	; push 10
	; call rand_bloc
	; add esp,16
	
	jmp fail
	
	buton_stanga:
	mov eax, [ebp + arg2] 
	cmp eax, 420
	jb fail
	cmp eax, 450
	ja buton_jos
	
	mov directie, 1
	; inc counter
	
	; call move_sarpe
	
	; dreptunghi 400 , 200 ,10 ,10 , 0FFFFFFh
	
	jmp fail
	buton_jos:
	cmp eax, 480
	ja buton_dreapta
	
	mov directie, 2
	; inc counter
	
	; call move_sarpe
	
	; dreptunghi 0 , 0 ,10 ,10 , 0FFFFFFh
	jmp fail
	buton_dreapta:
	cmp eax, 510
	ja fail
	
	mov directie, 3
	; inc counter
	
	; call move_sarpe
	
	;dreptunghi 0 , 143 ,10 ,10 , 0FFFFFFh
	
	fail:
	; mov eax, [ebp + arg3]
	; mov ebx, area_width
	; mul ebx
	; add eax, [ebp + arg2] 
	; shl eax, 2
	; add eax, area
	; mov dword ptr [eax], 0FF0000h
	; mov dword ptr [eax + 4], 0FF0000h
	; mov dword ptr [eax - 4], 0FF0000h
	; mov dword ptr [eax + 4*area_width], 0FF0000h
	; mov dword ptr [eax - 4*area_width], 0FF0000h
	
	
	
	
	jmp afisare_litere
	
	
	
	jmp afisare_litere
	
evt_timer:
	inc counter
	cmp mancare_count, 5
	jbe flq
	inc m7_count
	flq:
	cmp counter, 500
	jbe flq1
	inc m7_count
	; inc m_b_count
	inc counter
	flq1:
	
	
afisare_litere:
	; afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	; cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	; cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	; cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	; scriem un mesaj
	make_text_macro 'P', area, 30, 490
	make_text_macro 'R', area, 40, 490
	make_text_macro 'O', area, 50, 490
	make_text_macro 'I', area, 60, 490
	make_text_macro 'E', area, 70, 490
	make_text_macro 'C', area, 80, 490
	make_text_macro 'T', area, 90, 490
	
	make_text_macro 'L', area, 50, 510
	make_text_macro 'A', area, 60, 510
	
	make_text_macro 'A', area, 20, 530
	make_text_macro 'S', area, 30, 530
	make_text_macro 'A', area, 40, 530
	make_text_macro 'M', area, 50, 530
	make_text_macro 'B', area, 60, 530
	make_text_macro 'L', area, 70, 530
	make_text_macro 'A', area, 80, 530
	make_text_macro 'R', area, 90, 530
	make_text_macro 'E', area, 100, 530
	
	make_text_macro 'R', area, 700, 530
	make_text_macro 'E', area, 710, 530
	make_text_macro 'A', area, 720, 530
	make_text_macro 'L', area, 730, 530
	make_text_macro 'I', area, 740, 530
	make_text_macro 'Z', area, 750, 530
	make_text_macro 'A', area, 760, 530
	make_text_macro 'T', area, 770, 530
	
	make_text_macro 'D', area, 720, 550
	make_text_macro 'E', area, 730, 550
	
	make_text_macro 'C', area, 750, 550
	make_text_macro 'A', area, 760, 550
	make_text_macro 'C', area, 770, 550
	make_text_macro 'A', area, 780, 550
	make_text_macro 'R', area, 790, 550
	make_text_macro 'A', area, 800, 550
	make_text_macro 'Z', area, 810, 550
	make_text_macro 'A', area, 820, 550
	
	make_text_macro 'T', area, 840, 550
	make_text_macro 'O', area, 850, 550
	make_text_macro 'B', area, 860, 550
	make_text_macro 'I', area, 870, 550
	make_text_macro 'A', area, 880, 550
	make_text_macro 'S', area, 890, 550
	
	make_text_macro 'D', area, 910, 550
	make_text_macro 'A', area, 920, 550
	make_text_macro 'N', area, 930, 550
	make_text_macro 'I', area, 940, 550
	make_text_macro 'E', area, 950, 550
	make_text_macro 'L', area, 960, 550
	
	cmp game_over, 1
	jne kip
	
	dreptunghi area_width/3, area_height/4 + 100, 100, 200, 0110011h
	
	line_horizontal area_width/3, area_height/4 +100, 200, 0FF0000h
	line_horizontal area_width/3 , area_height/4+ 200, 200, 0FF0000h
	line_verticala area_width/3, area_height/4+100, 100, 0FF0000h
	line_verticala area_width/3+ 200, area_height/4+100, 100, 0FF0000h
	
	
	make_text_macro 'S', area, area_width/3+ 2*16, area_height/4 + 140
	make_text_macro 'C', area, area_width/3+ 3*16, area_height/4 + 140
	make_text_macro 'O', area, area_width/3+ 4*16, area_height/4 + 140
	make_text_macro 'R', area, area_width/3+ 5*16, area_height/4 + 140
	make_text_macro 'E', area, area_width/3+ 6*16, area_height/4 + 140
	make_text_macro ' ', area, area_width/3+ 7*16, area_height/4 + 140
	
	
	; mov score,1
	mov ebx, 10
	mov eax, score
	; cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, area_width/3+ 11*16, area_height/4 + 140
	; cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, area_width/3+ 10*16, area_height/4 + 140
	; cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, area_width/3+ 9*16, area_height/4 + 140
	; cifra miilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, area_width/3+ 8*16, area_height/4 + 140
	; mov score,1
	
	kip:
	
	
	cmp buton_start, 0
	jne skip
	cmp counter, 4
	jne skip
	
	dreptunghi area_width/3, area_height/4, 100, 200, 0110011h
	
	line_horizontal area_width/3, area_height/4, 200, 0FF0000h
	line_horizontal area_width/3 , area_height/4+ 100, 200, 0FF0000h
	line_verticala area_width/3, area_height/4, 100, 0FF0000h
	line_verticala area_width/3+ 200, area_height/4, 100, 0FF0000h
	
	make_text_macro 'S', area, area_width/3+ 4*16, area_height/4 + 40
	make_text_macro 'T', area, area_width/3+ 5*16, area_height/4 + 40
	make_text_macro 'A', area, area_width/3+ 6*16, area_height/4 + 40
	make_text_macro 'R', area, area_width/3+ 7*16, area_height/4 + 40
	make_text_macro 'T', area, area_width/3+ 8*16, area_height/4 + 40
	mov score,1
	
	mov game_over,0
	
	skip:
	cmp mancare_count, 7
	jae skip2
	cmp buton_start, 0
	je skip2
	mov eax, counter
	mov edx, 0
	div n40
	cmp edx, 0
	jne skip2
	
	mov edi, 0FFFFFFh
	
	inc mancare_count
	
	cmp m_b_count, 10
	jae qoe
	cmp m7_count, 2
	jbe qoe
	
	mov m7_count, 0
	mov edi, 0FF8C00h
	inc m_b_count
	dec mancare_count
	
	qoe:
	
	push edi
	push 1
	push 10
	push 10
	call rand_bloc
	add esp,16
	
	skip2:
	
	
	
	cmp bloc_rosu_count, 5
	jae skip3
	cmp buton_start, 0
	je skip3
	mov eax, counter
	mov edx, 0
	div n400
	cmp edx, 0
	jne skip3
	
	inc bloc_rosu_count
	
	mov edx, 0FF0000h 
	mov eax, 10
	mov ebx, 50
	mov esi, 1
	
	push edx
	push esi
	push ebx
	push eax
	call rand_bloc
	add esp,16
	
	
	push edx
	push esi
	push eax
	push ebx
	call rand_bloc
	add esp,16
	
	; dreptunghi 500 , 200, 10, 10, 0FF8C00h
	
	skip3:
	
	cmp score, 0
	jne ip
	mov game_over, 1
	mov directie, 1
	mov counter, 0
	ip:
	
	
	cmp buton_start, 0
	je skip4
	mov eax, counter
	mov edx, 0
	div nsarpe
	cmp edx, 0
	jne skip4
	
	call move_sarpe
	
	skip4:
	
	cmp game_over, 1
	jne skip5
	mov buton_start, 0
	mov mancare_count, 0

	skip5:
	
	line_horizontal 450, 450, 30, 0FF0000h ; x , y , len , color
	line_horizontal 450, 480, 30, 0FF0000h
	line_verticala 450, 450, 30, 0FF0000h
	line_verticala 480, 450, 30, 0FF0000h
	make_text_macro '=', area, 462, 454
	
	line_horizontal 480, 480, 30, 0FF0000h
	line_horizontal 480, 510, 30, 0FF0000h
	line_verticala 480, 480, 30, 0FF0000h
	line_verticala 510, 480, 30, 0FF0000h
	make_text_macro '\', area, 492, 484

	
	line_horizontal 450, 510, 30, 0FF0000h
	make_text_macro ']', area, 462, 484
	
	line_horizontal 420, 510, 30, 0FF0000h
	line_horizontal 420, 480, 30, 0FF0000h
	line_verticala 420, 480, 30, 0FF0000h
	line_verticala 450, 480, 30, 0FF0000h
	make_text_macro '[', area, 431, 484
	; make_sarpe_macro 0, area, 431, 484
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	; alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	; apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	; terminarea programului
	push 0
	call exit
end start
