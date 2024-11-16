################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       TODO
# - Unit height in pixels:      TODO
# - Display width in pixels:    TODO
# - Display height in pixels:   TODO
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################




.data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

  


##############################################################################
# Mutable Data
##############################################################################

# ADDRESSES
displayaddress:     .word       0x10008000   # Base address for the display
grid_addresses:     .word       0x11000000   # Base address for the grid cell addresses

# NUMERICAL VALUES
width:              .word       80           # Width of the display (64 pixels)
height:             .word       64           # Height of the display (64 pixels)

# COORDINATES
initial_pill_row:   .word       3            # Initial row position of the pill
initial_pill_col:   .word       12           # Initial column position of the pill

# COLORS (RGB values)
black:              .word       0x010100     # RGB color code for black
red:                .word       0xfa26a0     # RGB color code for red
yellow:             .word       0xf8d210     # RGB color code for yellow
blue:               .word       0x2ff3e0     # RGB color code for blue
rosewater:          .word       0xffc2c7     # RGB color code for rosewater (light pink)




.text
    .globl main
##############################################################################
# Code
##############################################################################

main:
    
    
    jal INIT
    jal PAINT_DISPLAY
    jal SLEEP1000
    jal game_loop
    j END_MAIN
    
game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	
	# 2b. Update locations (capsules)
	
	
	# 3. Draw the screen
	jal PAINT_DISPLAY
	
	# 4. Sleep
    jal SLEEP1000
    # 5. Go back to Step 1
    j game_loop
    
INIT:
    
    addi $sp, $sp, -4               # Allocate space on the stack
    sw $ra, 0($sp)                  # Save $ra on the stack
    
    jal INITIALIZE_GRID             # Initialize the grid and display the bottle
    lw $s0, grid_addresses          # $s0 is the address of the grid
    lw $s1, initial_pill_row
    lw $s2, initial_pill_col
    li $s3, 0 
    jal DRAW_BOTTLE                 # Draw the bottle
    jal DRAW_NEW_PILL
    
    lw $ra, 0($sp)                  # Load saved $ra
    addi $sp, $sp, 4                # Restore stack pointer
    jr $ra                          # Return from main
    


# Function: INITIALIZE_GRID
# Initializes the grid by storing the addresses of display cells in grid_addresses.
INITIALIZE_GRID:

    addi $sp, $sp, -4               # Allocate space on the stack
    sw $ra, 0($sp)                  # Save $ra on the stack
    
    # Load display width and height
    lw $t0, width                   # $t0 = width
    lw $t1, height                  # $t1 = height
    
    # Calculate the number of rows and columns (dividing width and height by 2)
    divu $t8, $t0, 2                # Number of columns
    divu $t9, $t1, 2                # Number of rows
    
    # Store grid cell addresses in grid_addresses array
    lw $t2, grid_addresses          # Load address of grid_addresses array
    lw $t5, displayaddress          # Load the base address of the display
    
    li $t3, 0                       # set row index (row = 0)
    row_loop_INITIALIZE_GRID:       # Start loop
        
        li $t4, 0                       # set column index (col = 0)
        column_loop_INITIALIZE_GRID:    # Start loop
            
            # Calculate address offset: ((row * 2 * width) + (col * 2)) * 4
            mul $t6, $t3, 2          # row * 2
            mul $t6, $t6, $t0        # row * 2 * width
            mul $t7, $t4, 2          # col * 2
            add $t6, $t6, $t7        # (row * 2 * width) + (col * 2)
            mul $t6, $t6, 4          # Offset * 4 (byte address offset)
            add $v0, $t5, $t6        # Base Address + Offset == final address
            
            # Store the calculated address in the grid_addresses array
            sw $v0, 0($t2)             # Store the address in the array
            lw $t6, black
            sw $t6, 4($t2)             # Store the address in the array
            
            addi $t2, $t2, 32           # Move to the next array index (each address is 4 bytes)
            addi $t4, $t4, 1           # Increment column index (j++)
            bne $t4, $t8, column_loop_INITIALIZE_GRID    # Repeat until all columns are processed
            
            addi $t3, $t3, 1           # Increment row index (i++)
            bne $t3, $t9, row_loop_INITIALIZE_GRID    # Repeat until all rows are processed
            
    lw $ra, 0($sp)                  # Load saved $ra
    addi $sp, $sp, 4                # Restore stack pointer
    jr $ra                          # Return from main

    

