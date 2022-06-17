# This code assumes the use of the "Bitmap Display" tool.
#
# Tool settings must be:
#   Unit Width in Pixels: 32
#   Unit Height in Pixels: 32
#   Display Width in Pixels: 512
#   Display Height in Pixels: 512
#   Based Address for display: 0x10010000 (static data)
#
# In effect, this produces a bitmap display of 16x16 pixels.


	.include "bitmap-routines.asm"

	.data
TELL_TALE:
	.word 0x12345678 0x9abcdef0	# Helps us visually detect where our part starts in .data section
KEYBOARD_EVENT_PENDING:
	.word	0x0
KEYBOARD_EVENT:
	.word   0x0
BOX_ROW:
	.word	0x0
BOX_COLUMN:
	.word	0x0

	.eqv LETTER_a 97
	.eqv LETTER_d 100
	.eqv LETTER_w 119
	.eqv LETTER_s 115
    .eqv SPACE    32
	.eqv BOX_COLOUR 0x0099ff33
	
	.globl main
	
	.text	
	
main:


	# initialize variables
	
	li $t1, 0
	li $k0 , 0
	addi $sp,$sp,-4
	la $s3, 0xffff0000	# control register for MMIO Simulator "Receiver"
	lb $s7, 0($s3)
	ori $s7, $s7, 0x02	# Set bit 1 to enable "Receiver" interrupts (i.e., keyboard)
	sb $s7, 0($s3)

	sw $k1, 0($sp)
	li $a0, 0
	li $a1, 0
	li $a2, BOX_COLOUR
	jal draw_bitmap_box
	li $a0, 0
	li $a1, 0	
	
	lw $k1, 0($sp)
	addi $sp,$sp,4

#Infinite loop function that keeps checking for any input.
check_for_event:

	
	lw $t6, KEYBOARD_EVENT
	beq $t6, 'a' DisplayNumber
	beq $t6, 'd' DisplayNumber
	beq $t6, 'w' DisplayNumber
	beq $t6, 's' DisplayNumber
	beq $t6, ' ' DisplayNumber
	beq $zero, $zero, check_for_event
	
	
	# Should never, *ever* arrive at this point
	# in the code.	

	addi $v0, $zero, 10
	
.data
    .eqv BOX_COLOUR_BLACK 0x00000000 
.text

	addi $v0, $zero, BOX_COLOUR_BLACK
	syscall
	
	
	
	b __kernel_entry 


# Draws a 4x4 pixel box in the "Bitmap Display" tool
# $a0: row of box's upper-left corner
# $a1: column of box's upper-left corner
# $a2: colour of box

#Function that checks what key has been pressed to display the needed square movement.
DisplayNumber:

	la $t2, KEYBOARD_EVENT #Identifying which key is pressed.
	
	lb $t4, 0($t2)
	beq $t4, '\0', check_for_event 
	addi $t2,$t2, 1
	sw $zero, KEYBOARD_EVENT
	
	beq $t4, 'a' Count_a
	beq $t4, 'd' Count_d
	beq $t4, 'w' Count_w
	beq $t4, 's' Count_s
	
	beq $t4, ' ' Count_Space
	
	
#Count (a) to shift the box left.
Count_a:
	
	jal reset_box
	addi $a1,$a1, -1
	jal draw_bitmap_box
	li $k0,0
	b check_for_event
	
#Count (d) to shift the box right.	
Count_d:
	
	jal reset_box
	add  $a1, $a1, 1
	jal draw_bitmap_box
	li $k0,0
	b check_for_event

#Count (w) to shift the box up.
Count_w:
	
	jal reset_box
	addi $a0,$a0, -1
	jal draw_bitmap_box
	li $k0,0
	b check_for_event

#Count (s) to shift the box down.
Count_s:
	
	jal reset_box
	addi $a0, $a0, 1
	jal draw_bitmap_box
	li $k0,0
	b check_for_event

#Count pressed spaces to change box color.
Count_Space:
	
	li $k0,0
	beq $t9, 0 ChangeColor
	li $a2, BOX_COLOUR
	li $t9, 0
	jal draw_bitmap_box
	b check_for_event
					


