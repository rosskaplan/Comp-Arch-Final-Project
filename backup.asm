.data
file: .asciiz "C:\Users\CCNez_000\Dropbox\Important Stuff\Freshman Spring\ece151\book.txt"      # Name of the file in the //same directory//
dontask: .space 1
textbuffer: .space 0x4FFFF 	#Creates a space for the text
buffer: .space 0xFFFF



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
li $a2, 0x4FFFF      #Specifies length
syscall      # Reads it.

li $t0, 0x000000FF
li $t1, 0x00000040 	#one less than A
li $t2, 0x0000005B	#One more than Z
li $t3, 0x00000060	#One less than a
li $t4, 0x0000007B	#One more than z
li $t5, 0x00000020	#space
li $t6, 0x00000021	#?
li $t7, 0x0000002E	#.
li $t8, 0x0000003F	#!
li $t9, 0x0000000A	#\n

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

beq $s1, $zero, done

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
jr $ra

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
jr $ra

jumpback:
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


