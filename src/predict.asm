INCLUDE "defines.asm"

SECTION "Predict", ROM0

HIDDEN_LAYER_NODES = 16
OUTPUT_LAYER_NODES = 10

InitPredictText::
    xor a
    ldh [hPromptPrediction], a
    jp PrintStartToPredict
 

Predict::
; Clear both NN layers
    xor a
    ld hl, hHiddenLayer
    ld c, hOutputLayer.end-hHiddenLayer
    rst MemsetSmall

; Calculate hidden layer values
    call ApplyHiddenWeights
    call ApplyHiddenBias
    call ApplyHiddenRelu

; Calculate output layer values
    call ApplyOutputWeights
    call ApplyOutputBias

; Display the likeliest value
    call FindPredictedValue
    jp OutputResult


ApplyHiddenWeights:
; The weights are 196 rows of HIDDEN_LAYER_NODES words each
; Each of the hidden layer nodes = the sum of each grid tile's value * a weight
; The grid tiles only have 2 values, 0 (unset) or 1 (set)
; ie no multiplication needed: if a grid tile is set, 
;   add the weights associated with it, to the hidden layer node values
    ld de, wGrid
    ld hl, HiddenLayerWeights
    ld c, 196
    .nextGridEntry:
    ; Skip adding to the hidden layer nodes, if the grid tile is unset
        ld a, [de]
        inc de
        and a
        jr z, .skip

    ; Add in the weight word values
        push bc
        ld c, LOW(hHiddenLayer)

        ld b, HIDDEN_LAYER_NODES
        .nextHiddenNode:
            ldh a, [c]
            add [hl]
            ldh [c], a
            inc hl
            inc c

            ldh a, [c]
            adc [hl]
            ldh [c], a
            inc hl
            inc c

            dec b
            jr nz, .nextHiddenNode

        pop bc
        jr .toNextGridEntry

    .skip:
        ld a, HIDDEN_LAYER_NODES*2
        add_A_to_HL

    .toNextGridEntry:
        dec c
        jr nz, .nextGridEntry

    ret


ApplyHiddenBias:
; The biases are 1 word per hidden layer node. Simply add them on
    ld c, LOW(hHiddenLayer)
    ld b, HIDDEN_LAYER_NODES
    ld hl, HiddenLayerBias
    .nextHiddenNode:
        ldh a, [c]
        add [hl]
        ldh [c], a
        inc hl
        inc c

        ldh a, [c]
        adc [hl]
        ldh [c], a
        inc hl
        inc c

        dec b
        jr nz, .nextHiddenNode
    ret


ApplyHiddenRelu:
; ReLU = each node's value = max(0, value)
    ld c, LOW(hHiddenLayer+1)
    ld b, HIDDEN_LAYER_NODES
    .nextHiddenNode:
    ; If the signed value's sign bit (bit 15) is set, clear the node
        ldh a, [c]
        cp $80
        jr c, .skip

        xor a
        ldh [c], a
        dec c
        ldh [c], a
        inc c

    .skip:
        inc c
        inc c

        dec b
        jr nz, .nextHiddenNode
    ret


ApplyOutputWeights:
; For each hidden node word val, mult by OUTPUT_LAYER_NODES consecutive signed byte vals
; Because of ReLU, we can skip multiplying out nodes with a value of 0,
;   and we can skip checking the node's sign, so the sign of the result
;   is only dependent on the signed byte
    xor a
    ldh [hHiddenWeightIdx], a
    ld c, LOW(hHiddenLayer)
    ld hl, OutputLayerWeights
    .nextHiddenWeight:
    ; Get hidden weight in DE
        ldh a, [c]
        ld e, a
        inc c
        ldh a, [c]
        ld d, a
        inc c

    ; Skip mult+sums if DE=0
        and a
        jr nz, .useHiddenWeight

        ld a, e
        and a
        jr nz, .useHiddenWeight

        ld a, OUTPUT_LAYER_NODES
        add_A_to_HL
        jr .afterHiddenWeight

    .useHiddenWeight:
        push bc

        ld c, LOW(hOutputLayer)

        .nextOutputWeight:
        ; Save 'is negative', and do unsigned 8-bit * 16-bit
            xor a
            ldh [hMultIsNegative], a

            ld a, [hl+]
            cp $80
            jr c, .afterNegCheck

            ldh [hMultIsNegative], a
            cpl
            inc a

        .afterNegCheck:
            push hl
            call Mult8by16

        ; Convert if negative
            ld b, a
            ldh a, [hMultIsNegative]
            and a
            jr z, .addMultResult

            ld a, l
            cpl
            inc a
            ld l, a
            and a

            ld a, h
            cpl
            jr nz, :+
            inc a
        :   ld h, a
            and a

            ld a, b
            cpl
            jr nz, :+
            inc a
        :   ld b, a

        .addMultResult:
            ldh a, [c]
            add l
            ldh [c], a
            inc c

            ldh a, [c]
            adc h
            ldh [c], a
            inc c

            ldh a, [c]
            adc b
            ldh [c], a
            inc c

        ; Check if we're done
            pop hl
            ld a, c
            cp LOW(hOutputLayer.end)
            jr nz, .nextOutputWeight

    ; Get back C = LOW(hHiddenLayer+2x)
        pop bc

    .afterHiddenWeight:
    ; Do next hidden layer node * 10 output weights
        ldh a, [hHiddenWeightIdx]
        inc a
        cp HIDDEN_LAYER_NODES
        ret z

        ldh [hHiddenWeightIdx], a
        jr .nextHiddenWeight