# Function: SET_SQUARE_COLOR
# Set the color of a Cell (a 4x4 square on the display) at the address stored in $a0 using the color in $s7.
SET_SQUARE_COLOR:
    # $s7 is the color
    
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address

    jal GET_CELL_IN_ARRAY    # get $v0 now has the cell address at coordinate ($a0, $a1)
    sw $s7, 4($v0)           # same the color at the cell structure
    
    lw $ra, 0($sp)           # Restore return address
    addi $sp, $sp, 4         # Restore stack pointer
    jr $ra                   # Return from function
    
    

# Function: REMOVE_SQUARE_COLOR
# Remove the color of a Cell (a 4x4 square on the display) at the address stored in $a0 using the color in $s7.
REMOVE_SQUARE_COLOR:
    # Loop over each row in the 4x4 square
    # $s7 is the color
    
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    jal GET_CELL_IN_ARRAY       # $v0 now has the cell ($a0, $a1)
    lw $s7, black
    sw $s7, 4($v0) 
    
    lw $ra, 0($sp)           # Restore return address
    addi $sp, $sp, 4         # Restore stack pointer
    jr $ra                   # Return from function

# Function: DRAW_BOTTLE
# Draws a bottle shape by calling DRAW_RECTANGLE for different parts of the bottle.
DRAW_BOTTLE:

    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    lw $s7, rosewater        # Load rosewater color
    
    li $a0, 2
    li $a1, 10
    li $a2, 5
    li $a3, 10
    jal DRAW_RECTANGLE # Left Neck
    
    li $a0, 2
    li $a1, 9
    li $a2, 2
    li $a3, 9
    jal DRAW_RECTANGLE # Left Mouth
    
    li $a0, 2
    li $a1, 14
    li $a2, 5
    li $a3, 14
    jal DRAW_RECTANGLE # Right Neck
    
    li $a0, 2
    li $a1, 15
    li $a2, 2
    li $a3, 15
    jal DRAW_RECTANGLE # Right Mouth
    
    li $a0, 5
    li $a1, 3
    li $a2, 5
    li $a3, 9
    jal DRAW_RECTANGLE # Left Body Top
    
    li $a0, 5
    li $a1, 15
    li $a2, 5
    li $a3, 21
    jal DRAW_RECTANGLE # Right Body Top
    
    li $a0, 5
    li $a1, 2
    li $a2, 29
    li $a3, 2
    jal DRAW_RECTANGLE # Left Body Side
    
    li $a0, 5
    li $a1, 22
    li $a2, 29
    li $a3, 22
    jal DRAW_RECTANGLE # Right Body Side
    
    li $a0, 29
    li $a1, 3
    li $a2, 29
    li $a3, 21
    jal DRAW_RECTANGLE # Bottom
    
    lw $ra, 0($sp)           # Restore return address
    addi $sp, $sp, 4         # Restore stack pointer
    jr $ra                   # Return from function
    
    
