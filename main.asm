#This program is written by Cory Nezin and Ross Kaplan
#Most recently edited 4/17/2015
#The purpose of this code is to determine authorship through analysis of linguistic
#features such as average words per sentence, average characters per word, and percentage of unique words



.data
file: .space 0xFF	#This space is reserved for the user inputted file
null: .asciiz ""	#This is to make sure it gets null terminated
textbuffer: .space 0x4FFF0 	#Creates a space for the author's text
databuffer: .space 0xFF00	#Creates a space for the database
datafile: .asciiz "database.txt"	#Name of the database file
buffer: .space 3	#to allign the next memory
wordbuffer: .space 0x4FFF0	#Creates a space for the "dictionary"
currentauthor: .space 0x1000
bestauthor: .space 0x1000
result1: .asciiz "Average words per sentece = "
result2: .asciiz "Average characters per word = "
result3: .asciiz "Fraction of unique words in the text = "
result4: .asciiz "Number of clauses in the text = "
space: .asciiz "\n\n"


.text

.globl main
main:

li $v0, 8 #read string
la $a0, file	#Gets the addres of the name of the author's text - to be inputted by user
li $a1, 0x100	#Max possible length of the input
syscall

#all of the following code before "open" is to replace the newline from console with a null.

addi $t3, $zero, 0x0a	#t3 is the newline which shows up from the console input
add $t1, $zero, $a0		#sets t1 equal to the starting address of the file name

#a later note explains why words are loaded instead of bytes, however in this case it might have been more useful to use words

nullify:	#This block searches the code for a newline
lw $t0, 0($t1)

andi $t2, $t0, 0xFF	#Each of these four is a check on each byte of the word
beq, $t2, $t3, loadnull1	#If it finds a newline, call a subroutine which replaces it with a null
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
j nullify	#go to the next word (mips word) if there's no newline

loadnull1:	#Each of these will replace the newline with a null - note that it matters which byte of the word it is in so there must be four cases
lw $t0, 0($t1)	#Go to the word which we found the newline in
li $t4, 0xFFFFFF00	#If this loadnull was called then this is the correct pattern for replacement (we don't want to effect the other bytes in the word)
and $t0, $t0, $t4
sw $t0, 0($t1)	#Overwrite the old word with the null terminated word
j open	#Start the actual program
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

#s0 - current mips word
#s1 - The current character being read
#s2 - The total amount of letters read so far
#s3 - The total amount of spaces and newlines
#s4 - The total amount of punctuation - ! . ?
#s5 - The total amount of repeated words
#s6 - The current location in the dictionary
#s7 - If this is zero the most recent character read was a space of punctuation.
#t9 - used as a permenant register, represents the state of there being a digit in the current word
#v0 - used as a permenant register, represents the location of the end of the file
#a0 - used as a permenant register, represents the current location in the file

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

#This makes v0 the length of the file


addi $t9, $zero, 0	#initialize to 0, just in case
la $s6, wordbuffer	#Start of "dictionary

addi $a3, $a1, 0
sll $v1, $v0, 2			
add $v0, $v0, $a1
add $v1, $v1, $a1

addi $v0, $v0, 4		#v0 now represents the end of the file


#Note that the following code for extracting characters may look odd.  Instead of reading the memory byte by byte
#we load in a word at a time and extract each byte individually.  This is mainly an experiment in optimization -
#While it is probably not more optimal in SPIM it may have a faster run time in actual MIPS because memory access
#is one of the largest time wasters, this method calls memory only 1/4th of the amount that would be called doing it byte by byte.

nextword:	#This loop loads the next 'mips' word in the author's text
lw $s0, 0($a1)	#Load the 4 characters into s0
addi $a1, $a1, 4	#Next loop uses the next 4 characters
addi $s8, $zero, 0	#reset s8, s8 is used as a number which determines what character of the word we are looking at
bgt $a1, $v0, done	#Stop when you get to the end of the file

nextchar:
addi $a3, $a3, 4
bgt $a3, $v1, done


srlv $s1, $s0, $s8	#put the next character in s1
andi $s1, $s1, 0xFF	#isolate it and store it in s1

jal semitest #Subroutine which determines if the character is a semi-colon for clause detection
jal lettertestLOWER	#Subroutine which determines if the character is a letter (input is s1)
jal punctest	#Subroutine which determines if the character is punctuation (input is s1)
jal spacetest	#Subroutine which determines if the character is a space or newline (input is s1)
jal numbertest	#Subroutine which determines if the character is a digit (input is s1)


skip:	#skip the rest of the tests if the character has been determined
addi $s8, $s8, 8		#so the next shift will provide the correct character
beq $s8, 32, nextword	#Once you've read 4 characters, go on to the next byte
j nextchar	#Otherwise go to the next character

###########################

numbertest:
li $t1, 0x2F	#one less than 0 (lower bound)
li $t2, 0x3A	#one more than 9 (upper bound)
bgt $s1, $t1, checkupperbound
jr $ra

semitest:
li $t1, 0x3B
beq $s1, $t1, semicount
jr $ra

