# CS 21 Lab 4 -- S2 AY 2022-2023
# Marius Barcenas -- XX/05/2023
# mp1c.asm -- Tetrisito Implementation

# GP ALLOCATION
# 0(4) - file descriptor (development ver)
# 4(4) - number of blocks
# 8(2 * 4) - initial board registers
# 16(2 * 4) - final board registers
# 24+(2 * 4) - block registers

.data
filename:	.asciiz "test.in"
yes:	.asciiz "YES"
no:	.asciiz "NO"
cont:	.align 2
	.space 256

# Reads a certain number of bytes from the input file and stores it into the buffer address
.macro	read_file(%register, %bytes)
#	lw	$a0, 0($gp)
	addi	$a0, $0, 0		# file descriptor for stdin
	la	$a1, cont		# buffer address
	addi	$a2, %register, %bytes	# number of bytes to take
	
	addi	$v0, $0, 14
	syscall			# read from file
.end_macro

.macro	newline()
	addi	$sp, $sp, -8
	sw	$a0, 0($sp)
	sw	$v0, 4($sp)
	
	addi	$a0, $0, 10
	addi	$v0, $0, 11
	syscall
	
	lw	$v0, 4($sp)
	lw	$a0, 0($sp)
	addi	$sp, $sp 8
.end_macro

.macro	space()
	addi	$sp, $sp, -8
	sw	$a0, 0($sp)
	sw	$v0, 4($sp)
	
	addi	$a0, $0, 32
	addi	$v0, $0, 11
	syscall
	
	lw	$v0, 4($sp)
	lw	$a0, 0($sp)
	addi	$sp, $sp 8
.end_macro

.macro	print_register(%register)
	addi	$sp, $sp, -8
	sw	$a0, 0($sp)
	sw	$v0, 4($sp)

	move	$a0, %register
	addi	$v0, $0, 34
	syscall
	
	lw	$v0, 4($sp)
	lw	$a0, 0($sp)
	addi	$sp, $sp 8
.end_macro

.macro	save()
	addi	$sp, $sp, -32
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
.end_macro

.macro	return()
	lw	$s6, 28($sp)
	lw	$s5, 24($sp)
	lw	$s4, 20($sp)
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 32
	
	jr	$ra
.end_macro

.macro	save_temp()
	addi	$sp, $sp, -32
	sw	$t0, 0($sp)
	sw	$t1, 4($sp)
	sw	$t2, 8($sp)
	sw	$t3, 12($sp)
	sw	$t4, 16($sp)
	sw	$t5, 20($sp)
	sw	$t6, 24($sp)
	sw	$t7, 28($sp)
.end_macro

.macro	return_temp()
	lw	$t7, 28($sp)
	lw	$t6, 24($sp)
	lw	$t5, 20($sp)
	lw	$t4, 16($sp)
	lw	$t3, 12($sp)
	lw	$t2, 8($sp)
	lw	$t1, 4($sp)
	lw	$t0, 0($sp)
	addi	$sp, $sp, 32
.end_macro

.text
main:
#	la	$a0, filename		# opens the file based on filename in .data directive
#	addi	$a1, $0, 0
#	addi	$a2, $0, 0
#	addi	$v0, $0, 13		# open file
#	syscall
#	sw	$v0, 0($gp)
	
	la	$s0, cont		# save the buffer address
	
	# INPUTS #
	li	$s6, 0x20080200	# magic number
	addi	$a0, $0, 6
	jal	create_board
	
	sll	$v0, $v0, 3
	sll	$v1, $v1, 3
	or	$v0, $v0, $s6
	or	$v1, $v1, $s6
	sw	$v0, 8($gp)		# initial board reg 1
	sw	$v1, 12($gp)		# initial board reg 2
	
	addi	$a0, $0, 6
	jal	create_board
	
	sll	$v0, $v0, 3
	sll	$v1, $v1, 3
	or	$v0, $v0, $s6
	or	$v1, $v1, $s6
	sw	$v0, 16($gp)		# final board reg 1
	sw	$v1, 20($gp)		# final board reg 2
	
	read_file($0, 3)
	lb	$s5, 0($s0)		# get number of blocks
	addi	$s5, $s5, -48		# ascii to num conversion
	sw	$s5, 4($gp)
	
	addi	$s6, $0, 24		# gp offset for blocks