# Function: DRAW_RECTANGLE
# Draws a rectangle with the top-left corner at (row, col) and the bottom-right corner at (row, col).
DRAW_RECTANGLE:
    # Arguments:
    #   $a0 = left top row coordinate (starting row of the rectangle)
    #   $a1 = left top column coordinate (starting column of the rectangle)
    #   $a2 = right bottom row coordinate (ending row of the rectangle)
    #   $a3 = right bottom column coordinate (ending column of the rectangle)
    #
    # Registers:
    #   $s1 = current row (starting from the top row)
    #   $s2 = current column (starting from the left column)
    #   $s3 = right bottom row coordinate (used as row boundary)
    #   $s4 = right bottom column coordinate (used as column boundary)
    #   $s5 = initial left top column coordinate (saved column start)
    #   $t3 = row counter
    #   $t4 = column counter
    
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    move $t1, $a0            # Save left top row in $s1
    move $t2, $a1            # Save left top column in $s2
    move $t5, $a1            # Save initial column coordinate for reference
    
    move $t3, $a2            # Save right bottom row in $s3
    addi $t3, $t3, 1         # Increment row to go one past the end row
    move $t4, $a3            # Save right bottom column in $s4
    addi $t4, $t4, 1         # Increment column to go one past the end column
    
    row_loop_DRAW_RECTANGLE:
        move $t2, $t5        # Reset column to the left side for each row
        move $a0, $t1        # Set current row to $a0
        
        col_loop_DRAW_RECTANGLE:
                    move $a1, $t2                           # Set current column to $a1
                    jal SET_SQUARE_COLOR                        # Paint the current square
                    addi $t2, $t2, 1                        # Increment column counter
                    bne $t2, $t4, col_loop_DRAW_RECTANGLE   # Continue looping through columns until end
        
        addi $t1, $t1, 1                        # Increment row counter
        bne $t1, $t3, row_loop_DRAW_RECTANGLE   # Continue looping through rows until end
    
    lw $ra, 0($sp)           # Restore return address
    addi $sp, $sp, 4         # Restore stack pointer
    jr $ra                   # Return from function



# Function: RANDOM_COLOR
# Randomly selects one of three colors and stores it in $s7.
#
# Arguments:
#   $a0 = value to be returned to caller after color selection
#   $a1 = another argument to return
#
# The function generates a random number and sets $s7 to one of three color values:
# - Red (if random number is 0)
# - Yellow (if random number is 1)
# - Blue (if random number is 2)
#
# It uses the syscall to generate the random number and determine which color to return.
RANDOM_COLOR:
    
    move $t0, $a0           # Save original arguments for later
    move $t1, $a1
    
    li $v0, 42              # Load syscall code for random number generation
    li $a0, 0               # Lower bound for the random number
    li $a1, 3               # Upper bound (exclusive)
    syscall                 # Make syscall to generate random number
    
    beq $a0, 0, red_RANDOM_COLOR    # If random number is 0, select red
    beq $a0, 1, yellow_RANDOM_COLOR # If random number is 1, select yellow
    beq $a0, 2, blue_RANDOM_COLOR   # If random number is 2, select blue
    
    red_RANDOM_COLOR:
        lw $v0, red         # Load red color code into $s7
        j end_RANDOM_COLOR  # Jump to the end of function
    
    yellow_RANDOM_COLOR:
        lw $v0, yellow      # Load yellow color code into $s7
        j end_RANDOM_COLOR  # Jump to the end of function
    
    blue_RANDOM_COLOR:
        lw $v0, blue        # Load blue color code into $s7
        j end_RANDOM_COLOR  # Jump to the end of function
    
    end_RANDOM_COLOR:
        move $a0, $t0       # Restore original arguments
        move $a1, $t1
        jr $ra               # Return from function
    

# Function: DRAW_PILL
# Draws a pill shape based on the given position and orientation (vertical or horizontal).
#
# Arguments:
#   $a0 = row_position (row of the starting point of the pill)
#   $a1 = column_position (column of the starting point of the pill)
#   $a2 = rotation state 
#   $s7 has to be set to the color of reference capsule
#   $s6 has to be set to the color of accompanying capsule
# This function calls RANDOM_COLOR to choose a random color and then calls SET_SQUARE_COLOR
# to paint each part of the pill shape. The pill consists of two squares in either
# a vertical or horizontal orientation.
DRAW_PILL:

    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    # Painting the first square...
    jal SET_SQUARE_COLOR         # Paint the first square of the pill
    
    move $s7, $s6
    
    # Painting the second square...
    beq $a2, 0, draw_vertical_south_half   # Check if vertical pill is needed
    beq $a2, 1, draw_horizontal_west_half  # Check if horizontal pill is needed
    beq $a2, 2, draw_vertical_north_half  # Check if horizontal pill is needed
    beq $a2, 3, draw_horizontal_east_half  # Check if horizontal pill is needed
    
    draw_vertical_south_half:
        addi $a0, $a0, 1     # Move to the next row for vertical pill
        jal SET_SQUARE_COLOR     # Paint the second square of the pill
        j end_DRAW_PILL      # Skip the horizontal part
    
    draw_horizontal_west_half:
        addi $a1, $a1, -1     # Move to the next column for horizontal pill
        jal SET_SQUARE_COLOR     # Paint the second square of the pill
        j end_DRAW_PILL      # Skip the vertical part
    
    draw_vertical_north_half:
        addi $a0, $a0, -1     # Move to the next column for horizontal pill
        jal SET_SQUARE_COLOR     # Paint the second square of the pill
        j end_DRAW_PILL      # Skip the vertical part
    
    draw_horizontal_east_half:
        addi $a1, $a1, 1     # Move to the next column for horizontal pill
        jal SET_SQUARE_COLOR     # Paint the second square of the pill
        j end_DRAW_PILL      # Skip the vertical part
    
    end_DRAW_PILL:
        lw $ra, 0($sp)       # Restore return address
        addi $sp, $sp, 4     # Restore stack pointer
        jr $ra               # Return from function



