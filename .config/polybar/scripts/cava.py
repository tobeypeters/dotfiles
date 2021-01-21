#!/usr/bin/python3

#   The MIT License(MIT)
#   Copyright(c), Tobey Peters, https://github.com/tobeypeters
#	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
#	and associated documentation files (the "Software"), to deal in the Software without restriction,
#	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
#	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
#	subject to the following conditions:
#	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
#	LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#   This script converts cava's data output into fancy little bars. These values can range from 0 to 100
#   Distributed characters '▁▂▃▄▅▆▇█'.
#
#   Original Author : H45H74X
#            reddit : https://www.reddit.com/user/H45H74X/
#            Script : https://gitlab.com/linuxstuff/dotfiles/-/blob/master/.config/polybar/scripts/modules/cava.py

from argparse import ArgumentParser, RawTextHelpFormatter
from configparser import ConfigParser
from os import linesep, mkfifo, path, remove
from struct import unpack
from subprocess import Popen, STDOUT
from sys import exit, stdout
from time import sleep

parser = ArgumentParser(description="cava polybar parse script\nConverts cava raw " + \
    "values into characters and outputs to STDOUT or a fifo buffer.\n\nAdjust thresholds, " + \
    "characters and config directly in the script.\n\nIf the config file at 'CONFIG_PATH'" + \
    "(/tmp/cava_polybar.config) is messed up, simply delet it.", formatter_class=RawTextHelpFormatter)

parser.add_argument('-t', '-test', action='store_true', help='Run test mode (stdout only)')
parser.add_argument('-c', '-colors', nargs=2, help='Override the background and foreground colors.')

args = parser.parse_args()

# Path of the temporary cava configuration.
#
# Examples:
#   path.join(sep, "tmp", "cava_polybar.config")
CAVA_CONFIG_PATH = '/tmp/cava_polybar.config'

# The 'BAR_FACTOR' is used to calculate all those states and keep the code readable
# (See 'BAR_CHARACTERS')
BAR_FACTOR = 100 / 7

# Characters to display in the visualizer.
BC = [ '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' ]

# Configure resolution and style of the output here.
# The script fetches the cava output value and searches for the biggest matching key to get the character from
# (See 'BAR_FACTOR')
BAR_CHARACTERS = dict([
    (000, BC[0]),  # Zero output

    (BAR_FACTOR * 1, BC[1]),
    (BAR_FACTOR * 2, BC[2]),
    (BAR_FACTOR * 3, BC[3]),
    (BAR_FACTOR * 4, BC[4]),
    (BAR_FACTOR * 5, BC[5]),
    (BAR_FACTOR * 6 ZQS, BC[6]),

    (100, BC[7]),  # Highest output
])