m_block_loop:
	addi	$s5, $s5, -1		# counter for blocks
	
	addi	$a0, $0, 4
	jal	create_board
	add	$t0, $gp, $s6		# global address for block
	sw	$v0, ($t0)		# save block reg 1 in global data
	addi	$t0, $t0, 4
	sw	$v1, ($t0)		# save block reg 2 in global data
	
	addi	$s6, $s6, 8		# increment global address
	
	bnez	$s5, m_block_loop

	lw	$a0, 8($gp)
	lw	$a1, 12($gp)
	move	$a2, $0
		
	jal	mama_mo_backtrack
	
	bnez	$v0, m_yes
	la	$a0, no
	j	m_print
m_yes:
	la	$a0, yes
m_print:
	addi	$v0, $0, 4
	syscall
debug:
	
	
exit:
	addi	$v0, $0, 10
	syscall			# exit

### FUNCTIONS ###
# The bread and butter of this whole program
# Arguments: board registers, chosen
# Returns: boolean if board can be reached
mama_mo_backtrack:
	save()
	
	move	$s0, $a0		# board reg 1
	move	$s1, $a1		# board reg 2
	move	$s2, $a2		# chosen registers
	
	lw	$s3, 16($gp)		# final board reg 1
	lw	$s4, 20($gp)		# final board reg 2
	lw	$s5, 4($gp)		# number of blocks
	
	sll	$s5, $s5, 3		# compute for the end of the blocks for use as counter
	addi	$s5, $s5, 24		# ($s5 * 8) + 24
	
	addi	$s6, $0, 0		# result
	
	bne	$s0, $s3, bt_ne1	# if not equal, go to rest of the function
	bne	$s1, $s4, bt_ne1
	addi	$v0, $0, 1		# else, return 1
	j	bt_exit
bt_ne1:
	addi	$t0, $0, 1		# chosen registers tracker mask
	addi	$t1, $0, 24		# gp offset for blocks
bt_main_loop:
	and	$t2, $t0, $s2		# if register's already chosen, continue
	bnez	$t2, bt_continue
	
	add	$t3, $gp, $t1		# gp location for block regs
	
	lw	$t4, 0($t3)		# get block reg 1
	lw	$t5, 4($t3)		# get block reg 2
	
bt_shift_loop:		
	move	$a0, $s0		# drop the current piece
	move	$a1, $s1
	move	$a2, $t4
	move	$a3, $t5
	save_temp()
	jal	drop_piece
	return_temp()
	
	bne	$v0, $s0, bt_recurse	# if next grid != curr grid, continue with recursion
	bne	$v1, $s1, bt_recurse
	j	bt_sl_continue	# else, continue

bt_recurse:
	or	$t2, $t0, $s2		# add register to chosen
	
	move	$a0, $v0		# recurse with the next grid and chosen registers
	move	$a1, $v1
	move	$a2, $t2
	save_temp()
	jal	mama_mo_backtrack
	return_temp()
	
	or	$s6, $s6, $v0		# result or backtrack()
	bnez	$s6, bt_return_true	# if result, return true
	j	bt_sl_continue	# else, continue
	
bt_return_true:
	addi	$v0, $0, 1		# return true
	j	bt_exit

bt_sl_continue:
	andi	$t6, $t5, 0x3FF	# last column mask
	
	bnez	$t6, bt_continue	# if can no longer shift, end loop
	
	move	$a0, $t4		# shift once
	move	$a1, $t5
	save_temp()
	jal	shift_piece
	return_temp()
	move	$t4, $v0
	move	$t5, $v1
	
	j	bt_shift_loop
bt_continue:
	sll	$t0, $t0, 1		# move to next register
	addi	$t1, $t1, 8
	bne	$t1, $s5, bt_main_loop
	
	addi	$v0, $0, 0
bt_exit:
	return()

# Shifts a piece once to the right, if possible
# Arguments: block registers
# Returns: shifted block registers
shift_piece:
	save()
	
	move	$s0, $a0		# block reg 1
	move	$s1, $a1		# block reg 2
	
	li	$s2, 0x3FF		# last column mask
	
	and	$t0, $s0, $s2		# get the last column of reg 1
	sll	$t0, $t0, 20		# shift it to be the first column
		
	srl	$s0, $s0, 10		# move one column over
	srl	$s1, $s1, 10
	
	or	$s1, $s1, $t0		# add the last column of reg 1 to first column of reg 2
	
	move	$v0, $s0
	move	$v1, $s1
	
	return()