REMOVE_PILL:

    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    # Painting the first square...
    jal REMOVE_SQUARE_COLOR         # Paint the first square of the pill
    
    beq $a2, 0, remove_vertical_south_half   # Check if vertical pill is needed
    beq $a2, 1, remove_horizontal_west_half  # Check if horizontal pill is needed
    beq $a2, 2, remove_vertical_north_half  # Check if horizontal pill is needed
    beq $a2, 3, remove_horizontal_east_half  # Check if horizontal pill is needed
    
    remove_vertical_south_half:
        addi $a0, $a0, 1     # Move to the next row for vertical pill
        jal REMOVE_SQUARE_COLOR     # Paint the second square of the pill
        j end_REMOVE_PILL      # Skip the horizontal part
    
    remove_horizontal_west_half:
        addi $a1, $a1, -1     # Move to the next column for horizontal pill
        jal REMOVE_SQUARE_COLOR     # Paint the second square of the pill
        j end_REMOVE_PILL      # Skip the vertical part
    
    remove_vertical_north_half:
        addi $a0, $a0, -1     # Move to the next column for horizontal pill
        jal REMOVE_SQUARE_COLOR     # Paint the second square of the pill
        j end_REMOVE_PILL      # Skip the vertical part
    
    remove_horizontal_east_half:
        addi $a1, $a1, 1     # Move to the next column for horizontal pill
        jal REMOVE_SQUARE_COLOR     # Paint the second square of the pill
        j end_REMOVE_PILL      # Skip the vertical part
    
    end_REMOVE_PILL:
        lw $ra, 0($sp)       # Restore return address
        addi $sp, $sp, 4     # Restore stack pointer
        jr $ra               # Return from function  


EXTRACT_CURRENT_PILL_COLOR:

    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    # Painting the first square...
    jal GET_CELL_IN_ARRAY
    move $t0, $v0
    lw $t2, 4($t0)
    
    
    beq $a2, 0, get_vertical_south_half   # Check if vertical pill is needed
    beq $a2, 1, get_horizontal_west_half  # Check if horizontal pill is needed
    beq $a2, 2, get_vertical_north_half  # Check if horizontal pill is needed
    beq $a2, 3, get_horizontal_east_half  # Check if horizontal pill is needed
    
    
    get_vertical_south_half:
        addi $a0, $a0, 1     # Move to the next row for vertical pill
        jal GET_CELL_IN_ARRAY     # Paint the second square of the pill
        lw $v1, 4($v0)
        j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the horizontal part
    
    
    get_horizontal_west_half:
        addi $a1, $a1, -1     # Move to the next column for horizontal pill
        jal GET_CELL_IN_ARRAY     # Paint the second square of the pill
        lw $v1, 4($v0)
        j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the vertical part
    
    
    get_vertical_north_half:
        addi $a0, $a0, -1     # Move to the next column for horizontal pill
        jal GET_CELL_IN_ARRAY     # Paint the second square of the pill
        lw $v1, 4($v0)
        j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the vertical part
    
    
    get_horizontal_east_half:
        addi $a1, $a1, 1     # Move to the next column for horizontal pill
        jal GET_CELL_IN_ARRAY     # Paint the second square of the pill
        lw $v1, 4($v0)
        j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the vertical part
    
    
    end_EXTRACT_CURRENT_PILL_COLOR:
        move $v0, $t2
        lw $ra, 0($sp)       # Restore return address
        addi $sp, $sp, 4     # Restore stack pointer
        jr $ra               # Return from function
  
    
