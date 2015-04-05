.data
file: .asciiz "C:\Users\CCNez_000\Dropbox\Important Stuff\Freshman Spring\ece151\book.txt"      # Name of the file in the //same directory//
buffer: .space 0x4FFFF #Creates a space in user data

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
la $a1, buffer      #Specifies buffer
li $a2, 0x4FFFF      #Specifies length
syscall      # Reads it.

addi $a1, $a1, 1      #Aligns memory

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
j $ra

checklower:
blt $s1, $t4, letteradd
j spaghetti

checkupper:
blt $s1, $t2, letteradd
j $ra

letteradd:
addi $s2, $s2, 1
addi $s7, $zero, 1
j $ra

############################

spacetest:
beq $s7, $zero, jumpback
beq $s1, $t5, spaceadd
j $ra

spaceadd:
addi $s3, $s3, 1
addi $s7, $zero, 0
j $ra

############################

punctest:
beq $s7, $zero, jumpback
beq $s1, $t6, puncadd
beq $s1, $t7, puncadd
beq $s1, $t8, puncadd
beq $s1, $t9, puncadd
j $ra

puncadd:
addi $s4, $s4, 1
addi $s7, $zero, 0
j $ra

jumpback:
j $ra

done:
add $s0, $s3, $s4