# Drops a piece until it can no longer drop
# Arguments: board registers, block registers
# Returns: updated board registers
drop_piece:
	save()
	
	move	$s0, $a0		# board reg 1
	move	$s1, $a1		# board reg 2
	move	$s2, $a2		# block reg 1
	move	$s3, $a3		# block reg 2
	
	addi	$t2, $0, 0		# number of rows dropped
	li	$t3, 0x00701C07	# top mask
dp_loop:
	and	$t0, $s0, $s2		# check for collision
	and	$t1, $s1, $s3
	
	bnez	$t0, dp_stop		# stop if there's a collision
	bnez	$t1, dp_stop
	
	sll	$s2, $s2, 1		# drop the tetrimino one row
	sll	$s3, $s3, 1
	addi	$t2, $t2, 1
	j	dp_loop		# repeat until collision

dp_stop:
	beqz	$t2, dp_no_drop	# if tetrimino didn't drop, return the board as is
	srl	$s2, $s2, 1		# else move back tetrimino to before it collided
	srl	$s3, $s3, 1
	
	and	$t4, $t3, $s2		# check for out of board bounds
	and	$t5, $t3, $s3
	
	bnez	$t4, dp_no_drop	# if out of board bounds, return the board as is
	bnez	$t5, dp_no_drop
	
	or	$v0, $s0, $s2		# return board with tetrimino included
	or	$v1, $s1, $s3
	
	j	dp_exit
dp_no_drop:
	move	$v0, $s0
	move	$v1, $s1
dp_exit:
	return()

# Creates a board
# Arguments: board size
# Returns: the board registers (implicitly via build_board_row)
create_board:
	save()

	move	$s0, $a0		# board size

	read_file($s0, 2)		# get a row from the input

	addi	$a0, $0, 0		# initial values are 0 for the very first row
	addi	$a1, $0, 0
	addi	$a2, $0, 0
	jal	build_row		# build the first row

	addi	$s1, $0, 0		# counter
create_loop:
	addi	$s1, $s1, 1		# increment counter, this will be used for shifting
	move	$t0, $v0
	move	$t1, $v1

	read_file($s0, 2)		# get a row from the input

	move	$a0, $s1
	move	$a1, $t0		# use previous outputs as new inputs
	move	$a2, $t1
	jal	build_row		# build a row using the new values
    
	addi	$t2, $s0, -1
	blt	$s1, $t2, create_loop	# loop while counter is less than board size

	return()
	
# Adds a row to the board
# Arguments: buffer address, shift amount, reg 1, reg 2, board size
# Returns: the board registers with added row
build_row:
	save()
	
	la	$s0, cont		# buffer address
	move	$s1, $a0		# shift amount
	move	$s2, $a1		# reg 1
	move	$s3, $a2		# reg 2
	
	addi	$t0, $0, 0		# offset
br_loop:				# do {
	add	$t1, $s0, $t0		# add offset
	lb	$t2, 0($t1)		# get character at offset
	
	bne	$t2, 0x23, br_isdot	# if (character) == '#', proceed
	addi	$t2, $0, 1
	j	br_isdot_
br_isdot:
	addi	$t2, $0, 0		# if (character) != '#'
br_isdot_:
	sb	$t2, 0($t1)		# return parsed value to memory
	addi	$t0, $t0, 1		# increment offset
	blt	$t0, 6, br_loop	# } while (offset < 6)
	
	lb	$t2, 0($s0)
	sll	$t3, $t2, 10		# mask 1: x
	lb	$t2, 1($s0)
	or	$t3, $t3, $t2		# x00 0000 000x
	sll	$t3, $t3, 10
	lb	$t2, 2($s0)
	or	$t3, $t3, $t2		# x 0000 0000 0x00 0000 000x
	sllv	$t3, $t3, $s1		# shift based on argument
	or	$v0, $t3, $s2		# add row to board and return
	
	lb	$t2, 3($s0)
	sll	$t4, $t2, 10		# mask 2: x
	lb	$t2, 4($s0)
	or	$t4, $t4, $t2		# x00 0000 000x
	sll	$t4, $t4, 10		
	lb	$t2, 5($s0)
	or	$t4, $t4, $t2		# x 0000 0000 0x00 0000 000x
	sllv	$t4, $t4, $s1		# shift based on argument
	or	$v1, $t4, $s3		# add row to board and return
	
	return()
