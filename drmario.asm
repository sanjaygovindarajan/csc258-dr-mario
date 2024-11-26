################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Sanjay Gavindarajan
# Student 2: Seonghyun Ban
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    110
# - Display height in pixels:   72
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.macro addstack ()
    addi $sp, $sp, -4   # Allocate space on the stack
    sw $ra, 0($sp)      # Save return address
.end_macro
.macro return ()
    lw $ra, 0($sp)      # Restore return address
    addi $sp, $sp, 4    # Restore stack pointer
    jr $ra              # Return to caller
.end_macro



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
displayaddress:         .word       0x10008000   # Base address for the display
game_grid_address:      .word       0x11000000   # Base address for the grid cell addresses
message_grid_address:   .word       0x12000000   # Base address for the grid cell addresses
pill_queue_address:     .word       0x13000000
letter_address:         .word       0x20000000  

# NUMERICAL VALUES
width:              .word       110           # Width of the display (64 pixels)
height:             .word       72           # Height of the display (64 pixels)

# COORDINATES
initial_pill_row:   .word       5            # Initial row position of the pill
initial_pill_col:   .word       16           # Initial column position of the pill
pill_queue_row:     .word       2
pill_queue_col:     .word       32

# COLORS (RGB values)
black:              .word       0x010100     # RGB color code for black
red:                .word       0xfa26a0     # RGB color code for red
yellow:             .word       0xf8d210     # RGB color code for yellow
blue:               .word       0x2ff3e0     # RGB color code for blue
rosewater:          .word       0xffc2c7     # RGB color code for rosewater (light pink)
white:              .word       0xffffff     # RGB color code for white
aqua:               .word       0x99ffff
bright_red:         .word       0xff99dd
bright_yellow:      .word       0xffffdd


.text
    .globl main
##############################################################################
# Code
##############################################################################










##############################################################################
# Subsection: >MAIN

    main:
        
        jal INIT
        jal PAINT_DISPLAY
        jal game_loop
        j END_MAIN
    


    game_loop:
        
        # 1a. Check if key has been pressed
        # 1b. Check which key has been pressed
        # 2a. Check for collisions
        # 4. Sleep while checking for input.
        jal INPUT_LOOP
        end_INPUT_LOOP:
        
        # 2b. Update locations (capsules)
        jal     LET_CURRENT_PILL_FALL
        NO_UPDATE:

        # 3. Draw the screen
        jal PAINT_DISPLAY
        
        # 5. Go back to Step 1
        j game_loop

    
    INPUT_LOOP:
    
    addstack()
    
    li $t9, 0

    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    SLEEP_LOOP:
        # 2a. Check for collisions
        jal CHECK_KEYBOARD_INPUT
        li $v0, 32
        li $a0, 10
        syscall
        addi $t9, $t9, 1
        li $t8, 100
        bne $t9, $t8, SLEEP_LOOP

    return()
    



# End of: <MAIN
##############################################################################    


##############################################################################
# Subsection: >INITIALIZATION

    INIT:
        
        addstack()
        
        jal INITIALIZE_GAME_GRID
        jal INITIALIZE_MESSAGE_GRID
        
        lw $s0, game_grid_address          # $s0 is the address of the grid        
        lw $s1, initial_pill_row
        lw $s2, initial_pill_col
        li $s3, 0 
        jal DRAW_BOTTLE                 # Draw the bottle
        jal DRAW_NEW_PILL
        
        li $t8 4
        DRAW_VIRUSES:
        jal DRAW_VIRUS
        subi $t8 $t8 1
        bgtz $t8 DRAW_VIRUSES
        
        jal INITIALIZE_PILL_QUEUE
        
        return()
        


    # Function: INITIALIZE_GRID
    # Initializes the grid by storing the addresses of display cells in game_grid_address.
    INITIALIZE_GRID:

        addstack()
        
        # Load display width and height
        lw $t0, width                   # $t0 = width
        lw $t1, height                  # $t1 = height
        
        # Calculate the number of rows and columns (dividing width and height by 2)
        divu $t8, $t0, 2                # Number of columns
        divu $t9, $t1, 2                # Number of rows
        
        # Store grid cell addresses in game_grid_address array
        move $t2, $s0           # Load address of game_grid_address array
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
                
                # Store the calculated address in the game_grid_address array
                sw $v0, 0($t2)             # Store the address in the array
                move $t6, $s7
                sw $t6, 4($t2)             # Store the color in the array
                sw $zero, 8($t2)           # Store that it is not a virus
                
                addi $t2, $t2, 32           # Move to the next array index (each address is 4 bytes)
                addi $t4, $t4, 1           # Increment column index (j++)
                bne $t4, $t8, column_loop_INITIALIZE_GRID    # Repeat until all columns are processed
                
                addi $t3, $t3, 1           # Increment row index (i++)
                bne $t3, $t9, row_loop_INITIALIZE_GRID    # Repeat until all rows are processed
                
        return()

    INITIALIZE_GAME_GRID:
        
        addstack()
        lw $s0, game_grid_address
        lw $s7, black
        jal INITIALIZE_GRID             # Initialize the grid and display the bottle
        return()
    
    INITIALIZE_MESSAGE_GRID:
    
        addstack()
        lw $s0, message_grid_address
        lw $s7, white
        jal INITIALIZE_GRID             # Initialize the grid and display the bottle
        return()

    INITIALIZE_PILL_QUEUE:
        addstack()
        
        lw $t1, pill_queue_col
        lw $t7, pill_queue_address
        
        li $t3, 0
        
        loop_INITIALIZE_PILL_QUEUE:
            lw $a0, pill_queue_row
            move $a1, $t1
            li $a2, 3
            jal RANDOM_COLOR
            move $s6, $v0
            sw $s6, 4($t7) 
            jal RANDOM_COLOR
            move $s7, $v0
            sw $s7, 0($t7)
            jal DRAW_PILL
            
            addi $t1, $t1, 4
            addi $t3, $t3, 1
            addi $t7, $t7, 32
            bne $t3, 5, loop_INITIALIZE_PILL_QUEUE
            
        return()



