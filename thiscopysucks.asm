#This program is written by Cory Nezin and Ross Kaplan
#Most recently edited 4/7/2015
#The purpose of this code is to determine authorship through analysis of linguistic features.

.data
file: .space 0xFF
null: .asciiz ""
textbuffer: .space 0x4FFF0 	#Creates a space for the text
databuffer: .space 0xFF00
datafile: .asciiz "database.txt"
buffer: .space 3
wordbuffer: .space 0x4FFF0


.text

.globl main
main:

li $v0, 8 #read string
la $a0, file
li $a1, 0x100
syscall

#all of the following code before "open" is to replace the newline from console with a null.

addi $t3, $zero, 0x0a
add $t1, $zero, $a0

nullify:
lw $t0, 0($t1)

andi $t2, $t0, 0xFF
beq, $t2, $t3, loadnull1
srl $t0, $t0, 8
andi $t2, $t0, 0xFF
beq, $t2, $t3, loadnull2
srl $t0, $t0, 8
andi $t2, $t0, 0xFF
beq, $t2, $t3, loadnull3
srl $t0, $t0, 8
andi $t2, $t0, 0xFF
beq, $t2, $t3, loadnull4
addi $t1, $t1, 4
j nullify

loadnull1:
lw $t0, 0($t1)
li $t4, 0xFFFFFF00
and $t0, $t0, $t4
sw $t0, 0($t1)
j open
loadnull2:
lw $t0, 0($t1)
li $t4, 0xFFFF0000
and $t0, $t0, $t4
sw $t0, 0($t1)
j open
loadnull3:
lw $t0, 0($t1)
li $t4, 0xFF000000
and $t0, $t0, $t4
sw $t0, 0($t1)
j open
loadnull4:
lw $t0, 0($t1)
li $t4, 0x00000000
and $t0, $t0, $t4
sw $t0, 0($t1)
j open

open:

####### These two syscalls open the database
li $v0, 13      # Prepare to open file.
la $a0, datafile
li $a1, 0		#unused
li $a2, 0		#unused
syscall      # Puts the file descriptor in $v0

move $a0, $v0

li $v0, 14    #Prepares file to be read
la $a1, databuffer      #Specifies buffer
li $a2, 0xFF00      #Specifies length
syscall      # Reads it.
la $t1, databuffer
li $t1, 0xFF00	#Goes to the end of databuffer
sw $v0, 0($t1)		#Stores the length of the database there for LATER

####### These two syscalls open the book
li $v0, 13      # Prepare to open file.
la $a0, file
li $a1, 0		#unused
li $a2, 0		#unused
syscall      # Puts the file descriptor in $v0

move $a0, $v0
li $v0, 14    #Prepares file to be read
la $a1, textbuffer      #Specifies buffer
li $a2, 0x4FFF0      #Specifies length
syscall      # Reads it.




addi $t9, $zero, 0	#initialize to 0, probably not necessary
la $s6, wordbuffer	#Start of dictionary

add $v0, $v0, $a1	#End of file

nextword:
lw $s0, 0($a1)	#Load the 4 characters
addi $a1, $a1, 4	#Next loop uses 4 characters
addi $s8, $zero, 0	#reset s8
bgt $a1, $v0, done	#Stop when you get to the end of the file

nextchar:
srlv $s1, $s0, $s8	#put the next character in s1
andi $s1, $s1, 0xFF	#isolate it

jal lettertestLOWER	#Subroutine which determines if the character is a letter (input is s1)
jal punctest	#Subroutine which determines if the character is punctuation (input is s1)
jal spacetest	#Subroutine which determines if the character is a space or newline (input is s1)
jal numbertest	#Subroutine which determines if the character is a digit (input is s1)

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
addi $t8 $zero, 0 	#reset it.

