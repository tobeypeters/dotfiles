#!/usr/bin/env python3

""" The MIT License(MIT)
    Copyright(c), Tobey Peters, https://github.com/tobeypeters
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without restriction,
	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
	LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

""" grey_it.py, inspired by, @typehouse on TikTok
    Description:
        She was given an assignment to make an instagram filter, which can apply greyscale,
        sepia, reflection, and blur to images.

        I started thinking how I might implement greyscale and well ... here's one way.
        I might implement the others functions later.

        UPDATE: I added a sepia effect

        NOTE: Yes, I know PIL has image filters already. But, the purpose is to atleast
              manipulate the individual pixels myself.
"""

def main() -> None:
    from argparse import ArgumentParser, Namespace as arg_namespace
    from pathlib import Path
    from PIL import Image

    def is_file(parser, arg) -> str:
        if not Path(arg).is_file():
            parser.error(f'The image file {arg} does not exist!')

        return arg

    effect_list = ['GREY_SCALE', "SEPIA"]

    parser: ArgumentParser = ArgumentParser()
    parser.add_argument('--input_file', '--i', nargs=1,
        type=lambda f : is_file(parser, f),
        help='Input file name.', required=True)
    parser.add_argument('--output_file', '--o', nargs=1, type=str,
        help="Output file name. If not specified, the output filename \
              will be input_file, prefixed with 'rendered_'.")
    parser.add_argument('--effect', '--e', nargs=1, type=str.upper, choices=effect_list, \
        help='Effect want to apply.', required=True)
    args: arg_namespace = parser.parse_args()

    BLUE: str = "\033[1;34m"
    CYAN: str = "\033[1;36m"
    RED: str = "\033[1;31m"
    YELLOW: str = "\033[1;33m"
    RESET: str = "\033[0;37m"

    def show_progress(p: str):
        print(f' Applying {RED}{args.effect[0]}{RESET} to {YELLOW}{args.input_file[0]}{RESET} [ {p} ]\r', end='')

    def apply_effect(effect: str) -> None:
#        print('')
        print('\n grey_it.py, inspired by, @typehouse on TikTok:')
        for loop1 in range(image.size[0]): # for each column
            for loop2 in range(image.size[1]): # for each row
                if loop2 % 3:
                    p = f'-'
                else:
                    p = '\\' if loop2 % 2 else '/'

                show_progress(f'{CYAN}{p}{RESET}')

                r, g, b = image_data[loop1, loop2]

                if (effect == 'GREY_SCALE'):
                    c: int = int((0.299 * r) + (0.587 * g) + (0.114 * b))
                    image_data[loop1,loop2] = c, c, c

                if (effect == 'SEPIA'):
                    r = min(255, int((r * .393) + (g *.769) + (b * .189)))
                    g = min(255, int((r * .349) + (g *.686) + (b * .168)))
                    b = min(255, int((r * .272) + (g *.534) + (b * .131)))

                    image_data[loop1,loop2] = r, g, b

        show_progress('Done')
        print('')

    image: Image = Image.open(args.input_file[0])

    image_data = image.load()

    apply_effect(args.effect[0])

    image.save(args.output_file[0] if args.output_file
                                   else f'rendered_{Path(args.input_file[0]).name}')

if __name__ == '__main__':
    main()