semicount: 

add $t1, $t1, 1
mtc1 $t1, $f14	#moves total amount of words to an fp register
cvt.s.w $f14, $f14	#converts it from int to fp
xor $t1, $t1, $t1 #wipes $t1 for later use
jr $ra

checkupperbound:
blt $s1, $t2, isnumber
jr $ra

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

j skip	#No need for other tests on this character, it is already determined

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
bgt $t9, $zero, skip	#if there is a digit in the word, don't count it (this should probably be moved somewhere further up to increase efficiency but it's not a common case anyway)
addi $s2, $s2, 1		#s2 is the total amount of letters
addi $s7, $zero, 1

sb $s1, 0($s6)	#Save the character to the dictionary
addi $s6, $s6, 1	#s6 is the "location in the text"
addi $t8,  $t8, 1	#t8 represents the amount of characters in the word SO FAR.  We need to subtract this if we encounter a digit later in the word to undo our mistakes.

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
addi $s7, $zero, 0	#s7 explained in puncadd
addi $t9, $zero, 0	#t9 explained in puncadd
j checkifunique		#Now that a word has been finished, we check to see if it is a repeat of a previous word - for our unique word feature/dictionary


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
addi $s7, $zero, 0	#most recent character is space/punctuation
addi $t9, $zero, 0	#No number in the current word now
j checkifunique		


checkifunique:
li $a2, 0x10	#Words in the dictionary are 0x10 characters long
div $s6, $a2	#difference between current position and beginning of word stored in HI
mfhi $a2		#get that and put it in a2
sub $a2 $s6, $a2	#subtract to get to the beginning of the word so we can compare it.

la $t0, wordbuffer
addi $t0, $t0, -16	#So it starts out at 0

#The following basically compares every unique word to the current word being tested

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
#The following code is executed when we've read the entire file, it does the basic calculations
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

li      $v0, 4
la      $a0, result1
syscall                      # print out "Average words per sentece = "

li      $v0, 2
mov.s    $f12, $f4
syscall                      # print out actual sum

addi $v0, $zero, 4  # print_string syscall
la $a0, space       # load address of the string
syscall

#########
div.s $f5, $f3, $f0	# Average characters per word

li      $v0, 4
la      $a0, result2
syscall                      # print out "Average characters per word = "

li      $v0, 2
mov.s    $f12, $f5
syscall                      # print out actual sum

addi $v0, $zero, 4  # print_string syscall
la $a0, space       # load address of the string
syscall

#########
div.s $f7, $f6, $f0	# Fraction of unique words in the text

li      $v0, 4
la      $a0, result3
syscall                      # print out "Fraction of unique words in the text = "

li      $v0, 2
mov.s    $f12, $f7
syscall                      # print out actual sum

addi $v0, $zero, 4  # print_string syscall
la $a0, space       # load address of the string
syscall

#######
li      $v0, 4
la      $a0, result4
syscall                      # print out "Number of clauses in the text = "

li      $v0, 2
mov.s    $f12, $f14
syscall                      # print out actual sum

addi $v0, $zero, 4  # print_string syscall
la $a0, space       # load address of the string
syscall
#######

#PAST THIS POINT VARIABLES HAVE DIFFERENT MEANINGS
#s0 - none
#s1 - The character that was just read in
#s2 - This number is the amount of digits to the right of the decimal
#s3 - the current byte in the author's name memory location
#s4 - The current field in the database - 1 is average words per sentence, 2 is average chars per word, 3 is author name
#s5 - the current value of the number from field 1 or 2 (a digit gets added every time the field is read)
#s6 - The current digit # (digit # of 101 is 3) of the number from field 1 or 2
#s7 - none

####### These two syscalls open the database
li $v0, 13      	# Prepare to open file.
la $a0, datafile	#Address of the file we want to open
li $a1, 0			#unused, but this is here just to be safe
li $a2, 0			#same thing
syscall      		# Puts the file descriptor in $v0

move $a0, $v0	#The output of the first syscall is the input to the next

li $v0, 14    		#Prepares file to be read
la $a1, databuffer  #Specifies buffer
li $a2, 0xFF00      #Specifies length
syscall      		# Reads it.

li $t1, 1000000		
mtc1 $t1, $f12
cvt.s.w $f12, $f12		#This initialized the authorship "score" to a very poor one so that it must be replaced by one in the database

add $v0, $v0, $a1		#v0 is the end

li $s6, 0				#initialize current digit

la $s3, currentauthor	#so we start writing to the correct locationl

#This section loads the database a byte at a time because it is much smaller and the performance hit wouldn't be as large

load_char:
addi $v0, $v0, -1		#Note that the file is loaded from end to start to make calculations simpler
blt $v0, $a1, finish

lb $s1, 0($v0)			#Load the current byte in

addi $t0, $zero, 0x2E	#period character
beq $s1, $t0, decimal
addi $t0, $zero, 0x2C	#comma character
beq $s1, $t0, comma
addi $t0, $zero, 0x0A	#newline ascii value
beq $s1, $t0, newline
addi $t0, $zero, 0x3A	#ascii value directly below 0
blt $s1, $t0, check_lower_bound
j letter