DRAW_NEW_PILL:

    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    lw $a0, initial_pill_row        # Draw the initial pill at the specified position
    lw $a1, initial_pill_col
    li $a2, 0
    jal RANDOM_COLOR
    move $s6, $v0
    jal RANDOM_COLOR
    move $s7, $v0
    
    jal DRAW_PILL
    
    lw $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4     # Restore stack pointer
    jr $ra  
    
    
PAINT_DISPLAY:
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    lw $t0, grid_addresses
    lw $t8, width
    mul $t3, $t8, 4 
    
    div $t8, $t8, 2 # number of columns
    lw $t7, height 
    
    div $t7, $t7, 2 # number of rows
    
    li, $t6, 0                      # offset
    
    li $t1, 0                       # set row index (row = 0)
    row_loop_PAINT_DISPLAY:       # Start loop
        
        li $t2, 0                       # set column index (col = 0)
        column_loop_PAINT_DISPLAY:    # Start loop
            
            move $a0, $t0
            jal GET_CELL_ON_DISPLAY     # GetCell(row, col) stored in $v0
            lw $s7, 4($t0)              # load color
            
            # Store the calculated address in the grid_addresses array
            sw $s7, 0($v0)                 # Store the address in the array
            sw $s7, 4($v0)                 # Store the address in the array
            add $v0, $v0, $t3
            sw $s7, 0($v0)                 # Store the address in the array
            sw $s7, 4($v0)                 # Store the address in the array
            
            addi $t0, $t0, 32           # Move to the next array index (each address is 4 bytes)
            addi $t2, $t2, 1           # Increment column index (j++)
            bne $t2, $t8, column_loop_PAINT_DISPLAY    # Repeat until all columns are processed
            
            addi $t1, $t1, 1           # Increment row index (i++)
            bne $t1, $t7, row_loop_PAINT_DISPLAY    # Repeat until all rows are processes
    
    lw $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4     # Restore stack pointer
    jr $ra               # Return from function
    

GET_CELL_IN_ARRAY:

    # Load base address and width
    lw $t0, width            # Width of the display
    div $t0, $t0, 2
    
    # Calculate address offset: ((row * 2 * width) + (col * 2)) * 4
    addi $t6, $a0, 0          # row * 2
    mul $t6, $t6, $t0        # row * 2 * number of columns
    addi $t7, $a1, 0          # col * 2
    add $t6, $t6, $t7        # (row * 2 * width) + (col * 2)
    mul $t6, $t6, 32          # Offset * 4 (byte address offset)
    add $v0, $s0, $t6        # Base Address + Offset == final address
    jr $ra                   # Return to caller



# Function: GET_CELL_ON_DISPLAY
# Calculates the address of a specific cell at (row, col) based on the base display address and width.
GET_CELL_ON_DISPLAY:

    lw $v0, 0($a0)
    jr $ra

UPDATE_CURRENT_PILL:
    
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    move $t3, $a0
    move $t4, $a1
    
    move $a0, $s1
    move $a1, $s2
    jal EXTRACT_CURRENT_PILL_COLOR
    move $t1, $v0
    move $t2, $v1
    
    move $a0, $s1
    move $a1, $s2
    jal REMOVE_PILL
    
    move $s7, $t1
    move $s6, $t2
    
    add $s1, $s1, $t3
    add $s2, $s2, $t4
    
    move $a0, $s1
    move $a1, $s2
    move $a2, $s3
    jal DRAW_PILL
    
    lw $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4     # Restore stack pointer
    jr $ra               # Return from function


UPDATE_GRID:
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    li $a0, 1
    li $a1, 0
    jal UPDATE_CURRENT_PILL

    lw $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4     # Restore stack pointer
    jr $ra               # Return from function


