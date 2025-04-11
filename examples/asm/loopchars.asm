setup: # setup the h
ld a $80
ld h a
ld a $07 # save color
ld b a
jp &color
increment:
inc (hl) # incrment char
jp Z &color # if all chars done then jump to color
jp &increment # else loop
color:
# load color into vram
ld a $02
ld l a
ld a b
inc a # increment color
ld b a
ld (hl) a
# load initial char
ld a $01
ld l a
ld a $32
ld (hl) a
jp &increment