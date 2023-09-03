INCLUDE "defines.asm"

SECTION "Intro", ROMX

Intro::
; Display sprites globally
	ldh a, [hLCDC]
	or LCDCF_OBJON|LCDCF_OBJ16
	ldh [hLCDC], a

; Clear OAM
	ld hl, wShadowOAM
	ld c, $a0
	ld a, $ff
	rst MemsetSmall

	ld a, h
	ldh [hOAMHigh], a

	rst WaitVBlank

; Clear screens
	ld hl, _SCRN0
	ld bc, $800
	ld a, $ff
	call LCDMemset

	call LoadScreen

; Load font and palettes
	call LoadFont
	ld a, %11100100
	ldh [hBGP], a
	ld a, %11000000
	ldh [hOBP0], a

; Load game stuff
	call InitGrid

.infLoop:
	rst WaitVBlank
	call UpdateCursor
	ld a, HIGH(wShadowOAM)
	ldh [hOAMHigh], a
	jr .infLoop


LoadScreen:
; Corners
	wait_vram
	ld a, $02
	ld [$9802], a

	wait_vram
	ld a, $04
	ld [$9802 + $20*15], a

	wait_vram
	ld a, $07
	ld [$9811], a

	wait_vram
	ld a, $09
	ld [$9811 + $20*15], a

; Top/Bottom
	ld b, 14
	ld hl, $9803
	ld de, $9803 + $20*15
	.nextTopBottom:
		wait_vram
		ld a, 6
		ld [de], a
		wait_vram
		ld a, 5
		ld [hl+], a

		inc e
		dec b
		jr nz, .nextTopBottom

; Left
	ld b, 14
	ld hl, $9802 + $20
	ld de, $20
	.nextLeft:
		wait_vram
		ld [hl], $03
		add hl, de

		dec b
		jr nz, .nextLeft

; Right
	ld b, 14
	ld hl, $9811 + $20
	ld de, $20
	.nextRight:
		wait_vram
		ld [hl], $08
		add hl, de

		dec b
		jr nz, .nextRight

; Inner
	ld hl, $9823
	ld de, $20-14
	ld b, 14
	.nextRow:
		ld c, 14
		.nextCol:
			wait_vram
			xor a
			ld [hl+], a

			dec c
			jr nz, .nextCol

		add hl, de
		dec b
		jr nz, .nextRow

	jp InitPredictText
