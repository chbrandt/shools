Bash Reference
==============

From the online gnu manual/reference text on Bash,
http://www.gnu.org/software/bash/manual/bashref, I put in collection here
some information for the records.

#Shell-Scripts
--------------

 * "When Bash runs a shell script, it sets the special parameter 0 to the 
name of the file, rather than the name of the shell"
 * "The arguments to the interpreter consist of a single optional argument
following the interpreter name on the first line of the script file,
followed by the name of the script file, followed by the rest of the
arguments."


#Bash-Variables
---------------

 * FUNCNAME: "An array variable containing the names of all shell functions
currently in the execution call stack. The element with index 0 is the name
of any currently-executing shell function. (...) This variable can be used 
with BASH_LINENO and BASH_SOURCE. Each element of FUNCNAME has corresponding 
elements in BASH_LINENO and BASH_SOURCE to describe the call stack. 
For instance, ${FUNCNAME[$i]} was called from the file ${BASH_SOURCE[$i+1]} 
at line number ${BASH_LINENO[$i]}. The caller builtin displays the current 
call stack using this information."


#Bourne-Shell-Builtins
----------------------

 * trap: "If a sigspec is 0 or EXIT, arg is executed when the shell exits. 
If a sigspec is DEBUG, the command arg is executed before every simple 
command, for command, case command, select command, every arithmetic for 
command, and before the first command executes in a shell function. 
If a sigspec is RETURN, the command arg is executed each time a shell 
function or a script executed with the . or source builtins finishes executing.
If a sigspec is ERR, the command arg is executed whenever a pipeline 
(which may consist of a single simple command), a list, or a compound
command returns a non-zero exit status, subject to the following conditions.
The ERR trap is not executed if the failed command is part of the command 
list immediately following an until or while keyword, part of the test 
following the if or elif reserved words, part of a command executed in 
a && or || list except the command following the final && or ||, any 
command in a pipeline but the last, or if the command’s return status 
is being inverted using !. These are the same conditions obeyed by the 
errexit (-e) option."


AWK
===

 * Select a block of text/code:
 `awk '/start_pattern/,/stop_pattern/' file`
  - Example: extract function definitions from a shell script:
  `awk '/\(\)/,/^}$/' script.sh


