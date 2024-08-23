start:
ld a $60
ld b a
ld a $ff
and a b
jp &start