; Multiply A by DE
; Return result in A:HL
; Trashes B
Mult8by16:
    ld b, 8
    ld hl, 0
    .nextBit:
        add hl, hl
        rl a
        jr nc, :+
        add hl, de
    :   dec b
        jr nz, .nextBit

    ret


ApplyOutputBias:
; The biases are 1 24-bit value per hidden layer node. Simply add them on
    ld c, LOW(hOutputLayer)
    ld b, OUTPUT_LAYER_NODES
    ld hl, OutputLayerBias
    .nextHiddenNode:
        ldh a, [c]
        add [hl]
        ldh [c], a
        inc hl
        inc c

        ldh a, [c]
        adc [hl]
        ldh [c], a
        inc hl
        inc c

        ldh a, [c]
        adc [hl]
        ldh [c], a
        inc hl
        inc c

    ; `dl` is actually 4 bytes, so skip the highest byte
        inc hl

        dec b
        jr nz, .nextHiddenNode
    ret


FindPredictedValue:
; todo: do an actual probability distribution
; This algorithm simply finds the max value, ignoring negative values
; Ideally, it would understand each value's probability, and even display
;   'uncertain' if none of the values has a high chance of matching the image
    xor a
    ldh [hMaxIdx], a
    ld b, a ; curr index
    ld l, a
    ld de, 0 ; L:DE = max value
    ld c, LOW(hOutputLayer+2)

    .nextOutput:
        ldh a, [c]
        push bc

        cp $80
        jr nc, .skip

    ; Compare current 24-bit value against L:DE
        cp l
        jr c, .skip
        jr z, :+
        jr .setMax

    :   dec c
        ldh a, [c]
        cp d
        jr c, .skip
        jr z, :+
        jr .setMax

    :   dec c
        ldh a, [c]
        cp e
        jr c, .skip

    .setMax:
    ; Set a new max value, L:DE, and a new max index
        pop bc
        ldh a, [c]
        ld l, a
        dec c
        ldh a, [c]
        ld d, a
        dec c
        ldh a, [c]
        ld e, a

        ld a, b
        ldh [hMaxIdx], a

        ld a, c
        add 5

        jr .toNextOutput

    .skip:
        pop bc
        ld a, c
        add 3

    .toNextOutput:
        inc b
        ld c, a
        cp LOW(hOutputLayer.end)
        jr c, .nextOutput

    ret


OutputResult:
    ld b, 20
    ld de, $9800 + $20*16
    call ClearText

    ld de, $9800 + $20*16
    ld hl, .text_predict
    call PrintCenteredText

; DE = dest to put number
    dec e
    ldh a, [hMaxIdx]
    add $30
    ld b, a
    wait_vram
    ld a, b
    ld [de], a

; Predict text no longer displayed
    xor a
    ldh [hPromptPrediction], a

    ret

.text_predict:
    db "Prediction: _", 0


PrintStartToPredict::
; Don't print the predict text if already prompted
    ldh a, [hPromptPrediction]
    and a
    ret nz

    inc a
    ldh [hPromptPrediction], a

; Display text
    ld de, $9800 + $20*16
    ld hl, .text_prompt
    jp PrintCenteredText

.text_prompt:
    db "START to predict", $00


INCLUDE "res/model.asm"


SECTION "Predict Hram", HRAM

hHiddenLayer: ds HIDDEN_LAYER_NODES*2
hOutputLayer: ds OUTPUT_LAYER_NODES*3
.end:

hHiddenWeightIdx: db
hMultIsNegative: db
hMaxIdx: db
hPromptPrediction: db
