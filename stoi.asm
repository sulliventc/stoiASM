.data
errMsg: .asciiz "Invalid input.\n"
.text

# Convert a string into a 32-bit, two's complement integer
# a0: string address
# a1: base of the string
# v0: int
stringToInt:
		addi 	$sp, $sp, -16 	# Make room on stack for 3 registers
		sw 	$ra, 12($sp) 	# Save $ra on stack
		sw 	$s2, 8($sp) 	# Save $s2 on stack
		sw 	$s1, 4($sp) 	# Save $s1 on stack
		sw 	$s0, 0($sp) 	# Save $s0 on stack
		
		move 	$s0, $a0 	# string address
		move 	$s1, $a1 	# base
		jal 	strlen 		# get length of the string
		move 	$s2, $v0 	# length
		
		move 	$t0, $0 	# digit
		move 	$t1, $0 	# result
		addi 	$t2, $0, 1 	# positionValue
		
		lb 	$t9, 0($s0) 	# get the first byte
		seq 	$t9, $t9, '-' 	# Set the neg flag
		beqz 	$t9, loop1 	# if no flag, start the loop
		addi 	$s0, $s0, 1 	# pop the '-'
		subi 	$s2, $s2, 1 	# Shorten the length
		
	loop1:	bge 	$t0, $s2, end1 	# if digit >= N
		add 	$t3, $s0, $s2 	# string[N]
		sub 	$t3, $t3, $t0 	# string[N - digit]
		subi 	$t3, $t3, 1 	# string[N - Digit - 1]
		lb 	$t4, 0($t3) 	# Grab that byte
		bgt 	$t4, 'F', err 	# Over base 16; error
		bge 	$t4, 'A', char 	# A-F; character
		bgt 	$t4, '9', err 	# Garbage character; error
		bge 	$t4, '0', num 	# 0-9; number
		blt 	$t4, '0', err 	# Garbage character; error
		
	num:	subi 	$t4, $t4, '0' 	# convert to int
		j 	continue 	# done here
		
	char:	subi 	$t4, $t4, 'A' 	# convert to int
		addi 	$t4, $t4, 10 	# move up 10
		j 	continue 	# Entirely unnecessary, but added for symmetry
		
	continue:
		bge 	$t4, $s1, err 	# if outside base range, invalid
		mul 	$t4, $t4, $t2 	# currentDigitValue * positionValue
		add 	$t1, $t1, $t4 	# result + CDV * PV
		mul 	$t2, $t2, $s1 	# update position (positionValue * base)
		addi 	$t0, $t0, 1 	# increment digit
		j 	loop1 		# restart loop
		
	end1:	move 	$v0, $t1 	# move result into return register
		beqz 	$t9, exit 	# if neg flag isn't set, skip negation
		sub 	$t1, $0, $t1 	# negate the number
		move 	$v0, $t1 	# move result into return register again for negation
	exit:	lw 	$s0, 0($sp) 	# restore $s0 from stack
		lw 	$s1, 4($sp) 	# restore $s1 from stack
		lw 	$s2, 8($sp) 	# restore $s2 from stack
		lw 	$ra, 12($sp) 	# restore $ra from stack
		addi 	$sp, $sp, 16 	# restore stack pointer
		jr 	$ra 		# return
		
# Get the length of the string
# a0: string address
# v0: length of string
strlen:		move	$t0, $a0	# cache the string address
	loop2:	lb 	$t1, 0($t0)	# Grab a character at string address
		beq 	$t1, $0, end2	# Null character: Jump to end
		
		addi 	$t0, $t0, 1	# Add 1 to string address
		j 	loop2		# Loop again with new string address
	end2:	move 	$t1, $a0	# Load the string address again
		sub 	$v0, $t0, $t1 	# Subtract string address from 
					# 	incremented address to get character count
		jr 	$ra		# return
	
# Input was invalid. Print error and return 0.
# v0: 0
err:		la 	$a0, errMsg	# load error message addr
		li 	$v0, 4 		# load print string syscall
		syscall 		# print the error message
		li 	$v0, 0 		# load 0 to return register
		j 	exit 		# jump to exit cleanup