def valueToCharacter(value):
    """
    Returns the respective character for specified value.

    Args:
        value ([int]): Value that should be mapped to a character
    """
    return BAR_CHARACTERS[BAR_FACTOR * (value // BAR_FACTOR)] if value < 100 else BAR_CHARACTERS[100]

if args.t:
    # Prints test data to stdout. Useful for checking resolution and customisation configuration

    print("\nBar Characters:")
    for bar_threshold in BAR_CHARACTERS:
        print('{:06.2f}: {}'.format(
            bar_threshold, BAR_CHARACTERS[bar_threshold]))

    print("\nValue Test:")
    for i in range(101):
        print('{:03d}: {}'.format(i, valueToCharacter(i)))

    exit(0)

# Separator Character between bars.
SEPARATOR = ' '

# Display no output if all bars are at minimum level (no sound output).
HIDE_WHEN_EMPTY = False

# Specify how long this script should wait before printing another value.
OUTPUT_DELAY = 0.0000

# Specify how many times cava can report "no sound" (all values are 0) 
# before the script detects it.
EMPTY_OUTPUT_THRESHOLD = 5

# If the script output should be written to a named pipe, specify the path here.
# Set to 'None' to disable FIFO output and print to STDOUT
PIPE_OUT = None

# The following data will be used in the temporary cava config.
# FIFO input pipe for raw cava data
# PIPE_IN = path.join(sep, "tmp", "cava_polybar_input.fifo")
PIPE_IN = "/tmp/cava_polybar_input.fifo"

# Number of bars in cava.  Default: 8
CAVA_BARS_NUMBER = 16

# Output bit format for cava.
# Can be 16bit ot 8bit, but 8 should be plenty of resolution for the default of 8 bars...
CAVA_BIT_FORMAT = "8bit"

bytetype, bytesize, bytenorm = ("H", 2, 65535) if (
    CAVA_BIT_FORMAT == "16bit") else ("B", 1, 255)

def output(string, file):
    def colorizeText(formatStr: str, formatColors: []) -> str:
        return f'%{{B{formatColors[0]}}}%{{F{formatColors[1]}}}{formatStr}%{{B- F-}}'

    """
    Write the given value either to STDOUT or user specified output pipe

    Args:
        string ([string]): String to print
        file ([file]): [description]
    """
    if (PIPE_OUT):
        file.write(string)
    else:
        print(string if not args.c else colorizeText(string, args.c), end="")
        stdout.flush()

    sleep(OUTPUT_DELAY)

# Create cava config start ##########
config = ConfigParser()

n = 'general'
config.add_section(n)
config.set(n, 'bars', str(CAVA_BARS_NUMBER))
config.set(n, 'overshoot', '0')

n = 'output'
config.add_section(n)
config.set(n, 'method', 'raw')
config.set(n, 'channels', 'mono')
config.set(n, 'mono_option', 'average')
config.set(n, 'raw_target', PIPE_IN)
config.set(n, 'bit_format', CAVA_BIT_FORMAT)

n = 'smoothing'
config.add_section(n)
config.set(n, 'integral', '0')

with open(CAVA_CONFIG_PATH, 'w') as configfile:
    config.write(configfile)
# Create cava config end ##########

# Create cava subprocess
cavaProcess = Popen(["cava", "-p", CAVA_CONFIG_PATH])
#    stdout=open(devnull, 'w'),
#    stderr=STDOUT
#)

exitCode = 0

if path.exists(PIPE_IN):
    inputPipe = open(PIPE_IN, "rb")

    # Open output pipe if specified
    outputPipe = None
    if (PIPE_OUT):
        print("The converted output can be found in " + PIPE_OUT)

        if path.exists(PIPE_OUT):
            remove(PIPE_OUT)

        mkfifo(PIPE_OUT)
        outputPipe = open(PIPE_OUT, "w")

#try:
    # Conversion process start ##########
    chunk = bytesize * CAVA_BARS_NUMBER
    fmt = bytetype * CAVA_BARS_NUMBER

    emptyOutputs = 0

    while True:
        rawData = inputPipe.read(chunk)
        if len(rawData) < chunk:
            break

        tstring = ""
        emptyOutput = True

        for i in unpack(fmt, rawData):
            value = int(i / bytenorm * 100)

            if (len(tstring) > 0):
                tstring += SEPARATOR
            
            tstring += valueToCharacter(value)

            if (value != 0):
                emptyOutput = False

        if (emptyOutput and HIDE_WHEN_EMPTY):
            emptyOutputs += 1
            if (emptyOutputs > EMPTY_OUTPUT_THRESHOLD):
                output("        " + linesep, outputPipe)
        else:
            emptyOutputs = 0
            output(tstring + linesep, outputPipe)
    # Conversion process end ##########
#except KeyboardInterrupt:
#    exitCode = 1

    # Close output pipe if needed
    if (PIPE_OUT):
        outputPipe.close()
        remove(PIPE_OUT)

    # Close input pipe and kill the subprocess    
    inputPipe.close()

cavaProcess.kill()
exit(exitCode)