#Function that erases the old box position by displaying a black box in its previous position.
reset_box:

addi $sp,$sp, -24
addi $t8, $a0,0
sb $t8, 24($sp)
addi $a0,$a0, -1

addi $t0, $ra, 0
sw $t0, 0($sp)
addi $t7,$a1,0
sb $t7, 4($sp)
sw $a2, 8($sp)

li $t0, 0
li $t2, 0
li $t3, 0
addi $a2,$zero, BOX_COLOUR_BLACK

loop_1:

li $t3,0
addi $t2,$t2,1
lb $a1, 4($sp)
beq $t2, 5 terminate
addi $a0,$a0,1

loop_2:

beq $t3, 4 loop_1
sb $t3, 16($sp)
sb $t2, 20($sp)

jal set_pixel

lb $t3, 16($sp)
lb $t2, 20($sp)

addi $a1,$a1,1
addi $t3,$t3,1

b loop_2

terminate:
lb $a0, 24($sp)
lb $a1, 4($sp)
lw $a2, 8($sp)
lw $ra, 0($sp)



addi $sp,$sp,24

      jr $ra

#Function to change the color of the square when shifting or displaying the default color.
draw_bitmap_box:


addi $sp,$sp, -24
addi $t8, $a0,0
sb $t8, 8($sp)
addi $a0,$a0, -1

addi $t0, $ra, 0
sw $t0, 0($sp)
addi $t7,$a1,0

sb $t7, 4($sp)

li $t0, 0
li $t2, 0
li $t3, 0
loop_1.1:

li $t3,0
lb $a1, 4($sp)
addi $t2,$t2,1
beq $t2, 5 terminate_1.1
addi $a0,$a0,1


loop_2.1:

beq $t3, 4 loop_1.1
sb $t3, 16($sp)
sb $t2, 20($sp)

jal set_pixel

lb $t3, 16($sp)
lb $t2, 20($sp)
addi $a1,$a1,1
addi $t3,$t3,1

b loop_2.1

terminate_1.1:
lb $a0, 8($sp)
lb $a1, 4($sp)
lw $ra, 0($sp)
addi $sp,$sp,24

      jr $ra


#Function to change the color of the square when space bar is pressed.
ChangeColor:

addi $sp,$sp, -24
addi $t9, $t9, 1
addi $t8, $a0,0
sb $t8, 24($sp)
addi $a0,$a0, -1

addi $t0, $ra, 0
sw $t0, 0($sp)
addi $t7,$a1,0
sb $t7, 4($sp)
sw $a2, 8($sp)

li $t0, 0
li $t2, 0
li $t3, 0

lw $a2, UVic_ID_Color #Storing the unique color associated with my UVic ID.

loop_1.2:

li $t3,0
addi $t2,$t2,1
lb $a1, 4($sp)
beq $t2, 5 terminate_2
addi $a0,$a0,1

loop_2.2:

beq $t3, 4 loop_1.2
sb $t3, 16($sp)
sb $t2, 20($sp)

jal set_pixel

lb $t3, 16($sp)
lb $t2, 20($sp)

addi $a1,$a1,1
addi $t3,$t3,1

b loop_2.2

terminate_2:
lb $a0, 24($sp)
lb $a1, 4($sp)
lw $ra, 0($sp)

addi $sp,$sp,24

      jr $ra


	.kdata

	.ktext 0x80000180


#Interupt handler to ctach any inputs by MIMO keyboard.
__kernel_entry:

	addi $k1,$zero, 0xffff0004 #Address that holds the inputted characters by MIMO keyboard.
	
	li $k0,0
	lb $k0, 0($k1)
	sb $k0, KEYBOARD_EVENT #Storing keyboard input.
	
	
#Exiting the interupt handler.
__exit_exception:
	eret	
	
.data
	
	UVic_ID_Color: .word 0x00947950 #Color associated to my UVic ID.
	
.eqv BOX_COLOUR_WHITE 0x00FFFFFF
