setup:
# Load color
ld a $80
ld h a
ld a $02
ld l a
ld a $08
ld (hl) a
# Load initial char
ld a $01
ld l a
ld a $30
ld (hl) a
settimer:
# Load timer with 60
ld a $3c
ld Timer a
# Increase charecter on screen
inc (hl)
# Check if charecter is past 9
ld a (hl)
sub a $3a
jp nz &loop
# If past 9 then set to 0
ld a $30
ld (hl) a
loop:
# check if number is 0
ld a Timer
sub a $01
# if 0 then jump to reset timer
jp c &settimer
# else loop
jp &loop