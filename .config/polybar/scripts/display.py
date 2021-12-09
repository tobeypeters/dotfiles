#!/usr/bin/env python3

''' Ignore what you see in this script and go see the real version:
    https://github.com/Nathaniel-James/Nijikan/blob/master/Nijikan/display.py
'''

def main() -> None:
    import os
    import platform

    from typing import Final

    ''' Color "CONSTANTS" : start '''
    def color_str(color:int) -> str:
        return f'\u001b[{color}m'

    ''' Foreground color escape sequences '''
    BLACK: Final  = color_str(30)
    RED: Final     = color_str(31)
    GREEN: Final   = color_str(32)
    YELLOW: Final  = color_str(33)
    BLUE: Final    = color_str(34)
    MAGENTA: Final = color_str(35)
    CYAN: Final    = color_str(36)
    WHITE: Final   = color_str(37)

    ''' Background color escape sequences '''
    BG_BLACK: Final   = color_str(40)
    BG_RED: Final     = color_str(41)
    BG_GREEN: Final   = color_str(42)
    BG_YELLOW: Final  = color_str(43)
    BG_BLUE: Final    = color_str(44)
    BG_MAGENTA: Final = color_str(45)
    BG_CYAN: Final    = color_str(46)
    BG_WHITE: Final   = color_str(47)
    ''' Color CONSTANTS : end '''

    def bg_fg_col(num: int = 0, bg: bool = False) -> str:
        return f'\u001b[{48 if bg else 38};5;{num}m'

    area: list[str][str] = [] # Stores the contents of the next frame
    last: list[str][str] = [] # Stores the contents of the last frame

    ''' init()
        Used to set the title using ANSI escape codes - by default it is empty
        Used to set the terminal's row size using ANSI escape codes - by default it is 50
        Used to set the terminal's column size using ANSI escape codes - by default it is 100
    '''
    def init(title: str = '', rows: int = 50, cols: int = 100) -> None:
        if platform.system() == "Windows":
            os.system('color')
            os.system('cls')
        else:
            os.system('clear')

        print(f'\033]2;{title}\007') # CMD title
        print(f'\x1b[8;{rows};{cols}t') # CMD size

    ''' insert()
        Description:
            Inserts a character into the Display's area
            while also dynamically increasing the display area based on the coordinates given

        Parameters
        ----------
        text : str : The character that will be inserted into position x, y
        x: int  : The x coordinate of the character that will be replaced
        y: int  : The y coordinate of the character that will be replaced
        escape  : str : An ANSI escape sequence, set to None as a blank string
        bg: int : ANSI 256-colour code
        fg: int : ANSI 256-colour code
    '''
    def insert(text:str = '', x:int = 0, y: int = 0, escape:str = '', bg:int = 0, fg: int = 0) -> None:
        # Checking y for increase
        l = len(area)
        if y >= l:
            area.extend( [[]]*(y+1 - l) )

        lt = len(text)

        # Checking x for increase
        l = len(area[y])
        if x >= l:
            # Adding len(text) to the equation so insert can be
            # used with arguments bigger than 1 letter
            area[y].extend( [' ']*(x+1+lt - l) )

        # Inserting string into list
        for i in range(lt):
            # "\u001b[0m" is an ASNI reset code
            area[y][x+i] = f'{escape}{bg_fg_col(bg)}{bg_fg_col(fg, True)}{text[i]}\u001b[0m'

    ''' move()
        Description:
            Moves the target character to the destination.
            It replaces the target character's old position with the one from the previous frame

        Parameters
        ----------
        target_x: int      : The x coordinate of the target character
        target_y: int      : The y coordinate of the target character
        destination_x: int : The x coordinate of the destination to send the target character
        destination_y: int : The y coordinate of the destination to send the target character
    '''
    def move(target_x, target_y, destination_x, destination_y) -> None:
        area[destination_y][destination_x] = area[target_y][target_x]
        area[target_y][target_x] = last[target_y][target_x]

    ''' refresh()
        Description:
            Sets the cursor position to the start of the terminal.
            Then writes over the old contents, with the contents of the next frame.
    '''
    def refresh() -> None:
        # Setting cursor position
        print('\033[0;0H')

        # Handling the new frame
        for line in area:
            print(''.join(char for char in line))

        # Storing the current frame as the last frame
        last = area

    init(' Color program')

    # iterator generators are faster than list comprehension
    for color_num, color_name in enumerate( (str(c) for c in range(256)) ):
        insert(color_name, 0, color_num, fg=color_num)
        insert(color_name, 5, color_num, bg=color_num)

    refresh()

if __name__ == '__main__':
    main()