# End of: <INITIALIZATION
##############################################################################


##############################################################################
# Subsection: >CELL_METHODS

    # Function: SET_CELL_COLOR
    # Set the color of a Cell (a 4x4 square on the display) at the address stored in $a0 using the color in $s7.
    SET_CELL_COLOR:
        # $s7 is the color
        
        addstack()

        jal GET_CELL_GRID_ADDRESS    # get $v0 now has the cell address at coordinate ($a0, $a1)
        sw $s7, 4($v0)           # same the color at the cell structure
        
        return()
        
        

    # Function: REMOVE_CELL_COLOR
    # Remove the color of a Cell (a 4x4 square on the display) at the address stored in $a0 using the color in $s7.
    REMOVE_CELL_COLOR:
        # Loop over each row in the 4x4 square
        # $s7 is the color
        
        addstack()
        
        jal GET_CELL_GRID_ADDRESS       # $v0 now has the cell ($a0, $a1)
        lw $s7, black
        sw $s7, 4($v0) 
        
        return()







# End of: <CELL_METHODS
##############################################################################


##############################################################################
# Subsection: >CELL_GETTERS

    GET_CELL_GRID_ADDRESS:

        addstack()
        
        move $s5, $t7 # Save t7 to restore value later

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
        
        move $t7, $s5 # Restore t7
        
        return()


    # Function: GET_CELL_DISPLAY_ADDRESS
    # Calculates the address of a specific cell at (row, col) based on the base display address and width.
    GET_CELL_DISPLAY_ADDRESS:
        addstack()

        lw $v0, 0($a0)
        
        return()






# End of: <CELL_GETTERS
##############################################################################