li $a2, 0x10	#Words in the dictionary are 0x10 characters long
div $s6, $a2	#difference between current position and beginning of word stored in HI
mfhi $a2		#get that and put it in a2
sub $a2 $s6, $a2	#subtract to get to the beginning of the word so we can compare it.

#The following wipes it all clean and puts the dictionary in the right place

addi $s6, $a2, 0
sw $zero, 0($a2)
sw $zero, 4($a2)
sw $zero, 8($a2)
sw $zero, 12($a2)
addi $s6, -16

j skip	#No need for other tests on this character

###########################

lettertestLOWER:

li $t1, 0x00000040 	#one less than A
li $t2, 0x0000005B	#One more than Z
li $t3, 0x00000060	#One less than a
li $t4, 0x0000007B	#One more than z

bgt $s1, $t3, checklower	#check if it COULD be lower case letter (need two checks to confirm)
j lettertestUPPER	#If it's not lower case, it might be upper case

checklower:
blt $s1, $t4, letteradd
j lettertestUPPER

lettertestUPPER:
bgt $s1, $t1, checkupper
jr $ra

checkupper:
blt $s1, $t2, makelower	#we only want lower case so we can easily compare words.
j $ra

makelower:	#adding 32 results in a conversion to lower case
addi $s1, $s1, 32
j letteradd

letteradd:
bgt $t9, $zero, skip	#if there is a digit in the word, don't count it (this should probably be moved somewhere further up)
addi $s2, $s2, 1
addi $s7, $zero, 1

sb $s1, 0($s6)	#Save the character to the dictionary
addi $s6, $s6, 1	#s6 is the total letter count for the whole text
addi $t8,  $t8, 1	#t8 represents the amount of characters in the word SO FAR.  We need to subtract this if we encounter a digit later in the word

j skip

############################

spacetest:

li $t1, 0x00000020	#space
li $t2, 0x0000000A	#\n

beq $s7, $zero, skip	#If there was just a space or punctuation, this character doesn't matter, skip it!
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
addi $s4, $s4, 1	#s4 is number of periods
addi $s7, $zero, 0	#most recent character is space/punc
addi $t9, $zero, 0	#No number in the current word now
j checkifunique		#This subroutine checks if the word just loaded is unique


checkifunique:
li $a2, 0x10	#Words in the dictionary are 0x10 characters long
div $s6, $a2	#difference between current position and beginning of word stored in HI
mfhi $a2		#get that and put it in a2
sub $a2 $s6, $a2	#subtract to get to the beginning of the word so we can compare it.

la $t0, wordbuffer
addi $t0, $t0, -16	#So it starts out at 0

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
addi $s5, $s5, 1
#This stuff just wipes the current word out because it is not unique.

addi $s6, $a2, 0
sw $zero, 0($a2)
sw $zero, 4($a2)
sw $zero, 8($a2)
sw $zero, 12($a2)

jr $ra

done:
addi $s4, $s4, 1
add $s0, $s3, $s4
sub $s5, $s0, $s5

mtc1 $s0, $f0	#moves total amount of words to an fp register
cvt.s.w $f0, $f0	#converts it from int to fp

mtc1 $s2, $f3
cvt.s.w $f3, $f3

mtc1 $s3, $f1
cvt.s.w $f1, $f1

mtc1 $s4, $f2
cvt.s.w $f2, $f2

mtc1 $s5, $f6
cvt.s.w $f6, $f6

div.s $f4, $f0, $f2 # Average words per sentece
div.s $f5, $f3, $f0	# Average characters per word
div.s $f7, $f6, $f0	# Fraction of unique words in the text

################################################
#The following section is for analyzing the database.

addi $s2, $zero, 0
addi $s3, $zero, 0

la $a1, databuffer	#beginning of database
li $t0, 0xFF00
add $a2, $a1, $t0	#End of database, location of the length of the database from EARLIER
lw $v0, 0($a2)		#v0 now holds the length of database
add $v0, $v0, $a1 	#v0 is now the location of the end of the database

