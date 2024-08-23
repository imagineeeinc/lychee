andtest:
ld a $60
ld b a
ld a $ff
and a b
ld $A000 a
xortest:
ld a $60
ld b a
ld a $ff
xor a b
ld $A001 a
ortest:
ld a $30
ld b a
ld a $60
or a b
ld $A002 a
exit:
jp &exit