##############################################################################
# Subsection: >PILL_METHODS

    # Function: DRAW_PILL
    # Draws a pill shape based on the given position and orientation (vertical or horizontal).
    #
    # Arguments:
    #   $a0 = row_position (row of the starting point of the pill)
    #   $a1 = column_position (column of the starting point of the pill)
    #   $a2 = rotation state 
    #   $s7 has to be set to the color of reference capsule
    #   $s6 has to be set to the color of accompanying capsule
    # This function calls RANDOM_COLOR to choose a random color and then calls SET_CELL_COLOR
    # to paint each part of the pill shape. The pill consists of two squares in either
    # a vertical or horizontal orientation.
    DRAW_PILL:

        addstack()
        
        move $s5, $t0
        # Painting the first square...
        jal SET_CELL_COLOR         # Paint the first square of the pill
        
        move $s7, $s6
        
        # Painting the second square...
        beq $a2, 0, draw_vertical_south_half   # Check if vertical pill is needed
        beq $a2, 1, draw_horizontal_west_half  # Check if horizontal pill is needed
        beq $a2, 2, draw_vertical_north_half  # Check if horizontal pill is needed
        beq $a2, 3, draw_horizontal_east_half  # Check if horizontal pill is needed
        
        draw_vertical_south_half:
            addi $a0, $a0, 1     # Move to the next row for vertical pill
            jal SET_CELL_COLOR     # Paint the second square of the pill
            j end_DRAW_PILL      # Skip the horizontal part
        
        draw_horizontal_west_half:
            addi $a1, $a1, -1     # Move to the next column for horizontal pill
            jal SET_CELL_COLOR     # Paint the second square of the pill
            j end_DRAW_PILL      # Skip the vertical part
        
        draw_vertical_north_half:
            addi $a0, $a0, -1     # Move to the next column for horizontal pill
            jal SET_CELL_COLOR     # Paint the second square of the pill
            j end_DRAW_PILL      # Skip the vertical part
        
        draw_horizontal_east_half:
            addi $a1, $a1, 1     # Move to the next column for horizontal pill
            jal SET_CELL_COLOR     # Paint the second square of the pill
            j end_DRAW_PILL      # Skip the vertical part
        
        end_DRAW_PILL:
            move $t0, $s5
            return()

    

    DRAW_NEW_PILL:

        addstack()
        
        lw $a0, initial_pill_row        # Draw the initial pill at the specified position
        lw $a1, initial_pill_col
        jal GET_CELL_GRID_ADDRESS
        lw $s6 4($v0)
        beq $s6 0x010100 proceed_DRAW_NEW_PILL
        jal GAME_OVER
        j end_DRAW_NEW_PILL
        
        proceed_DRAW_NEW_PILL:
        li $a2, 0
        jal RANDOM_COLOR
        move $s6, $v0
        jal RANDOM_COLOR
        move $s7, $v0
        
        jal DRAW_PILL
        
        end_DRAW_NEW_PILL:
        return() 



    REMOVE_PILL:

        addstack()
        
        # Painting the first square...
        jal REMOVE_CELL_COLOR         # Paint the first square of the pill
        
        beq $a2, 0, remove_vertical_south_half   # Check if vertical pill is needed
        beq $a2, 1, remove_horizontal_west_half  # Check if horizontal pill is needed
        beq $a2, 2, remove_vertical_north_half  # Check if horizontal pill is needed
        beq $a2, 3, remove_horizontal_east_half  # Check if horizontal pill is needed
        
        remove_vertical_south_half:
            addi $a0, $a0, 1     # Move to the next row for vertical pill
            jal REMOVE_CELL_COLOR     # Paint the second square of the pill
            j end_REMOVE_PILL      # Skip the horizontal part
        
        remove_horizontal_west_half:
            addi $a1, $a1, -1     # Move to the next column for horizontal pill
            jal REMOVE_CELL_COLOR     # Paint the second square of the pill
            j end_REMOVE_PILL      # Skip the vertical part
        
        remove_vertical_north_half:
            addi $a0, $a0, -1     # Move to the next column for horizontal pill
            jal REMOVE_CELL_COLOR     # Paint the second square of the pill
            j end_REMOVE_PILL      # Skip the vertical part
        
        remove_horizontal_east_half:
            addi $a1, $a1, 1     # Move to the next column for horizontal pill
            jal REMOVE_CELL_COLOR     # Paint the second square of the pill
            j end_REMOVE_PILL      # Skip the vertical part
        
        end_REMOVE_PILL:
            return()  




    UPDATE_CURRENT_PILL:
    
        addstack()
        
        move $t3, $a0
        move $t4, $a1
        move $t5, $a2
        
        prev_state_stored:
        move $a0, $s1
        move $a1, $s2
        move $a2, $t5
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
        
        return()



    EXTRACT_CURRENT_PILL_COLOR:

        addstack()
        
        # Painting the first square...
        jal GET_CELL_GRID_ADDRESS
        move $t0, $v0
        lw $t2, 4($t0)
        
        beq $a2, 0, get_vertical_south_half   # Check if vertical pill is needed
        beq $a2, 1, get_horizontal_west_half  # Check if horizontal pill is needed
        beq $a2, 2, get_vertical_north_half  # Check if horizontal pill is needed
        beq $a2, 3, get_horizontal_east_half  # Check if horizontal pill is needed
        
        
        get_vertical_south_half:
            addi $a0, $a0, 1     # Move to the next row for vertical pill
            jal GET_CELL_GRID_ADDRESS     # Paint the second square of the pill
            lw $v1, 4($v0)
            j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the horizontal part
        
        
        get_horizontal_west_half:
            addi $a1, $a1, -1     # Move to the next column for horizontal pill
            jal GET_CELL_GRID_ADDRESS     # Paint the second square of the pill
            lw $v1, 4($v0)
            j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the vertical part
        
        
        get_vertical_north_half:
            addi $a0, $a0, -1     # Move to the next column for horizontal pill
            jal GET_CELL_GRID_ADDRESS     # Paint the second square of the pill
            lw $v1, 4($v0)
            j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the vertical part
        
        
        get_horizontal_east_half:
            addi $a1, $a1, 1     # Move to the next column for horizontal pill
            jal GET_CELL_GRID_ADDRESS     # Paint the second square of the pill
            lw $v1, 4($v0)
            j end_EXTRACT_CURRENT_PILL_COLOR      # Skip the vertical part
        
        
        end_EXTRACT_CURRENT_PILL_COLOR:
            move $v0, $t2
            return()


    LOAD_NEW_PILL:
        
        addstack()
        
        lw $a0, initial_pill_row        # Draw the initial pill at the specified position
        lw $a1, initial_pill_col
        jal GET_CELL_GRID_ADDRESS
        lw $s6 4($v0)
        beq $s6 0x010100 continue_LOAD_NEW_PILL
        jal SLEEP1000
        jal GAME_OVER
        j end_LOAD_NEW_PILL
        
        continue_LOAD_NEW_PILL:
        li $t9, 0
        move_left_LOAD_NEW_PILL:
            lw $t0, pill_queue_row
            lw $t1, pill_queue_col
            lw $t2, pill_queue_address
            add $t1, $t1, $t9
            
            move $a0, $t0
            move $a1, $t1
            li $a2, 3
            jal REMOVE_PILL
            
            subi $t9, $t9, 1
            lw $t0, pill_queue_row
            lw $t1, pill_queue_col
            add $t1, $t1, $t9
            move $a0, $t0
            move $a1, $t1
            li $a2, 3
        
            lw $s7, 0($t2)
            lw $s6, 4($t2)
            jal DRAW_PILL
            jal PAINT_DISPLAY
            jal SLEEP50
            
            bne $t9, -16, move_left_LOAD_NEW_PILL
            
        lw $t0, pill_queue_row
        lw $t1, pill_queue_col
        lw $t2, pill_queue_address
        add $t1, $t1, $t9
        move $a0, $t0
        move $a1, $t1
        li $a2, 3
        jal REMOVE_PILL
        
        lw $t0, pill_queue_row
        lw $t1, pill_queue_col
        add $t1, $t1, $t9
        move $a0, $t0
        move $a1, $t1
        li $a2, 0
    
        lw $s7, 4($t2)
        lw $s6, 0($t2)
        jal DRAW_PILL
        jal PAINT_DISPLAY
        
        li $t4, 0
        
        move_down_LOAD_NEW_PILL:
            lw $t0, pill_queue_row
            lw $t1, pill_queue_col
            lw $t2, pill_queue_address
            add $t1, $t1, $t9
            add $t0, $t0, $t4
            
            move $a0, $t0
            move $a1, $t1
            li $a2, 0
            jal REMOVE_PILL
            
            addi $t4, $t4, 1
            lw $t0, pill_queue_row
            lw $t1, pill_queue_col
            add $t1, $t1, $t9
            add $t0, $t0, $t4
            move $a0, $t0
            move $a1, $t1
            li $a2, 0
        
            lw $s7, 4($t2)
            lw $s6, 0($t2)
            jal DRAW_PILL
            jal PAINT_DISPLAY
            jal SLEEP50
            
            bne $t4, 3, move_down_LOAD_NEW_PILL
            
        
        lw $t1, pill_queue_col
        addi $t1, $t1, 4
        lw $t7, pill_queue_address
        addi $t7, $t7, 32
            
        jal UPDATE_PILL_QUEUE
        return()
        

    UPDATE_PILL_QUEUE:
        addstack()
        
        lw $t1, pill_queue_col
        lw $t7, pill_queue_address
        
        li $t3, 0
        
        loop_UPDATE_PILL_QUEUE:
            lw $a0, pill_queue_row
            move $a1, $t1
            li $a2, 3
            
            lw $s6, 36($t7) 
            lw $s7, 32($t7)
            sw $s6, 4($t7)
            sw $s7, 0($t7)
            
            jal DRAW_PILL
            
            addi $t1, $t1, 4
            addi $t3, $t3, 1
            addi $t7, $t7, 32
            bne $t3, 4, loop_UPDATE_PILL_QUEUE
            
        lw $a0, pill_queue_row
        lw $a1, pill_queue_col
        addi $a1, $a1, 16 
        li $a2, 3
        jal RANDOM_COLOR
        move $s6, $v0
        sw $s6, 4($t7) 
        jal RANDOM_COLOR
        move $s7, $v0
        sw $s7, 0($t7)
        jal DRAW_PILL
        
        end_LOAD_NEW_PILL:
            
        return()
        