addi $t0, $zero, 0x2c 	#represents a comma
addi $t1, $zero, 0x2F	#Numbers start right after this
addi $t2, $zero, 0x3A	#Numbers end rigt before this
addi $t3, $zero, 1,000,000 #10^6, 6 digits maximum accuracy
addi $t4, $zero, 1	#field number 1
addi $t5, $zero, 2	#field number 2
addi $t6, $zero, 0x2E	#decimal point

DATAnextword:
lw $s0, 0($a1)	#Load the 4 characters
addi $a1, $a1, 4	#Next loop uses the next 4 characters
bgt $a1, $v0, DATAdone	#Stop when you get to the end of the file

DATAnextchar:
srlv $s1, $s0, $s8	#put the next character in s1
andi $s1, $s1, 0xFF	#isolate it

beq $s1, $t0, fieldUP	#increases the field number (goes to the next "section" in the database) returns s7 as the field number
beq $s7, $t4, addfirstfield
beq $s7, $t5, addsecondfield
beq $s1, $t6, fixdecimal

addi $s8, $s8 8		#so the next shift will provide the correct character
beq $s8, 32, nextword	#Once you've read 4 characters, go on to the next byte
j DATAnextchar	#Otherwise go to the next character

#############################################
fixdecimal:
addi $s4, $zero, $s3	#s4 now contains the amount of digits to the left of the decimal

fieldUP
beq $s7, $t4, convertfloat1	#converts average characters per word
beq $s7, $t5, convertfloat2	#converts average words per sentence
addi $s7, $s7, 1
j DATAnextchar

exponentiate:
mult $t8, $t8, $t7
addi $s4, $s4, -1
bne $s4, $zero, exponentiate
jr $ra

######################################################

convertfloat1:
sub $s4, $s3, $s4	#number of digits to the right of the decimal
addi $t8, $zero, 1	#used in exponentiate	
addi $t7, $zero, 10	#used in exponentiate
jr exponentiate	#After this subroutine, t8 will be 10^s4

mtc1 $s2, $f31	this is the unaligned number
cvt.s.w $f31, $f31	#converts it from int to fp

mtc1 $s4, $f30	this is the amount of digits.
cvt.s.w $f30, $f30	#converts it from int to fp

div.s $f29, $f31, $f30	#f29 now contains the correct floating point value.
j Datanextchar

addfirstfield:
addi $s1 -0x30 #converts ascii to integer
mult $s1, $s1, $t3	#Start of the "power series" for number (x10^6 + y10^5 + z10^4... etc)
div $t3, $t3, 10	#lo = t1/10
mflo $t3	#t1 = t1/10
add $s2, $s2, $s1
addi $s3, $s3, 1	#Number of digits counted so far - later used to "shift" the power series to the correct position
j DATAnextchar

######################################################

convertfloat2:
sub $s4, $s3, $s4	#number of digits to the right of the decimal
addi $t8, $zero, 1	#used in exponentiate	
addi $t7, $zero, 10	#used in exponentiate
jr exponentiate	#After this subroutine, t8 will be 10^s4

mtc1 $s2, $f31	this is the unaligned number
cvt.s.w $f31, $f31	#converts it from int to fp

mtc1 $s4, $f30	this is the amount of digits.
cvt.s.w $f30, $f30	#converts it from int to fp

div.s $f28, $f31, $f30	#f29 now contains the correct floating point value.
j Datanextchar

addsecondfield:
addi $s1 -0x30 #converts ascii to integer
mult $s1, $s1, $t3	#Start of the "power series" for number (x10^6 + y10^5 + z10^4... etc)
div $t3, $t3, 10	#lo = t1/10
mflo $t3	#t1 = t1/10
add $s2, $s2, $s1
addi $s3, $s3, 1	#Number of digits counted so far - later used to "shift" the power series to the correct position
j DATAnextchar

DATAdone:

li $v0, 10      #exit
syscall


