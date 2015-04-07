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
li $v0, 14      #Prepares file to be read
la $a1, buffer      #Specifies buffer
li $a2, 0x4FFFF      #Specifies length
syscall      # Reads it.

addi $a1, $a1, 1      #Aligns memory

#Produces number which are used to isolate character bits
li $t0, 0x000000FF
li $t1, 0x0000FF00
li $t2, 0x00FF0000
li $t3, 0xFF000000
#letters start in ascii at 0x40 #DOES NOT ACCOUNT FOR SOME SPECIAL CHARS
li $t4, 0x00000040
#space is 0x20, punctuation is represented by 21, 2E, 3F
li $t5, 0x00000020
li $s1, 0x21
li $t7, 0x2E
li $t8, 0x3F
li $t9, 0x0a

addi $t6, $zero, 0x00
addi $a2, $zero, 0
# we go to "nextbyte" when we have finished reading one byte of data

srl $v0, $v0, 2
nextbyte:
beq $a2, $v0, done
lw $s0, 0($a1)      #Load the next byte of data in
addi $a2, $a2, 1
addi $a1, $a1, 4      # i=i+4      #increases the "index" by a byte size

#in char n the code analyzes the number to check what type of character it is

char1:
and $s5, $s0, $t0		#This isolates the char we want.
jal lettertest1		#This is a subroutine that tests if it's a letter
jal spacetest1		#Same idea but for the space character
jal puncttest1		#Same idea but for ? . ! \n
beq $s5, $zero, done

char2:
and $s4, $s0, $t1
srl $s4, $s4, 8		#This is used to get the number in the far right position of the word
jal lettertest2
jal spacetest2
jal puncttest2
beq $s4, $zero, done

char3:
and $s3, $s0, $t2
srl $s3, $s3, 16
jal lettertest3
jal spacetest3
jal puncttest3
beq $s3, $zero, done

char4:
and $s2, $s0, $t3
srl $s2, $s2, 24
jal lettertest4
jal spacetest4
jal puncttest4
beq $s2, $zero, done

j nextbyte					#Done finding information about the text

#The following blocks are the codes for the previous subroutines:

###########################

lettertest1:
bgt $s5, $t4, letteradd1	#adds a letter, test should be modified for special symbols
j $ra	#If the test fails, go back and check the next thing.

letteradd1:
addi $s6, $s6, 1	#s6 register holds letter count
addi $t6, $zero, 0x00		#t6 represents whether or not the last char was a space or punct
					#if it is >1 then the last char was, this is used in later tests
j char2 			#Checks the next char, no need for other tests.
 
############################
 
spacetest1:
beq $s5, $t5, prev_space_check1		#if it is a space, check to see if the last char was a space or punct.
j $ra	#If it fails, go back and check the next thing.

prev_space_check1:
beq $t6, $zero spaceadd1	#as stated previously t6 represents whether or not the last char was a space or punct
							#We check to see if that's not 0 (>0).  We do this check because we only want to count the amount of spaces
							#Between words so we can determine how many words there are.  
j char2	#If it got here we already know it' a space so we can jump to the next character's test

spaceadd1:
addi $s7, $s7, 1	#add one to the space counter, note that this is not the actual number of spaces for the previously stated reason
addi $t6, $zero, 0x01		#the next test will see that the previous char was a space/punct unless a letter comes next to reset t6
j char2		#Again, no point in testing for other stuff if we already have a space confirmed.

###########################
 
puncttest1:
beq $s5, $s1, prev_punct_check1		#Checks for ?
beq $s5, $t7, prev_punct_check1		#Checks for .
beq $s5, $t8, prev_punct_check1		#Checks for !
beq $s5, $t9, prev_punct_check1		#Checks for new line
j $ra	#Note that this is equivalent to going to the next character test

prev_punct_check1:
beq $t6, $zero, punctadd1	#We dont want to count multiple punctuation in a row as multiple sentences.
j $ra

punctadd1:
addi $s8, $s8, 1  #Punctuation counter
addi $t6, $zero, 0x01
j $ra

###########################


#The following are very similar (with one exception at the end) tests for the other characters


###########################

lettertest2:
bgt $s4, $t4, letteradd2
j $ra

letteradd2:
addi $s6, $s6, 1
addi $t6, $zero, 0x00
j char3
 
############################
 
spacetest2:
beq $s4, $t5, prev_space_check2
j $ra

prev_space_check2:
beq $t6, $zero, spaceadd2
j $ra

spaceadd2:
addi $s7, $s7, 1
addi $t6, $zero, 0x01
j char3

###########################
 
puncttest2:
beq $s4, $s1, prev_punct_check2
beq $s4, $t7, prev_punct_check2
beq $s4, $t8, prev_punct_check2
beq $s4, $t9, prev_punct_check2

j $ra

prev_punct_check2:
beq $t6, $zero, punctadd2
j $ra

punctadd2:
addi $s8, $s8, 1
addi $t6, $zero, 0x01
j $ra


############################################################################################################

lettertest3:
bgt $s3, $t4, letteradd3
j $ra

letteradd3:
addi $s6, $s6, 1
addi $t6, $zero, 0x0
j char4
 
############################
 
spacetest3:
beq $s3, $t5, prev_space_check3
j $ra

prev_space_check3:
beq $t6, $zero, spaceadd3
j $ra

spaceadd3:
addi $s7, $s7, 1
addi $t6, $zero, 0x01
j char4

###########################
 
puncttest3:
beq $s3, $s1, prev_punct_check3
beq $s3, $t7, prev_punct_check3
beq $s3, $t8, prev_punct_check3
beq $s3, $t9, prev_punct_check3

j $ra

prev_punct_check3:
beq $t6, $zero, punctadd3
j $ra

punctadd3:
addi $s8, $s8, 1
addi $t6, $zero, 0x01
j $ra

#######################################################################################################################################

lettertest4:
bgt $s2, $t4, letteradd4
j $ra

letteradd4:
addi $s6, $s6, 1
addi $t6, $zero, 0x0
j nextbyte	#bytedone means we're at the end of our byte and we don't want to do any other tests so skip to the end.
 
############################
 
spacetest4:
beq $s2, $t5, prev_space_check4
j $ra

prev_space_check4:
beq $t6, $zero, spaceadd4
j $ra

spaceadd4:
addi $s7, $s7, 1
addi $t6, $zero, 0x01
j nextbyte

###########################
 
puncttest4:
beq $s2, $s1, prev_punct_check4
beq $s2, $t7, prev_punct_check4
beq $s2, $t8, prev_punct_check4
beq $s2, $t9, prev_punct_check4

j $ra

prev_punct_check4:
beq $t6, $zero, punctadd4
j $ra

punctadd4:
addi $s8, $s8, 1
addi $t6, $zero, 0x01
j nextbyte

done:
addi $s8, $s8, 1
addi $s6, $s6, 1	#The char count is generally off by one because of issues counting the first letter
add $s0, $s7, $s8

li $v0, 16      
la $a1, file     
syscall      