# End of: <PILL_METHODS
##############################################################################


##############################################################################
# Subsection: >PILL_GETTERS

    GET_PILL_ADDRESSES:
    
        addstack()

        move $a0, $s1
        move $a1, $s2
        jal GET_CELL_GRID_ADDRESS
        move $v1, $v0

        beq $s3, 0, vertical_south_GET_PILL_ADDRESS
        beq $s3, 1, horizontal_west_GET_PILL_ADDRESS
        beq $s3, 2, vertical_north_GET_PILL_ADDRESS
        beq $s3, 3, horizontal_east_GET_PILL_ADDRESS

        vertical_south_GET_PILL_ADDRESS:
            addi $a0, $a0, 1
            jal GET_CELL_GRID_ADDRESS
            j end_GET_PILL_ADDRESS

        horizontal_west_GET_PILL_ADDRESS:
            addi $a1, $a1, -1
            jal GET_CELL_GRID_ADDRESS
            j end_GET_PILL_ADDRESS

        vertical_north_GET_PILL_ADDRESS:
            addi $a0, $a0, -1
            jal GET_CELL_GRID_ADDRESS
            j end_GET_PILL_ADDRESS

        horizontal_east_GET_PILL_ADDRESS:
            addi $a1, $a1, 1
            jal GET_CELL_GRID_ADDRESS
            j end_GET_PILL_ADDRESS

        end_GET_PILL_ADDRESS:
            return()









# End of: <PILL_GETTERS
##############################################################################


##############################################################################
# Subsection: >VIRUS_METHODS

    DRAW_VIRUS:
        addstack()
        
        jal RANDOM_POSITION
        
        move $a0, $v0        # Draw the initial pill at the specified position
        move $a1, $v1
        jal GET_CELL_GRID_ADDRESS
        move $t9 $v0
        
        li $a2, 0
        jal RANDOM_COLOR
        move $s6, $v0
        
        sw $s6 4($t9)
        beq $s6 0xf8d210 draw_yellow_virus
        beq $s6 0xfa26a0 draw_red_virus
        beq $s6 0x2ff3e0 draw_blue_virus
        
        draw_yellow_virus:
        lw $s7 bright_yellow
        j set_color
        draw_red_virus:
        lw $s7 bright_red
        j set_color
        draw_blue_virus:
        lw $s7 aqua
        j set_color
        
        set_color:
        sub $s6 $s7 $s6
        sw $s6 8($t9)
        
        return() 








# End of: <VIRUS_METHODS
##############################################################################


##############################################################################
# Subsection: >GRAVITY_METHODS

    LET_CURRENT_PILL_FALL:
        addstack()
        lw $t9, game_grid_address
        bne $t9, $s0 end_LET_CURRENT_PILL_FALL
        jal GET_PILL_ADDRESSES
        move $a1 $v0
        move $a2 $v1
        jal falling_block
        
        li $a0, 1
        li $a1, 0
        move $a2, $s3
        jal UPDATE_CURRENT_PILL
        
        end_LET_CURRENT_PILL_FALL:
        return()              # Return from function








# End of: <GRAVITY_METHODS
##############################################################################


