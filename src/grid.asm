INCLUDE "defines.asm"

SECTION "Grid", ROM0

InitGrid::
    xor a
    ld hl, wGrid
    ld c, wGrid.end-wGrid
    rst MemsetSmall

    ldh [hCursorX], a
    ldh [hCursorY], a

    ret


UpdateCursor::
    call ProcessCursorInput
    jp DisplayCursor


ProcessCursorInput:
    ldh a, [hPressedKeys]
    bit PADB_DOWN, a
    jr nz, .down

    bit PADB_UP, a
    jr nz, .up

    bit PADB_LEFT, a
    jr nz, .left

    bit PADB_RIGHT, a
    jr nz, .right

    bit PADB_START, a
    jr nz, .predict

    bit PADB_B, a
    jr nz, .deselect

    bit PADB_A, a
    jr nz, .select

    ret

.down:
    ldh a, [hCursorY]
    inc a
    cp 14
    jr nz, :+
    xor a
:   ldh [hCursorY], a
    ret

.up:
    ldh a, [hCursorY]
    dec a
    cp $ff
    jr nz, :+
    ld a, 13
:   ldh [hCursorY], a
    ret

.left:
    ldh a, [hCursorX]
    dec a
    cp $ff
    jr nz, :+
    ld a, 13
:   ldh [hCursorX], a
    ret

.right:
    ldh a, [hCursorX]
    inc a
    cp 14
    jr nz, :+
    xor a
:   ldh [hCursorX], a
    ret

.predict:
    jp Predict

.deselect:
    call PrintStartToPredict
    call GetCursorOffs
    ld [hl], 0
    call GetScreenOffs
    wait_vram
    ld [hl], 0
    ret

.select:
    call PrintStartToPredict
    call GetCursorOffs
    ld [hl], 1
    call GetScreenOffs
    wait_vram
    ld [hl], 1
    ret


DisplayCursor:
    ld hl, wShadowOAM

    ldh a, [hCursorY]
    swap a
    rra
    add $10 + 1*8 + 4
    ld [hl+], a

    ldh a, [hCursorX]
    swap a
    rra
    add $08 + 3*8 + 4
    ld [hl+], a

    xor a
    ld [hl+], a
    ld [hl], a

    ret


; Returns wGrid offset based on cursor in HL
; Trashes B and HL
GetCursorOffs:
    ldh a, [hCursorY]
    ld hl, Mult14
    add_A_to_HL
    ld b, [hl]
    ldh a, [hCursorX]
    add b
    ld hl, wGrid
    add_A_to_HL
    ret


GetScreenOffs:
    ld hl, $9823
    ldh a, [hCursorY]
    swap a
    add a
    jr nc, :+
    inc h
:   ld b, a
    ldh a, [hCursorX]
    add b
    add_A_to_HL
    ret


Mult14:
FOR N, 14
    db N*14
ENDR


SECTION "Grid Wram", WRAM0

wGrid:: ds 14*14
.end:


SECTION "Grid Hram", HRAM

hCursorX: db
hCursorY: db
