ld a $01
ld c a
ld a $07
ld e a
ld a $80
ld h a
ld a $00
ld l a
increment:
ld a $32
ld (hl) a
add hl bc
ld a e
ld (hl) a
add hl bc
jp &increment