##############################################################################
# Subsection: >COLLISION_DETECTOR

    detect_left:
    add $a1 $a1 4
    add $a0 $a0 4
    add $v0 $zero $zero
    addi $t6 $zero -32 # Encodes the direction
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
    addi $t6 $zero 32
    addi $a1 $a1 32
    beq $a0 $a1 detect_case_b
    addi $a1 $a1 -64
    beq $a0 $a1 detect_case_a
    addi $a1 $a1 32
    j detect_case_c

    detect_case_a: # We check the half stored in $s4
    add $a1 $a1 $t6 # Reset after we shifted it to check the condition
    add $a1 $a1 $t6 # Check one block in direction t7

    lw $t5 0($a1)
    mult $t6 $t6 -1
    add $a1 $a1 $t6
    beq $t5 0x010100 chain_return
    addi $v0 $v0 1
    jr $ra

    detect_case_b: # We check the half stored in $s3
    sub $a1 $a1 $t6
    add $a0 $a0 $t6
    lw $t5 0($a0)
    mult $t6 $t6 -1
    add $a0 $a0 $t6
    beq $t5 0x010100 chain_return
    addi $v0 $v0 1
    jr $ra

    detect_case_c: # We need to check both halves of the capsule
    add $a0 $a0 $t6
    lw $t5 0($a0)
    sub $a0 $a0 $t6
    sub $a1 $a1 $t6
    beq $t5 0x010100 detect_case_a # In the case nothing is found after checking $s3
    add $a1 $a1 $t6
    addi $v0 $v0 1 # Immediate failure if we cannnot shift $s3
    jr $ra

    chain_return:
    jr $ra

    falling_block:

    addstack()
    addi $a1 $a1 4
    addi $a2 $a2 4

    # Requires t8, t9
    addi $t9 $zero 0
    addi $a0 $a1 0
    jal detect_fall
    addi $a0 $a2 0
    jal detect_fall

    beq $t9, 1, PREP_NO_UPDATE
    beq $t9 2 PREP_NO_UPDATE

    lw $ra, 0($sp)                  # Load saved $ra
    addi $sp, $sp, 4                # Restore stack pointer
    jr $ra

    PREP_NO_UPDATE:
    lw $ra, 0($sp)                  # Load saved $ra
    addi $sp, $sp, 4                # Restore stack pointer
    lw $ra, 0($sp)                  # Load saved $ra
    addi $sp, $sp, 4                # Restore stack pointer
    j post_fall

    PREP_DRAW_PILL:
    jal LOAD_NEW_PILL
    # jal DRAW_NEW_PILL
    lw $s1 initial_pill_row
    lw $s2 initial_pill_col
    li $s3 0
    j NO_UPDATE

    detect_fall:
    lw $a3, width
    mult $a3 $a3 16 # Divide by 2, multiply by 32
    add $a0 $a0 $a3 # Store address of one block below in a0
    lw $t8 0($a0) # Store value of one block below in t8
    beq $t8 0x010100 finish_detect_fall # If there is no block below, do nothing
    beq $a0 $a1 finish_detect_fall # If one half falls onto the other half, it is ok
    beq $a0 $a2 finish_detect_fall
    addi $t9 $t9 1
    finish_detect_fall:
    jr $ra




    delete_block: # Deletes t9 blocks
    addstack()

    mult $t7 $t7 -1 # Changes the direction
    j delete_block_down
    delete_block_iterate:
    add $s5 $s5 $t7 # Changes the pixel being deleted

    move $t5 $t7
    move $a0 $s5
    li $s7 0x010100
    sw $s7 0($s5)
    sw $zero 4($s5)
    move $t7 $t5

    jal chain_fall
    addi $t9 $t9 -1 # Decrease the counter
    beq $t9 $zero delete_return # If the counter is 0 we switch to the next instruction
    j delete_block_iterate # Otherwise we continue the loop

    delete_block_down:
    bge $t7 -32 delete_block_iterate
    mult $t6 $t9 $t7
    add $t6 $t6 $t7
    mult $t7 $t7 -1
    add $s5 $s5 $t6
    j delete_block_iterate

    delete_return:
    lw $ra, 0($sp)                  # Load saved $ra
    addi $sp, $sp, 4                # Restore stack pointer
    jr $ra

    # Lines 106-179 search for chains to delete

    post_fall:

    jal GET_PILL_ADDRESSES
    addi $v0 $v0 4
    addi $v1 $v1 4
    lw $t3 0($v0)

    skip_left_3:
    move $s5 $v0
    li $t9 1 # Sets counter t9 to 1
    li $t7 -32 # Pills are -32 apart

    left_loop_3:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 skip_right_3 # If the chain ends, check a different direction
    addi $t9 $t9 1
    j left_loop_3

    skip_right_3:
    # blt $t9 4 skip_right_3b
    # jal delete_block
    skip_right_3b:
    move $s5 $v0 # Reset s5
    # li $t9 1 # Sets counter t9 to 1
    li $t7 32 # Pills are 32 apart

    right_loop_3:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 skip_down_3
    addi $t9 $t9 1
    j right_loop_3

    skip_down_3:
    blt $t9 4 skip_down_3b
    jal delete_block
    skip_down_3b:
    move $s5 $v0 # Reset s5
    li $t9 1 # Sets counter t9 to 1
    lw $t7 width
    mult $t7 $t7 16

    down_loop_3:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 skip_up_3
    addi $t9 $t9 1
    j down_loop_3
    
    skip_up_3:
    # blt $t9 4 skip_up_3b
    # jal delete_block
    skip_up_3b:
    move $s5 $v0 # Reset s5
    # li $t9 1 # Sets counter t9 to 1
    lw $t7 width
    mult $t7 $t7 -16

    up_loop_3:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 skip_left_4
    addi $t9 $t9 1
    j up_loop_3

    skip_left_4:
    blt $t9 4 skip_left_4b
    jal delete_block
    skip_left_4b:
    lw $t3 0($v1)
    move $s5 $v1 # Reset s5
    li $t9 1 # Sets counter t9 to 1
    li $t7 -32 # Pills are -32 apart

    left_loop_4:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 skip_right_4 # If the chain ends, check a different direction
    addi $t9 $t9 1
    j left_loop_4

    skip_right_4:
    # blt $t9 4 skip_right_4b
    # jal delete_block
    skip_right_4b:
    move $s5 $v1 # Reset s5
    # li $t9 1 # Sets counter t9 to 1
    li $t7 32 # Pills are 32 apart
    right_loop_4:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 skip_down_4
    addi $t9 $t9 1
    j right_loop_4

    skip_down_4:
    blt $t9 4 skip_down_4b
    jal delete_block
    skip_down_4b:
    move $s5 $v1 # Reset s5
    li $t9 1 # Sets counter t9 to 1
    lw $t7 width
    mult $t7 $t7 16

    down_loop_4:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 skip_up_4
    addi $t9 $t9 1
    j down_loop_4
    
    skip_up_4:
    # blt $t9 4 skip_up_3b
    # jal delete_block
    skip_up_4b:
    move $s5 $v1 # Reset s5
    # li $t9 1 # Sets counter t9 to 1
    lw $t7 width
    mult $t7 $t7 -16

    up_loop_4:
    add $s5 $s5 $t7
    lw $t8 0($s5)
    bne $t8 $t3 finish_deletion
    addi $t9 $t9 1
    j up_loop_4

    finish_deletion:
    blt $t9 4 PREP_DRAW_PILL
    jal delete_block
    j PREP_DRAW_PILL

    chain_fall:
    move $s7 $s5

    chain_fall_iterate:
    li $t5 0
    lw $t6 width
    mult $t6 $t6 16

    repeat_fall:
    addi $t5 $t5 1 # Counts the number of spaces fallen
    sub $s7 $s7 $t6 # At this point s7 is the capsule to drop
    lw $t8 0($s7) # Load colour of capsule to drop
    li $s6 0x010100

    beq $t8 0x010100 chain_return # Exit if there is no capsule
    lw $s6 rosewater
    beq $t8 $s6 chain_return # Fix bug where the wall can fall
    li $s6 0x010100
    # Viruses cannot fallw
    lw $t8 4($s7)
    bne $t8 $zero chain_return
    lw $t8 0($s7)

    sw $s6 0($s7)
    add $s7 $s7 $t6 # s7 is one below the capsule to drop
    sw $t8 0($s7) #

    add $s7 $s7 $t6 # s7 is one below the place we just dropped to
    lw $t8 0($s7)

    beq $t8 0x010100 repeat_fall
    sub $s7 $s7 $t6
    mult $t6 $t6 $t5

    sub $s7 $s7 $t6
    j chain_fall_iterate










