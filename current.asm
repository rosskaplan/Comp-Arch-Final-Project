#This program is written by Cory Nezin and Ross Kaplan
#Most recently edited 4/7/2015
#The purpose of this code is to determine authorship through analysis of linguistic features.

.data
file: .asciiz "book.txt"
buffer: .space 7
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

#li $t0, 0x000000FF	#For isolating bits
#li $t1, 0x00000040 	#one less than A
#li $t2, 0x0000005B	#One more than Z
#li $t3, 0x00000060	#One less than a
#li $t4, 0x0000007B	#One more than z
#li $t5, 0x00000020	#space
#li $t6, 0x00000021	#?
#li $t7, 0x0000002E	#.
#li $t8, 0x0000003F	#!
#li $t9, 0x0000000A	#\n
addi $t9, $zero, 0


la $s6, wordbuffer	#Start of dictionary

add $v0, $v0, $a1	#End of file

nextword:
lw $s0, 0($a1)	#Load the 4 characters
addi $a1, $a1, 4	#Next loop uses 4 characters
addi $s8, $zero, 0	#rest s8
bgt $a1, $v0, done	#Stop when you get to the end of the file

nextchar:
srlv $s1, $s0, $s8	#put the next character in s1
andi $s1, $s1, 0xFF	#isolate it

jal numbertest	#Subroutine which determines if the character is a digit (input is s1)
jal lettertestLOWER	#Subroutine which determines if the character is a letter (input is s1)
jal punctest	#Subroutine which determines if the character is punctuation (input is s1)
jal spacetest	#Subroutine which determines if the character is a space or newline (input is s1)

skip:	#skip the rest of the tests if the character has been determined
addi $s8, $s8 8		#so the next shift will provide the correct character
beq $s8, 32, nextword	#Once you've read 4 characters, go on to the next byte
j nextchar	#Otherwise go to the next character

###########################

numbertest:
li $t1, 0x2F	#one less than 0 (lower bound)
li $t2, 0x3A	#one more than 9 (upper bound)
bgt $s1, $t1, checkupperbound
jr $ra
checkupperbound:
blt $s1, $t2, isnumber
j $ra
isnumber:
bgt $s7, $zero, revert #if the previous character was a letter, revert some changes.
j skip	#Otherwise just ignore this little incident

revert:
addi $t9, $zero, 1	#signifiies that there is a number in the current word, doesn't count more letters in the word
addi $s3, $s3, -1	#decreases the amount of spaces by 1 (because spaces are used to count actual words)
sub $s7, $s7, $t8	#t8, as commented later, this keeps track of the amount of characters counted in the current word so far

li $a2, 0x10	#Words in the dictionary are 0x10 characters long
div $s6, $a2	#difference between current position and beginning of word stored in HI
mfhi $a2		#get that and put it in a2
sub $a2 $s6, $a2	#subtract to get to the beginning of the word so we can compare it.

#The following wipes it all clean and puts us in the right place.

addi $s6, $a2, 0
sw $zero, 0($a2)
sw $zero, 4($a2)
sw $zero, 8($a2)
sw $zero, 16($a2)
addi $s6, -16

j skip



###########################

lettertestLOWER:

li $t1, 0x00000040 	#one less than A
li $t2, 0x0000005B	#One more than Z
li $t3, 0x00000060	#One less than a
li $t4, 0x0000007B	#One more than z

bgt $s1, $t3, checklower
j lettertestUPPER

checklower:
blt $s1, $t4, letteradd
j lettertestUPPER

lettertestUPPER:
bgt $s1, $t1, checkupper
jr $ra

checkupper:
blt $s1, $t2, makelower	#we only want lower case so we can easily compare words.
j $ra

makelower:
addi $s1, $s1, 32
j letteradd

letteradd:
bgt $t9, $zero, skip	#if there is a digit in the word, don't count it (this should probably be moved somewhere further up)
addi $s2, $s2, 1
addi $s7, $zero, 1

sb $s1, 0($s6)
addi $s6, $s6, 1
addi $t8,  $t8, 1	#t8 represents the amount of characters in the word SO FAR.  We need to subtract this if we encounter a digit later in the word

j skip

############################

spacetest:

li $t1, 0x00000020	#space
li $t2, 0x0000000A	#\n

beq $s7, $zero, skip
beq $s1, $t1, spaceadd
beq $s1, $t2, spaceadd
jr $ra

spaceadd:
addi $s3, $s3, 1
addi $s7, $zero, 0
addi $t9, $zero, 0
j checkifunique


############################

punctest:

li $t1, 0x00000021	#?
li $t2, 0x0000002E	#.
li $t3, 0x0000003F	#!

beq $s7, $zero, skip
beq $s1, $t1, puncadd
beq $s1, $t2, puncadd
beq $s1, $t3, puncadd
jr $ra

puncadd:
addi $s4, $s4, 1
addi $s7, $zero, 0
addi $t9, $zero, 0
j checkifunique


checkifunique:
li $a2, 0x10	#Words in the dictionary are 0x10 characters long
div $s6, $a2	#difference between current position and beginning of word stored in HI
mfhi $a2		#get that and put it in a2
sub $a2 $s6, $a2	#subtract to get to the beginning of the word so we can compare it.

la $t0, wordbuffer
addi $t0, $t0, -16

loop:
addi $t0, $t0, 16
beq $t0, $a2 isunique
lw $t1, 0($t0)
lw $t5, 0($a2)
bne $t1, $t5, loop
lw $t2, 4($t0)
lw $t6, 4($a2)
bne $t2, $t6, loop
lw $t3, 8($t0)
lw $t7, 8($a2)
bne $t3, $t7, loop
lw $t4, 12($t0)
lw $t8, 12($a2)
bne $t4, $t8, loop
j notunique

isunique:
li $a2, 0x10
div $s6, $a2
mfhi $a2
li $t5, 0x10
sub $a2, $t5, $a2
add $s6, $s6, $a2

jr $ra

notunique:

addi $s6, $a2, 0
sw $zero, 0($a2)
sw $zero, 4($a2)
sw $zero, 8($a2)
sw $zero, 16($a2)

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