check_lower_bound:
addi $t0, $zero, 0x2F	#ascii value directly above 9
bgt $s1, $t0, number	#if it's within the bounds we know it's a number
j letter				#due to this being the last test we can assume it's a letter if it doesn't pass

##################

comma:
addi $s4, $s4, 1		#field number
li $t1, 1
li $t2, 2
beq $s4, $t1, calculate_awps
beq $s4, $t2, calculate_acpw


##################

decimal:
add $s2, $s6, $zero		#Saves the current digit number (represents digits to right of decimal)
j load_char

##################

number:
li $t1, 1
li $t2, 10
addi $s1, -0x30 		#subtract 0x30 to convert from ascii to actual number value
add $t0, $zero, $s6
jal exp10				#exp10 returns t1 = 10^t0, t1 must be initialized as 1, t2 must be initialized as 10
mult $s1, $t1
mflo $s1				

add $s5, $s5, $s1		#add N*10^n where N is the digit loaded and n is the number of digits so far (starting with 0)
addi $s6, $s6, 1		#Add one to the amount of digits in this number

##################

letter:
bc1f load_char			#If it is not the best author, don't write the name.
sb $s1, 0($s3)			#save character of the best authors name to memory
addi $s3, $s3, 1		#store the next value one up
j load_char

##################

newline:
li $s4, 0				#reset s4
li $s5, 0				#reset s5
la $t0, currentauthor	#reset the write address of the authors name to the original position.
j load_char

################## ABOVE NEEDS TO FIXED, LINK WITH AUTHORSHIP TEST SOMEHOW

authorship_test:
#because of the inherently different scale of words per sentence and characters per word, we chose
#to use a geometric mean of the differences between the actual values and the values in the data base.
sub.s $f29, $f29, $f4	#difference between database awps (average words per sentence) and actual
sub.s $f28, $f28, $f5	#difference between database acpw (average characters per word) and actual
mul.s $f28, $f29, $f28	#The product of those differences
c.lt.s $f28, $f15		#Check if it's negative
bc1t make_positive		#If it is, make it positive
number_is_positive:

li $t0, 100				#iterations of newton's method for finding the square root of the product
li $t1, 1				#this and the following line are just used to computer 1/2
li $t2, 2
mtc1 $t1, $f8
cvt.s.w $f8, $f8
mtc1 $t2, $f9
cvt.s.w $f9, $f9
div.s $f8, $f8, $f9			#f8 = 1/2
add.s $f10, $f10, $f8		#f10 = 1/2, first guess, f10 is in general "Xn" that is, the current "guess" of newton's method
jal calculate_root			#returns f10 = square root of f28, which is the geometric mean of differences

c.lt.s $f9, $f8				#Certainly sets fcond to be 0 (2>1/2) because it might still be true from the last run.
c.lt.s $f10, $f12			#Checks to see if the result is better than the last, f12 is the last result (initialized to 1000000)
bc1t new_best				#if it's less (better) make it the new best value.
new_best_found:

j load_char

##################

exp10:
addi $t0, $t0, -1
blt $t0, $zero, return
mult $t1, $t2
mflo $t1
j exp10

##################

calculate_awps:
li $t1, 1				#declaration for exp10
li $t2, 10				#^
add $t0, $s2, $zero		#t0 gets the value of the # of digits to the right of the decimal
jal exp10

mtc1 $s5, $f31			#Store the non-decimal parsed number in f31
cvt.s.w $f31, $f31		#convert to floating point
mtc1 $t1, $f30			#this number is what we have to divide by to get it into proper form (10^n where n is the amount of digits to the right)
cvt.s.w $f30, $f30		#convert to floating point

div.s $f29, $f31, $f30	#Get actual value
li $s5, 0
li $s6, 0

j load_char

##################
#This code is all the same as the previous block but it stores the result in f30
calculate_acpw:
li $t1, 1
li $t2, 10
add $t0, $s2, $zero
jal exp10

mtc1 $s5, $f31
cvt.s.w $f31, $f31
mtc1 $t1, $f30
cvt.s.w $f30, $f30

div.s $f28, $f31, $f30

li $s5, 0
li $s6, 0
j authorship_test

make_positive:
#If it's negative we just subtract iself twice to get the positive version
add.s $f26, $f26, $f28
sub.s $f28, $f28, $f26
sub.s $f28, $f28, $f26
j number_is_positive

return:
jr $ra

calculate_root:
#the following is an implementation of newtons method to find the square root of f28 and store it in f10
div.s $f11, $f28, $f10		#f11 = S/xn
add.s $f11, $f11, $f10		#f11 = S/xn + xn
mul.s $f10, $f8, $f11		#f10 = 1/2(S/xn + xn)
addi $t0, $t0, -1
blt $t0, $zero, return
j calculate_root

new_best:
add.s $f12, $f17, $f10		#Stores the current best in f12



j new_best_found

finish:
j main