# End of: <COLLISION_DETECTOR
##############################################################################


##############################################################################
# Subsection: >KEYBOARD_HANDLERS

    CHECK_KEYBOARD_INPUT:
        
        addstack()
        
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
            beq $t2, 0x70, HANDLE_PAUSE
            beq $t2, 0x72, HANDLE_RETRY
            j end_CHECK_KEYBOARD_INPUT
        
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
            move $a2, $s3
            jal UPDATE_CURRENT_PILL

            jal PAINT_DISPLAY
            
            j end_CHECK_KEYBOARD_INPUT
            
        HANDLE_MOVE_RIGHT:
            jal GET_PILL_ADDRESSES
            move $a0 $v0
            move $a1 $v1
            jal detect_right
            bne $v0 $zero end_CHECK_KEYBOARD_INPUT
            
            li $a0, 0
            li $a1, 1
            move $a2, $s3
            jal UPDATE_CURRENT_PILL

            jal PAINT_DISPLAY

            j end_CHECK_KEYBOARD_INPUT
            
        HANDLE_ROTATE:
            jal GET_PILL_ADDRESSES  
            move $a0 $v0
            move $a1 $v1
            jal detect_left
            bne $s3, 0, left_border_rotation_clear
            bne $v0 $zero end_CHECK_KEYBOARD_INPUT
            left_border_rotation_clear:
            
            jal GET_PILL_ADDRESSES
            move $a0 $v0
            move $a1 $v1
            jal detect_right
            bne $s3, 2, right_border_rotation_clear
            bne $v0 $zero end_CHECK_KEYBOARD_INPUT
            right_border_rotation_clear:
        
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
                move $a2, $s3
                jal UPDATE_CURRENT_PILL
    
                jal PAINT_DISPLAY
            
            jal SLEEP1000
            jal RESET_INPUT_BUFFER
            
            lw $ra, 0($sp)       # Restore return address
            addi $sp, $sp, 4     # Restore stack pointer 
            j end_INPUT_LOOP
            
        HANDLE_PAUSE:
            lw $t9, game_grid_address
            beq $t9, $s0 show_pause_view
            lw $t9, message_grid_address
            beq $t9, $s0 show_game_view
            j end_INPUT_LOOP
            
            show_pause_view:
                jal DRAW_PAUSE_MESSAGE
                jal LOAD_MESSAGE_VIEW
                j end_INPUT_LOOP
                
            show_game_view:
                jal LOAD_GAME_VIEW
                j end_INPUT_LOOP
                
        HANDLE_RETRY:
            j main
              
        end_CHECK_KEYBOARD_INPUT:
            return()
            
            
    
        
    FIND_BOTTOM:

        addstack()
        
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
            jal GET_CELL_GRID_ADDRESS
            lw $t3, 4($v0)
            
            bne $t3, $t4, exit_BOTTOM_SEARCH_LOOP
            
            beq $s3 1 find_bottom_west
            beq $s3 3 find_bottom_east
            
            addi $t1, $t1, 1
            bne $t1, 31, BOTTOM_SEARCH_LOOP
        
        exit_BOTTOM_SEARCH_LOOP:
            subi $t1, $t1, 1
            move $v0, $t1
            j end_FIND_BOTTOM
            
        bottom_reached:
            move $v0, $s1
            j end_FIND_BOTTOM
        
        end_FIND_BOTTOM:
            return()
            
        find_bottom_west:
        
            move $a0, $t1
            move $a1, $s2
            addi $a1 $a1 -1
            jal GET_CELL_GRID_ADDRESS
            lw $t3, 4($v0)
            
            bne $t3, $t4, exit_BOTTOM_SEARCH_LOOP
            addi $t1, $t1, 1
            bne $t1, 31, BOTTOM_SEARCH_LOOP
            j exit_BOTTOM_SEARCH_LOOP
            
        find_bottom_east:
        
            move $a0, $t1
            move $a1, $s2
            addi $a1 $a1 1
            jal GET_CELL_GRID_ADDRESS
            lw $t3, 4($v0)
            
            bne $t3, $t4, exit_BOTTOM_SEARCH_LOOP
            addi $t1, $t1, 1
            bne $t1, 31, BOTTOM_SEARCH_LOOP
            j exit_BOTTOM_SEARCH_LOOP





# End of: <KEYBOARD_HANDLERS
##############################################################################


