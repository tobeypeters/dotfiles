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

""" my_helper.py
    Description:
        Miscellaneous helper functions

"""

from pathlib import Path
from subprocess import check_output, Popen, PIPE, run
from timeit import default_timer
from typing import Any, Optional, Tuple, Union

def output_check(output_to_check: Any) -> Any:
	return check_output(output_to_check)

def process_exec(p_cmd: str, capture_output=False, capture_errors=False) -> Optional[Union[Tuple[str, str], str]]:
	""" Spawn an OS process, with Popen().  The output of the spawned process,
		can be captured and returned to the caller:

		args:
			 <p_cmd> : Command you want to execute.
			 <capture_output> : Capture the output of <p_cmd>
			 <capture_errors> : Capture the output of <p_cmd>

		returns:
			 no capture: <None>
			 capture_output: <str>
			 capture_errors: <str>
			 capture_output & capture_errors: <(str, str)>
    """
	args = {'shell': True}

	if not capture_output:
		Popen(p_cmd, **args)

		return None

	args.update({'stdout': PIPE, 'stderr': PIPE})

	p = Popen(p_cmd, **args)
	output, errors = p.communicate()

	"""
	print(f'p_cmd: {p_cmd} {args}')
	print(f'output: {output} errors: {errors}')
	"""

	decode_args: dict[str, str] = {'encoding': 'utf-8', 'errors' : 'ignore'}

	if capture_output:
		output = output.decode(**decode_args)

	if capture_errors:
		errors = errors.decode(**decode_args)

	if capture_output and capture_errors:
		return (output, errors)

	return output if capture_output else errors

def gen_path_file(file: str, path: str, f_args: str = '', path_obj: bool = False) -> Union[str, Path]:
	""" Generates a filepath string or Path object.

		args:
			 <file> : name of file
			 <f_args> : arguments to append to the end
			 <path> : Desired file path
			 <path_obj> : Return a Path object, instead of a str

		returns:
			 path_obj : False : <str>
			 path_obj : True :  <Path>
	"""

	ret_val: Path = Path.joinpath(Path(path).parent, file)

	if f_args:
		ret_val = Path(f'{ret_val} {f_args}')

	return f'{ret_val}' if not path_obj else ret_val

# Decorators: start
def debug_timer(func):
	def wrapper(*args, **kwargs):
		starttime = default_timer()
		func(*args, **kwargs)
		print(f'Execution time of <{func}>: ', default_timer() - starttime)

def debug_func_start_ends(func):
    def wrapper(*args, **kwargs):
        cmd = f"notify-send 'cycle.py:' '{func.__name__} "
        process_exec(f"{cmd}started'")
        func(*args, **kwargs)
        process_exec(f"{cmd}ended'")

    return wrapper
# Decorators: end
