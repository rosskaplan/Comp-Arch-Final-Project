.data
file: .asciiz "C:\Users\CCNez_000\Dropbox\Important Stuff\Freshman Spring\ece151\book.txt"
buffer: .space 5
textbuffer: .space 0x4FFF0 	#Creates a space for the text
wordbuffer: .space 0x4FFF0

.text

.globl main
main:

li $v0, 13      # Prepare to open file.
la $a0, file      # Specifies the file.
li $a1, 0		#unused
li $a2, 0		#unused
syscall      # Puts the file descriptor in $v0

move $a0, $v0
li $v0, 14    #Prepares file to be read
la $a1, textbuffer      #Specifies buffer
li $a2, 0x4FFF0      #Specifies length
syscall      # Reads it.

li $t0, 0x000000FF	#For isolating bits
li $t1, 0x00000040 	#one less than A
li $t2, 0x0000005B	#One more than Z
li $t3, 0x00000060	#One less than a
li $t4, 0x0000007B	#One more than z
li $t5, 0x00000020	#space
li $t6, 0x00000021	#?
li $t7, 0x0000002E	#.
li $t8, 0x0000003F	#!
li $t9, 0x0000000A	#\n

la $s6, wordbuffer

add $v0, $v0, $a1

nextbyte:
lw $s0, 0($a1)
addi $a1, $a1, 4
addi $s8, $zero, 0
bgt $a1, $v0, done

nextchar:
srlv $s1, $s0, $s8
and $s1, $s1, $t0
jal lettertest
jal punctest
jal spacetest

addi $s8, $s8 8
beq $s8, 32, nextbyte
j nextchar

###########################

lettertest:
bgt $s1, $t3, checklower
spaghetti:
bgt $s1, $t1, checkupper
jr $ra

checklower:
blt $s1, $t4, letteradd
j spaghetti

checkupper:
blt $s1, $t2, letteradd
jr $ra

letteradd:
addi $s2, $s2, 1
addi $s7, $zero, 1

sb $s1, 0($s6)
addi $s6, $s6, 1

jr $ra

############################

spacetest:
beq $s7, $zero, jumpback
beq $s1, $t5, spaceadd
beq $s1, $t9, spaceadd
jr $ra

spaceadd:
addi $s3, $s3, 1
addi $s7, $zero, 0
j checkifunique


############################

punctest:
beq $s7, $zero, jumpback
beq $s1, $t6, puncadd
beq $s1, $t7, puncadd
beq $s1, $t8, puncadd
jr $ra

puncadd:
addi $s4, $s4, 1
addi $s7, $zero, 0
j checkifunique

jumpback:
jr $ra

checkifunique:
li $a2, 0x10
div $s6, $a2
mfhi $a2
sub $a2 $s6, $a2
la $t0, wordbuffer

loop:
addi $t0, $t0, 0x10
lw $t1, 0($t0)
beq $t1, $zero, isunique
lw $t5, 0($a2)
bne $t1, $t5, loop
lw $t2, 1($t0)
lw $t6, 1($a2)
bne $t2, $t6, loop
lw $t3, 2($t0)
lw $t7, 2($a2)
bne $t3, $t7, loop
lw $t4, 3($t0)
lw $t8, 3($a2)
bne $t4, $t8, loop
j notunique

isunique:
li $a2, 0x10
div $s6, $a2
mfhi $a2
li $t9, 16
sub $a2, $t9, $a2
add $s6, $s6, $a2

li $t0, 0x000000FF	#For isolating bits
li $t1, 0x00000040 	#one less than A
li $t2, 0x0000005B	#One more than Z
li $t3, 0x00000060	#One less than a
li $t4, 0x0000007B	#One more than z
li $t5, 0x00000020	#space
li $t6, 0x00000021	#?
li $t7, 0x0000002E	#.
li $t8, 0x0000003F	#!
li $t9, 0x0000000A	#\n

jr $ra

notunique:

addi $s6, $a2, 0
sw $zero, 0($a2)
sw $zero, 16($a2)
sw $zero, 32($a2)
sw $zero, 48($a2)

li $t0, 0x000000FF	#For isolating bits
li $t1, 0x00000040 	#one less than A
li $t2, 0x0000005B	#One more than Z
li $t3, 0x00000060	#One less than a
li $t4, 0x0000007B	#One more than z
li $t5, 0x00000020	#space
li $t6, 0x00000021	#?
li $t7, 0x0000002E	#.
li $t8, 0x0000003F	#!
li $t9, 0x0000000A	#\n

jr $ra

done:
addi $s4, $s4, 1
add $s0, $s3, $s4

mtc1 $s0, $f0
cvt.s.w $f0, $f0

mtc1 $s2, $f3
cvt.s.w $f3, $f3

mtc1 $s3, $f1
cvt.s.w $f1, $f1

mtc1 $s4, $f2
cvt.s.w $f2, $f2

div.s $f4, $f0, $f2
div.s $f5, $f3, $f0