##############################################################################
# Subsection: >DRAWING_METHODS

    # Function: DRAW_BOTTLE
    # Draws a bottle shape by calling DRAW_RECTANGLE for different parts of the bottle.
    DRAW_BOTTLE:

        addstack()
        
        lw $s7, rosewater        # Load rosewater color
        
        li $a0, 4
        li $a1, 14
        li $a2, 7
        li $a3, 14
        jal DRAW_RECTANGLE # Left Neck
        
        li $a0, 4
        li $a1, 13
        li $a2, 4
        li $a3, 13
        jal DRAW_RECTANGLE # Left Mouth
        
        li $a0, 4
        li $a1, 18
        li $a2, 7
        li $a3, 18
        jal DRAW_RECTANGLE # Right Neck
        
        li $a0, 4
        li $a1, 19
        li $a2, 4
        li $a3, 19
        jal DRAW_RECTANGLE # Right Mouth
        
        li $a0, 7
        li $a1, 7
        li $a2, 7
        li $a3, 13
        jal DRAW_RECTANGLE # Left Body Top
        
        li $a0, 7
        li $a1, 19
        li $a2, 7
        li $a3, 25
        jal DRAW_RECTANGLE # Right Body Top
        
        li $a0, 7
        li $a1, 6
        li $a2, 31
        li $a3, 6
        jal DRAW_RECTANGLE # Left Body Side
        
        li $a0, 7
        li $a1, 26
        li $a2, 31
        li $a3, 26
        jal DRAW_RECTANGLE # Right Body Side
        
        li $a0, 31
        li $a1, 7
        li $a2, 31
        li $a3, 25
        jal DRAW_RECTANGLE # Bottom
        
        return()
        
        
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
        
        addstack()
        
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
                        jal SET_CELL_COLOR                        # Paint the current square
                        addi $t2, $t2, 1                        # Increment column counter
                        bne $t2, $t4, col_loop_DRAW_RECTANGLE   # Continue looping through columns until end
            
            addi $t1, $t1, 1                        # Increment row counter
            bne $t1, $t3, row_loop_DRAW_RECTANGLE   # Continue looping through rows until end
        
        return()


    DRAW_PAUSE_MESSAGE:
        addstack()
        
        jal INITIALIZE_MESSAGE_GRID
        
        li $a0, 29
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 0
        jal LOAD_LETTER_P
        jal DRAW_LETTER
        

        li $a0, 29
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 5
        jal LOAD_LETTER_A
        jal DRAW_LETTER
        
        li $a0, 29
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 10
        jal LOAD_LETTER_U
        jal DRAW_LETTER
        
        li $a0, 29
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1,15
        jal LOAD_LETTER_S
        jal DRAW_LETTER
        
        li $a0, 29
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 20
        jal LOAD_LETTER_E
        jal DRAW_LETTER
        
        li $a0, 29
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 25
        jal LOAD_LETTER_D
        jal DRAW_LETTER
        
        return()
        
    DRAW_GAME_OVER_MESSAGE:
        addstack()
        
        jal INITIALIZE_MESSAGE_GRID
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 0
        jal LOAD_LETTER_G
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        jal SLEEP200
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 5
        jal LOAD_LETTER_A
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        jal SLEEP200
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 10
        jal LOAD_LETTER_M
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        jal SLEEP200
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1,16
        jal LOAD_LETTER_E
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        jal SLEEP200
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 21
        jal LOAD_LETTER_SPACE
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 25
        jal LOAD_LETTER_O
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        jal SLEEP200
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 30
        jal LOAD_LETTER_V
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        jal SLEEP200
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 36
        jal LOAD_LETTER_E
        jal DRAW_LETTER
        jal PAINT_DISPLAY
        jal SLEEP200
        
        li $a0, 46
        jal GET_MESSAGE_OFFSET
        move $a0, $v0
        addi $a1, $v1, 41
        jal LOAD_LETTER_R
        jal DRAW_LETTER
        
        return()




# End of: <DRAWING_METHODS
##############################################################################


##############################################################################
# Subsection: >PAINTING_METHODS

    PAINT_DISPLAY:
        addstack()
        
        move $t0, $s0
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
                jal GET_CELL_DISPLAY_ADDRESS     # GetCell(row, col) stored in $v0
                lw $s7, 4($t0)              # load color
                
                # Untested
                lw $s6, 8($t0)
                add $s7, $s6, $s7
                
                # Store the calculated address in the game_grid_address array
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
        
        return()              # Return from function
        








# End of: <PAINTING_METHODS
##############################################################################


##############################################################################
# Subsection: >RANDOM_GENERATORS


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
        addstack()
        
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
            return()
        

    RANDOM_POSITION:
        addstack()

        li $v0, 42              # Load syscall code for random number generation
        li $a0, 0               # Lower bound for the random number
        li $a1, 19              # Upper bound (exclusive)
        syscall                 # Make syscall to generate random number
        addi $s6 $a0 7
        
        li $v0, 42              # Load syscall code for random number generation
        li $a0, 0               # Lower bound for the random number
        li $a1, 23              # Upper bound (exclusive)
        syscall                 # Make syscall to generate random number
        addi $v0 $a0 9
        move $v1 $s6
        
        return()







# End of: <RANDOM_GENERATORS
##############################################################################


##############################################################################
# Subsection: >VIEW_METHOD

    LOAD_MESSAGE_VIEW:
        addstack()
        lw $s0, message_grid_address
        jal PAINT_DISPLAY
        return()
        
        
    LOAD_GAME_VIEW:
        addstack()
        lw $s0, game_grid_address
        jal PAINT_DISPLAY
        return()
    
        

# End of: <DISPLAY_METHOD
##############################################################################