SLEEP1000:
    
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    li $t9, 0
    
    SLEEP_LOOP:
        jal CHECK_KEYBOARD_INPUT
        li $v0, 32
        li $a0, 10
        syscall
        addi $t9, $t9, 1
        li $t8, 100
        bne $t9, $t8, SLEEP_LOOP
   
    jal UPDATE_GRID
    lw $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4     # Restore stack pointer   
    jr $ra
    
CHECK_KEYBOARD_INPUT:
    
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    lw $t0, ADDR_KBRD
    lw $t1, 0($t0)
    bne $t1, 1, end_CHECK_KEYBOARD_INPUT
    KEYBOARD_HANDLER:
        
        lw $t2, 4($t0)
        beq $t2, 0x71, HANDLE_QUIT
        beq $t2, 0x77, HANDLE_ROTATE
        beq $t2, 0x61, HANDLE_MOVE_LEFT
        beq $t2, 0x73, HANDLE_DROP
        beq $t2, 0x64, HANDLE_MOVE_RIGHT
    
    HANDLE_QUIT:
        jal INIT
        jal PAINT_DISPLAY
        j END_MAIN
    
    HANDLE_MOVE_LEFT:
    jal GET_PILL_ADDRESSES
        
        move $a0 $v0
        move $a1 $v1
        jal detect_left
	    bne $v0 $zero end_CHECK_KEYBOARD_INPUT
    
        li $a0, 0
        li $a1, -1
        jal UPDATE_CURRENT_PILL
        jal PAINT_DISPLAY
        
        j end_CHECK_KEYBOARD_INPUT
        
   GET_PILL_ADDRESSES:
 
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address

    move $a0, $s1
    move $a1, $s2
    jal GET_CELL_IN_ARRAY
    move $v1, $v0

    beq $s3, 0, vertical_south_GET_PILL_ADDRESS
    beq $s3, 1, horizontal_west_GET_PILL_ADDRESS
    beq $s3, 2, vertical_north_GET_PILL_ADDRESS
    beq $s3, 3, horizontal_east_GET_PILL_ADDRESS

    vertical_south_GET_PILL_ADDRESS:
        addi $a0, $a0, 1
        jal GET_CELL_IN_ARRAY
        j end_GET_PILL_ADDRESS

    horizontal_west_GET_PILL_ADDRESS:
        addi $a1, $a1, -1
        jal GET_CELL_IN_ARRAY
        j end_GET_PILL_ADDRESS

    vertical_north_GET_PILL_ADDRESS:
        addi $a0, $a0, -1
        jal GET_CELL_IN_ARRAY
        j end_GET_PILL_ADDRESS

    horizontal_east_GET_PILL_ADDRESS:
        addi $a1, $a1, 1
        jal GET_CELL_IN_ARRAY
        j end_GET_PILL_ADDRESS

    end_GET_PILL_ADDRESS:
        lw $ra, 0($sp)       # Restore return address
        addi $sp, $sp, 4     # Restore stack pointer
        jr $ra               # Return from function
          
    HANDLE_MOVE_RIGHT:
        jal GET_PILL_ADDRESSES
        
        move $a0 $v0
        move $a1 $v1
        jal detect_right
	    bne $v0 $zero end_CHECK_KEYBOARD_INPUT
	    
	    li $a0, 0
        li $a1, 1
        jal UPDATE_CURRENT_PILL
        jal PAINT_DISPLAY

        j end_CHECK_KEYBOARD_INPUT
        
    HANDLE_ROTATE:
        move $a2, $s3
        addi $s3, $s3, 1
        bne $s3, 4, continue_HANDLE_ROTATE
        li $s3, 0
        continue_HANDLE_ROTATE:
        li $a0, 0
        li $a1, 0
        jal UPDATE_CURRENT_PILL
        jal PAINT_DISPLAY
        
        j end_CHECK_KEYBOARD_INPUT
            
    HANDLE_DROP:
        
        jal FIND_BOTTOM
        move $t9, $v0
        sub $t9, $t9, $s1
        bne $s3, 0, offset_calculated_HANDLE_DROP 
            subi $t9, $t9, 1
            j offset_calculated_HANDLE_DROP
        
        offset_calculated_HANDLE_DROP:
            move $a0, $t9
            li $a1, 0
            jal UPDATE_CURRENT_PILL
            jal PAINT_DISPLAY
            
        j end_CHECK_KEYBOARD_INPUT
            
    end_CHECK_KEYBOARD_INPUT:
        lw $ra, 0($sp)       # Restore return address
        addi $sp, $sp, 4     # Restore stack pointer   
        jr $ra
 
    
    

