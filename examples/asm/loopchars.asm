setup:
ld a $80
ld h a
ld a $07
ld b a
jp &color
increment:
inc (hl)
jp Z &color
jp &increment
color:
ld a $02
ld l a
ld a b
inc a
ld b a
ld (hl) a
ld a $01
ld l a
ld a $32
ld (hl) a
jp &increment