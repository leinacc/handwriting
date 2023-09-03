INCLUDE "defines.asm"

SECTION "Text", ROM0

LoadFont::
; Main ascii font
	assert Font.end-Font <= $9800-$9200
	ld de, Font
	ld hl, $9200
	ld bc, Font.end-Font
	; Increment B if C is non-zero
	dec bc
	inc b
	inc c
	.loop:
		wait_vram
		ld a, [de]
		ld [hl+], a
		ld [hl+], a
		inc de
		dec c
		jr nz, .loop
		dec b
		jr nz, .loop

; White+black tile
	ld de, .gridTiles
	ld hl, $9000
	ld c, .cursor-.gridTiles
	call LCDMemcpySmall

; TL, Left, BL
	ld hl, $9020 + 7*2
	ld a, $01
	ld c, $14
	call LCDMemsetSmall

; Top, Bottom
	ld hl, $9050 + 7*2
	ld a, $ff
	ld c, $04
	call LCDMemsetSmall

; TR, Right, BR
	ld hl, $9070 + 7*2
	ld a, $80
	ld c, $14
	call LCDMemsetSmall

    ld de, .cursor
    ld hl, $8000
    ld c, .end-.cursor
    jp LCDMemcpySmall

.gridTiles:
	dw `00000000
	dw `00000001
	dw `00000000
	dw `00000001
	dw `00000000
	dw `00000001
	dw `00000000
	dw `01010101

	dw `33333333
	dw `33333332
	dw `33333333
	dw `33333332
	dw `33333333
	dw `33333332
	dw `33333333
	dw `32323232

.cursor:
    dw `30000000
    dw `33000000
    dw `32300000
    dw `32230000
    dw `32223000
    dw `32222300
    dw `32222230
    dw `32233333
    dw `32300000
    dw `33000000
    dw `30000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
.end:


Font:
	incbin "res/ascii.1bpp"
.end:


; DE - dest
; HL - src
; $00 is the terminator
PrintText::
.nextChar:
    wait_vram
    ld a, [hl+]
    and a
    ret z

    ld [de], a
    inc e
    jr .nextChar


; DE - dest of start of row
; HL - src
; $00 is the terminator
; Trashes B
PrintCenteredText::
    push hl
    ld b, 0

    .nextChar:
        ld a, [hl+]
        and a
        jr z, .gotLen

        inc b
        jr .nextChar

.gotLen:
    ld a, SCRN_X_B
    sub b
    srl a
    add e
    ld e, a
    adc d
    sub e
    ld d, a
    
    pop hl
    jp PrintText


; B - len
; DE - dest
; Trashes A
ClearText::
.nextTile:
    wait_vram
    ld a, $ff
    ld [de], a
    inc e
    dec b
    jr nz, .nextTile

    ret