FIND_BOTTOM:

    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address
    
    lw $t4, black
    
    move $t1, $s1
    addi $t1, $t1, 1
    bne $s3, 0, check_if_boundary_reached
    addi $t1, $t1, 1
    
    check_if_boundary_reached:
    slti $t2, $t1, 29
    bne $t2, 1, bottom_reached
    
    BOTTOM_SEARCH_LOOP:
        move $a0, $t1
        move $a1, $s2
        jal GET_CELL_IN_ARRAY
        lw $t3, 4($v0)
        
        bne $t3, $t4, exit_BOTTOM_SEARCH_LOOP
        addi $t1, $t1, 1
        bne $t1, 29, BOTTOM_SEARCH_LOOP
    
    exit_BOTTOM_SEARCH_LOOP:
        subi $t1, $t1, 1
        move $v0, $t1
        j end_FIND_BOTTOM
        
    bottom_reached:
        move $v0, $s1
        j end_FIND_BOTTOM
    
    end_FIND_BOTTOM:
        lw $ra, 0($sp)       # Restore return address
        addi $sp, $sp, 4     # Restore stack pointer
        jr $ra               # Return from function
    
END_MAIN:



detect_left:
add $a1 $a1 4
add $a0 $a0 4
add $v0 $zero $zero
addi $t9 $zero -32 # Encodes the direction
addi $a1 $a1 32
beq $a0 $a1 detect_case_a
addi $a1 $a1 -64
beq $a0 $a1 detect_case_b
addi $a1 $a1 32
j detect_case_c

detect_right:
add $a1 $a1 4
add $a0 $a0 4
add $v0 $zero $zero
addi $t9 $zero 32
addi $a1 $a1 32
beq $a0 $a1 detect_case_b
addi $a1 $a1 -64
beq $a0 $a1 detect_case_a
addi $a1 $a1 32
j detect_case_c

detect_case_a: # We check the half stored in $s4
add $a1 $a1 $t9 # Reset after we shifted it to check the condition
add $a1 $a1 $t9 # Check one block in direction t7

lw $t8 0($a1)
mult $t9 $t9 -1
add $a1 $a1 $t9
beq $t8 0x010100 chain_return
addi $v0 $v0 1
jr $ra

detect_case_b: # We check the half stored in $s3
sub $a1 $a1 $t9
add $a0 $a0 $t9
lw $t8 0($a0)
mult $t9 $t9 -1
add $a0 $a0 $t9
beq $t8 0x010100 chain_return
addi $v0 $v0 1
jr $ra

detect_case_c: # We need to check both halves of the capsule
add $a0 $a0 $t9
lw $t8 0($a0)
sub $a0 $a0 $t9
sub $a1 $a1 $t9
beq $t8 0x010100 detect_case_a # In the case nothing is found after checking $s3
add $a1 $a1 $t9
addi $v0 $v0 1 # Immediate failure if we cannnot shift $s3
jr $ra

chain_return:
jr $ra

falling_block:
# Requires t8, t9
addi $t9 $zero 0
addi $a0 $a1 0
jal detect_fall
addi $a0 $a2 0
jal detect_fall
# beq $t9, 1, post_fall
# beq $t9 2 post_fall
# j fall

detect_fall:

mult $a3 $a3 32 # a3
add $a0 $a0 $a3 # Store address of one block below in a0
lw $t8 0($a0) # Store value of one block below in t8
bne $t8 0x010100 finish_detect_fall # If there is no block below, do nothing
beq $a0 $a1 finish_detect_fall # If one half falls onto the other half, it is ok
beq $a0 $a2 finish_detect_fall
addi $t9 $t9 1
finish_detect_fall:
jr $ra