##############################################################################
# Subsection: >ETC

    SLEEP1000:
        addstack()

        li $v0, 32
        li $a0, 1000
        syscall
        
        return()
        
    SLEEP200:
        addstack()

        li $v0, 32
        li $a0, 200
        syscall
        
        return()
        
    SLEEP50:
        addstack()

        li $v0, 32
        li $a0, 50
        syscall
        
        return()
        
    RESET_INPUT_BUFFER:
        addstack()
        
        li $t1, 0
        
        lw $t0, ADDR_KBRD
        
        
        reset_loop:
            lw $t1, 0($t0)
            beqz $t1, end_reset_loop          # Exit if no key is ready
            lw $t2, 4($t0)     # Read key (clears the buffer entry)
            j reset_loop     
        
        end_reset_loop:
        return()

    
    GET_MESSAGE_OFFSET:
        
        addstack()
        
        lw $v1, width
        div $v1, $v1, 2
        sub $v1, $v1, $a0
        addi $v1, $v1, 2
        div $v1, $v1, 2
        
        lw $v0, height
        div $v0, $v0, 2
        sub $v0, $v0, 5
        div $v0, $v0, 2
        
        return()
        

# End of: <ETC
##############################################################################


##############################################################################
# Subsection: >LETTER_METHODS

    

# End of: <LETTER_METHODS
##############################################################################
    
    DRAW_LETTER:
    
        addstack()
        
        move $s5, $t7
        
        move $t2, $a0
        move $t3, $a1
        lw $t5, letter_address
        
        lw $t4, black
        li $t9, 0
        row_loop_DRAW_LETTER:
            
            li $t1, 0
            col_loop_DRAW_LETTER:

                move $a0, $t2
                move $a1, $t3
                jal GET_CELL_GRID_ADDRESS
                
                mul $t6, $t9, 5
                add $t6, $t6, $t1
                lw $t7, 0($t5)
                bne $t6, $t7, skip_drawing_cell
                
                sw $t4, 4($v0)
                addi $t5, $t5, 4
                skip_drawing_cell:

                addi $t1, $t1, 1
                addi $t3, $t3, 1
                bne $t1, 5, col_loop_DRAW_LETTER
        
        subi $t3, $t3, 5
        addi $t9, $t9, 1
        addi $t2, $t2, 1
        bne $t9, 5, row_loop_DRAW_LETTER
        
        move $t7, $s5
                
        return()
    
    
    LOAD_LETTER_P:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 8
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 11
        jal load_letter_value
        li $t1, 12
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 20
        jal load_letter_value
        
        return()
        
        load_letter_value:
            sw $t1, 0($t0)
            addi $t0, $t0, 4
            jr $ra
            
            
    LOAD_LETTER_A:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 8
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 13
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 16
        jal load_letter_value
        li $t1, 17
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 20
        jal load_letter_value
        li $t1, 23
        jal load_letter_value
        
        return()
        
        
    LOAD_LETTER_U:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 0
        jal load_letter_value
        li $t1, 3
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 8
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 13
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 21
        jal load_letter_value
        li $t1, 22
        jal load_letter_value
        
        return()
        
    LOAD_LETTER_S:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 3
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 11
        jal load_letter_value
        li $t1, 12
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 20
        jal load_letter_value
        li $t1, 21
        jal load_letter_value
        li $t1, 22
        jal load_letter_value
        
        return()
        
    LOAD_LETTER_E:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 3
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 11
        jal load_letter_value
        li $t1, 12
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 21
        jal load_letter_value
        li $t1, 22
        jal load_letter_value
        li $t1, 23
        jal load_letter_value
        
        return()


    LOAD_LETTER_D:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 0
        jal load_letter_value
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 8
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 13
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 20
        jal load_letter_value
        li $t1, 21
        jal load_letter_value
        li $t1, 22
        jal load_letter_value
        
        return()
    
    
    LOAD_LETTER_G:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 3
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 12
        jal load_letter_value
        li $t1, 13
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 21
        jal load_letter_value
        li $t1, 22
        jal load_letter_value
        li $t1, 23
        jal load_letter_value
        
        return()
        
LOAD_LETTER_M:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 0
        jal load_letter_value
        li $t1, 4
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 6
        jal load_letter_value
        li $t1, 8
        jal load_letter_value
        li $t1, 9
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 12
        jal load_letter_value
        li $t1, 14
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 19
        jal load_letter_value
        li $t1, 20
        jal load_letter_value
        li $t1, 24
        jal load_letter_value
        
        return()
        
    LOAD_LETTER_O:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 8
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 13
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 21
        jal load_letter_value
        li $t1, 22
        jal load_letter_value
        
        return()
        
        LOAD_LETTER_V:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 0
        jal load_letter_value
        li $t1, 4
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 9
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 14
        jal load_letter_value
        li $t1, 16
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 22
        jal load_letter_value
        
        return()
        
        LOAD_LETTER_R:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, 1
        jal load_letter_value
        li $t1, 2
        jal load_letter_value
        li $t1, 5
        jal load_letter_value
        li $t1, 8
        jal load_letter_value
        li $t1, 10
        jal load_letter_value
        li $t1, 11
        jal load_letter_value
        li $t1, 12
        jal load_letter_value
        li $t1, 15
        jal load_letter_value
        li $t1, 18
        jal load_letter_value
        li $t1, 20
        jal load_letter_value
        li $t1, 23
        jal load_letter_value
        
        return()
        
        LOAD_LETTER_SPACE:
        
        addstack()
        
        lw $t0, letter_address
        
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
        li $t1, -1
        jal load_letter_value
         
        return()
    


##############################################################################
# Subsection: >END_OF_CODE

    GAME_OVER:
        addstack()
        jal DRAW_GAME_OVER_MESSAGE
        jal LOAD_MESSAGE_VIEW
        return()
        
        
    END_MAIN:








# End of: <END_OF_CODE
##############################################################################









##############################################################################
# End of Code haha
##############################################################################