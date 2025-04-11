ld a $80
ld h a
ld a $02
ld l a
ld a $07
ld (hl) a
ld a $01
ld l a
ld a $19
ld (hl) a
%increment:
inc (hl)
jp &increment
