/* Regression test suite for the Small compiler and abstract machine */

/* Create the DLLs with:
 *   bcc32 -w -tWD -eamxFixed -DAMXEXPORT="__stdcall _export" -DAMX_NATIVE_CALL=__stdcall fixed.c amx.c
 *   bcc32 -w -tWD -eamxFloat -DAMXEXPORT="__stdcall _export" -DAMX_NATIVE_CALL=__stdcall float.c amx.c
 *   bcc32 -w -w-amb -tWD -DAMXEXPORT="__stdcall _export" -DAMX_NATIVE_CALL=__stdcall amxfile.c amx.c
 *   bcc32 -w -w-amb -tWD -DAMXEXPORT="__stdcall _export" -DAMX_NATIVE_CALL=__stdcall -DAMX_NOSTRFMT amxstring.c amx.c
 * Create PAWNRUN with:
 *   bcc32 -w -DFLOATPOINT;FIXEDPOINT -DAMX_NATIVE_CALL=__stdcall -DAMXDBG pawnrun.c amx.c amxcore.c amxcons.c amxdbg.c
 */

say 'This REXX file does several tests on the compiler and the abstract machine.'
say 'The test scrip assumes that both the compiler and the abstract machine can be'
say 'found in the parent directory of this directory.'
say ''
say 'The current system is' uname('S')'.'
say ''
say 'Requirements:'
say '   1. PAWNRUN is the ANSI C version (for most assertions)'
say '   2. PAWNRUN includes AMXDBG to parse debug information (test 3)'
say '   2. everything is compiled with assertions (test 40)'
say '   3. AMXCONS includes floating point support (tests 41, 43, 44, 46)'
say '   4. AMXCONS includes fixed point support (test 62)'
say '   5. DLLs/shared libraries "amxFixed" and "amxFloat" are present'
say '   6. the compiler uses FORTIFY for memory leakage checks (e.g. test 64)'
say 'For example builds (for Borland C++), see the comments in this REXX file.'
say 'You can abort the test run by entering "BYE" at any "test#" prompt.'

/* check whether we are running in Windows or Linux */
sysname = uname('S')
if sysname = WINNT | sysname = WIN2K | sysname = WINXP| sysname = WIN95 | sysname = WIN98 then
  iswin32 = 1
else
  iswin32 = 0

if iswin32 then
  do
    clearscreen = 'cls'
    pawncc      = '..\bin\pawncc'
    pawnrun     = '..\bin\pawnrun'
  end
else
  do
    clearscreen = 'clear'
    pawncc      = '../bin/pawncc'
    pawnrun     = '../bin/pawnrun'
  end

signal on syntax name syntax_err
trace O /* disable checking of the return code of the compiler */
testnumber = 0
do forever
  say ''
  call charout , 'test# '
  pull reply
  if reply = 'BYE' | reply = 'bye' | reply = 'QUIT' | reply = 'quit' then
    exit
  if reply = '' then
    testnumber = testnumber + 1
  else
    testnumber = reply

  clearscreen
  testfunc = 'test'||testnumber
  interpret 'signal' testfunc   /* interpret 'call' testfunc */
end

syntax_err:
  say 'All tests have been completed.'
  exit

test1:
  say '1. The compilation should issue error 17 ("undefined symbol").'
  say ''
  say '   Calling an undefined function.'
  say ''
  say 'Symptoms of detected bug: the compiler flags the error, but then crashes'
  say 'or hangs.'
  say '-----'
  pawncc ' -p UNDEF_FUNC_CALL= test1'
  return

test2:
  say '2. The following test should compile successfully.'
  say ''
  say '   Compiling a program that contains no native function call should compile'
  say '   correctly.'
  say ''
  say 'Symptoms of detected bug: the compiler aborts with an "out of memory" error.'
  say '-----'
  pawncc ' -p test1'
  return

test3:
  say '3. In the following test, a run-time assertion should fire (run time error 2),'
  say '   but NOT on line 11.'
  say ''
  say '   An assertion with a function call should give the correct line number.'
  say ''
  say 'Symptoms of detected bug: the abstract machine returns line 11, because'
  say 'that is the last line executed (through the function call).'
  say '-----'
  pawncc ' -d2 ASSERT_LINENO= test2'
  pawnrun ' test2.amx'
  return

test4:
  say '4. Obsolete test case, please ignore.'
/*
        Cascaded assignment test; specifically the "swap without temporary variable"
        trick. The epxression "a ^= b ^= a ^= b" swaps the values of a and b.

     Symptoms of detected bug: this does not work; it does not work in Java either.
     It is not a hard bug, but a dependency on the evaluation order of the parser.
 */
  say '-----'
/*  pawncc ' CASCADED_ASSIGN= test2'
    pawnrun ' test2.amx'
 */
  return

test5:
  say '5. The compilation should issue error 37 ("invalid string")'
  say ''
  say '   An unterminated string in a function that accepts a variable number of'
  say '   parameters re-enters the lexer indefinitely searching for the closing ")".'
  say ''
  say 'Symptoms of detected bug: the compiler produces garbage on the screen or'
  say 'crashes.'
  say '-----'
  pawncc ' UNTERMINATED_STRING= test2'
  return

test6:
  say '6. The following test should pass (with only warnings about unused symbols).'
  say ''
  say '   Array assignment (testing whether valid syntaxes pass).'
  say '-----'
  pawncc ' OKAY= test3'
  return

test7:
  say '7. The following THREE compilations should all issue error 47.'
  say ''
  say '   Array assignment: the following three tests attempt to assign arrays where'
  say '   the size does not match, or the size of an array is unspecified.'
  say '-----'
  pawncc ' WRONG_LENGTH_1= test3'
  pawncc ' WRONG_LENGTH_2= test3'
  pawncc ' WRONG_LENGTH_3= test3'
  return

test8:
  say '8. The compilation should issue error 6.'
  say ''
  say '   Array assignment: the program attempts to assign an array to an indexed cell'
  say '   in a second array. Both arrays have a single dimension. A cell cannot hold'
  say '   an array.'
  say '-----'
  pawncc ' INDEXED= test3'
  return

test9:
  say '9. Obsolete test, please ignore.'
  say ''
  say '   As of version 2.6, a function can return an array.'
  return

test10:
  say '10. The following test should compile successfully.'
  say ''
  say '    Line continuation (with a \ at the end of a line) could cause incorrect'
  say '    lines to be read.'
  say ''
  say 'Symptoms of detected bug: compiler error "symbol not found" with a symbol'
  say 'name "prinprint".'
  say '-----'
  pawncc ' LINE_CAT= test2'
  return

test11:
  say '11. The compilation should issue warning 217.'
  say ''
  say '    The infamous "dangling else" problem should be signalled to the user with'
  say '    a "loose indentation" warning.'
  say ''
  say 'Symptoms of detected bug: no warning message.'
  say '-----'
  pawncc ' -p DANGLING_ELSE= test1'
  return

test12:
  say '12. The compilation should issue warning 203.'
  say ''
  say '    An unused and uninitialized local variable should be flagged as "never'
  say '    used" (warning 203).'
  say ''
  say 'Symptoms of detected bug: warning message "assigned a value that is never'
  say 'used" (warning 204).'
  say '-----'
  pawncc ' -p UNUSED_LOCAL= test1'
  return

test13:
  say '13. The compilation should issue warning 219 for TWO variables.'
  say ''
  say '    A local variable with the name of a variable or function (or parameter) at'
  say '    a higher level should issue a warning (because it is not "clean" code and'
  say '    possibly an error).'
  say ''
  say 'Symptoms of detected bug: no warning message.'
  say '-----'
  pawncc ' -p LOCAL_SHADOWS= test1'
  return

test14:
  say '14. The following test should compile successfully.'
  say ''
  say '    Function names with upper case letters are valid.'
  say ''
  say 'Symptoms of detected bug: assertion failed (in the assembler)'
  say '-----'
  pawncc ' -p MIXED_CASE= test1'
  return

test15:
  say '15. The following test should compile successfully.'
  say ''
  say '    The "for" loop would remove all local symbols of the higher level if the'
  say '    index was not declared in expr1 of the "for" loop.'
  say ''
  say 'Symptoms of detected bug: compiler error for one or more unknown variable(s)'
  say 'and an assertion failed (in the staging submodule)'
  say '-----'
  pawncc ' -p FOR_DEL_LOCALS= test1'
  return

test16:
  say '16. The following test should compile successfully.'
  say ''
  say '    For systems that support long filenames (and filenames with embedded space'
  say '    characters), the code generator cannot use the space character as a name'
  say '    delimiter, when adding debugging information.'
  say ''
  say 'Symptoms of detected bug: assertion failure in the assembler stage.'
  say '-----'
  pawncc ' -d2 "test lfn"'
  return

test17:
  say '17. The following test should compile successfully.'
  say ''
  say '    A global variable that is a fairly large, uninitialized, array. This array'
  say '    should be initialized completely with zeros.'
  say ''
  say 'Symptoms of detected bug: when there are more than 16 array entries to set to'
  say 'zero, this causes an assertion failure in the assembler stage.'
  say '-----'
  pawncc ' -p UNINIT_ARRAY= test1'
  return

test18:
  say '18. The following test should compile successfully.'
  say ''
  say '    A prototyped function followed by its (identical) definition should'
  say '    compile.'
  say ''
  say 'Symptoms of detected bug: due to a string comparison error, the definition was'
  say 'considered *different* from its prototype if the parameter name is the same as'
  say 'the one on the prototype.'
  say '-----'
  pawncc ' -p PROTOTYPE_GOOD= test1'
  return

test19:
  say '19. The compilation should issue error 25.'
  say ''
  say '    Parameter names in a prototype must be identical to those in the function'
  say '    definition, otherwise the "named parameters" feature cannot work.'
  say ''
  say 'Symptoms of detected bug: the compiler accepted different parameter names (it'
  say 'rejected identical names; this bug is related to the previous one).'
  say '-----'
  pawncc ' -p PROTOTYPE_BAD= test1'
  return

test20:
  say '20. The compilation should issue error 22 (after warning 211).'
  say ''
  say '    An attempt to assign a value to a constant in a test should issue error 22'
  say '    and warning 211.'
  say ''
  say 'Symptoms of detected bug: the compiler detects the error but then fails in an'
  say 'assertion and/or crashes.'
  say '-----'
  pawncc ' -p LVAL_IN_TEST= test1'
  return

test21:
  say '21. The following test should compile successfully.'
  say ''
  say '    The example program contains valid declarations of public functions and'
  say '    public variables.'
  say '-----'
  pawncc ' test4'
  return

test22:
  say '22. The compilation should issue error 42.'
  say ''
  say '    A variable is declared both "public" and "native" (which is invalid).'
  say '-----'
  pawncc ' INVALID_PUBVAR= test4'
  return

test23:
  say '23. The next TWO compilations should each issue error 42.'
  say ''
  say '    Two functions are flagged as both "public" and "native" (which is invalid).'
  say '-----'
  pawncc ' INVALID_PUBFUNC1= test4'
  pawncc ' INVALID_PUBFUNC2= test4'
  return

test24:
  say '24. The compilation should issue error 56 TWICE.'
  say ''
  say '    Both function arguments and local variables cannot be "public".'
  say '-----'
  pawncc ' INVALID_PUBLOCAL= test4'
  return

test25:
  say '25. The compilation should issue warning 202 (too few parameters).'
  say ''
  say '    A function that expects two parameters of type array receives only one.'
  say '    Default parameter values are absent.'
  say ''
  say 'Symptoms of detected bug: the compiler issues the warning, but then crashes'
  say 'because it attempts to store the default value (which is not present) for the'
  say 'array.'
  say '-----'
  pawncc ' -p MISSING_PARM= test1'
  return

test26:
  say '26. The following test should compile successfully.'
  say ''
  say '    When semicolons to end a line are optional, a postfix operator may not'
  say '    start a line; the operator should be considered the prefix operator on the'
  say '    next line.'
  say ''
  say 'Symptoms of detected bug: the prefix operator on the next line was considered'
  say 'a postfix operator related to the previous line.'
  say '-----'
  pawncc ' -;- IMPLICIT_POSTFIX= test2'
  return

test27:
  say '27. The following test should compile successfully. The output of the program'
  say '    must be 3 lines with the number 40 and a 4th line with the number 41.'
  say ''
  say '    A reference argument to a function that is passed to another function by'
  say '    reference is actually passed by value.'
  say ''
  say 'Symptoms of detected bug: the value of the argument was not loaded in the'
  say 'primary register before pushing it onto the stack.'
  say '-----'
  pawncc ' REFERENCE_ARG= test2'
  pawnrun ' test2.amx'
  return

test28:
  say '28. The following test should compile successfully.'
  say ''
  say '    A string or a literal array that is passed to a function must be smaller'
  say '    or equal to the size of the array of the function''s formal argument.'
  say ''
  say 'Symptoms of detected bug: the compiler rejected all literal arrays (unless'
  say 'the function''s formal argument had an unspecified array size).'
  say '-----'
  pawncc ' PASS_LIT_ARRAY= test3'
  return

test29:
  say '29. The compilation should issue error 47 THREE times.'
  say ''
  say '    A string or a literal array that is passed to a function must be smaller'
  say '    or equal to the size of the array of the function''s formal argument.'
  say '-----'
  pawncc ' PASS_WRONG_LENGTH= test3'
  return

test30:
  say '30. The following test should compile successfully (with only warning 203). The'
  say '    output of the program must read "*** for 63".'
  say ''
  say '    This module has a label (unused) in a somewhat larger program.'
  say ''
  say 'Symptoms of detected bug: wrong printout (or even a crash) due to the size of'
  say 'the "label" code not being accounted for in the code generation.'
  say '-----'
  pawncc ' test5'
  pawnrun ' test5.amx'
  return

test31:
  say '31. The compilation should issue error 1, expecting "#endif" before end of'
  say '    file.'
  say ''
  say '    The program has an #if 0 without a matching #endif before the end of'
  say '    compilation.'
  say ''
  say 'Symptoms of detected bug: silent complation (no error/warning message).'
  say '-----'
  pawncc ' test6'
  return

test32:
  say '32. The compilation should issue error 1, expecting "*/" before end of file.'
  say ''
  say '    The program has a /* without a matching */ before the end of compilation.'
  say ''
  say 'Symptoms of detected bug: silent complation (no error/warning message).'
  say '-----'
  pawncc ' test7'
  return

test33:
  say '33. The following test should compile successfully.'
  say ''
  say '    Conditional #endinput should reset the #if ... #endif nesting level.'
  say ''
  say 'Symptoms of detected bug: #if ... section was left open, causing an error'
  say 'message at file close.'
  say '-----'
  pawncc ' -i. test8'
  return

test34:
  say '34. The following test should compile successfully.'
  say ''
  say '    A recursive function that returns a value from a call to itself implicitly'
  say '    returns a value.'
  say ''
  say 'Symptoms of detected bug: warning 209 (function should return a value),'
  say 'because at the time the function is used, its definition is not yet complete.'
  say '-----'
  pawncc ' fibr'
  return

test35:
  say '35. The following test should issue warning 206. When it runs, it should print'
  say '    the string "Hello world".'
  say ''
  say '    Comparing two constants with the same value is redundant, but should'
  say '    generate valid code.'
  say ''
  say 'Symptoms of detected bug: invalid opcode assertion when running it. The'
  say 'redundant test was scrapped and this caused code following it to be scrapped as'
  say 'well.'
  say '-----'
  pawncc ' REDUNDANT_TEST= test2'
  pawnrun ' test2.amx'
  return

test36:
  say '36. The following test should issue warning 205. When it runs, it should print'
  say '    the string "Okay".'
  say ''
  say '    Comparing two constants with different values is redundant, but should'
  say '    generate valid code.'
  say ''
  say 'Symptoms of detected bug: invalid opcode assertion when running it. The jump'
  say 'around the following code was scrapped too.'
  say '-----'
  pawncc ' REDUNDANT_CODE= test2'
  pawnrun ' test2.amx'
  return

test37:
  say '37. The following test should compile successfully. When it runs, it should'
  say '    print the "Result: 4".'
  say ''
  say '    The "true" and "false" expressions in a conditional operator should be'
  say '    equivalent.'
  say ''
  say 'Symptoms of detected bug: the expression "ident" was set to the second'
  say 'expression; this caused the comparison to be optimized away if it was a'
  say 'constant expression.'
  say '-----'
  pawncc ' COND_EXPR_CONST= test2'
  pawnrun ' test2.amx'
  return

test38:
  say '38. The following test should compile successfully. When it runs, it should'
  say '    print the "Result: 0".'
  say ''
  say '    When an argument "uses" its default value (the caller omitted the argument)'
  say '    and that argument is a const array, the compiler does not need to copy the'
  say '    default value to the heap. It can instead pass the address of the default'
  say '    value, since the function does not modify it (it is "const").'
  say ''
  say 'Symptoms of detected bug: the compiler does NOT copy the default value to'
  say 'the heap, but it DOES try to remove it from the heap after the call. This'
  say 'causes a "heap underflow" error.'
  say '-----'
  pawncc ' DEF_ARRAY_ARG= test2'
  pawnrun ' test2.amx'
  return

test39:
  say '39. The following test should issue error 1, expecting ":" (THREE times).'
  say ''
  say '    The colons on case statements in a switch are missing, this should be'
  say '    flagged.'
  say ''
  say 'Symptoms of detected bug: the compiler hangs (it drops in an endless loop and'
  say 'does not finish compilation).'
  say '-----'
  pawncc ' -p SWITCH_NO_COLONS= test1'
  return

test40:
  say '40. The following test should compile successfully. When it runs, it does not'
  say '    print anything, but it should not drop in an assertion.'
  say ''
  say '    Note: you must have the ANSI C version of PAWNRUN to get the assertions.'
  say ''
  say '    The sample has a "for" loop with a new variable in its first expression.'
  say '    A break in the loop must not delete that variable, as the "exit code" of'
  say '    the for loop does this already.'
  say ''
  say 'Symptoms of detected bug: an assertion for a stack mismatch (caused by a double'
  say 'delete).'
  say '-----'
  pawncc ' -p FOR_BREAK_LCLVAR= test1'
  pawnrun ' test1.amx'
  return

test41:
  say '41. The following test should compile successfully. When it runs, it should'
  say '    print the values:'
  say '           p1=3.141500  p2=5.000000  p3=0.000000'
  say '           sum=8.141500'
  say '           product=15.707500'
  say '           quotient=0.628300'
  say '           negated=-0.628300'
  say ''
  say '    You must have a version of PAWNRUN that includes floating point support.'
  say ''
  say 'Symptoms of detected bug: stock user-defined operators were flagged as illegal'
  say 'declarations.'
  say '-----'
  pawncc ' USEROP_STOCK= float'
  pawnrun ' float.amx'
  return

test42:
  say '42. The following test should issue error 021 (symbol already defined).'
  say ''
  say '    An enum and a variable are declared at the same scope and with the same'
  say '    name.'
  say ''
  say 'Symptoms of detected bug: the compiler crashed.'
  say '-----'
  pawncc ' -p REDECL_ENUM_VAR= test1'
  return

test43:
  say '43. The following test should compile successfully. When it runs, it should'
  say '    print the value:'
  say '           F=3.750'
  say ''
  say '    You must have a version of PAWNRUN that includes floating point support.'
  say ''
  say 'Symptoms of detected bug: due to a code generation bug when both parameters of'
  say 'user-defined operators are constants, one of these was NOT loaded into a'
  say 'register and pushed onto the stack.'
  say '-----'
  pawncc ' USEROP_CONSTPARAMS= float'
  pawnrun ' float.amx'
  return

test44:
  say '44. The following test should compile successfully. When it runs, it should'
  say '    print:'
  say '           Bigger'
  say '           Unequal'
  say ''
  say '    You must have a version of PAWNRUN that includes floating point support.'
  say ''
  say 'Symptoms of detected bug: the program compiles bug crashes when run. The code'
  say 'generation fault only occurs when compiling with debug info. (It is caused by'
  say 'the symbol renaming with user-defined operators and symbol length variations).'
  say '-----'
  pawncc ' -d2 USEROP_DEBUGINFO= float'
  pawnrun ' float.amx'
  return

test45:
  say '45. The following test should issue error 017 ("undefined symbol") TWICE.'
  say ''
  say '    A global variable is declared in the main file, but used in a file that is'
  say '    included *before* the declaration.'
  say '    The program uses the "printf" function, but does not include console.inc.'
  say ''
  say 'Symptoms of detected bug: error 004 ("function not implemented") on printf,'
  say 'no error on the variable, but the variable is not created either.'
  say '-----'
  pawncc ' -p menumain'
  return

test46:
  say '46. The following test should compile successfully. When it runs, it should'
  say '    print:'
  say '           "a" okay'
  say '           "b" okay'
  say ''
  say '    The script contains an expression with chained relational operators, like'
  say '    "if (0.0 <= b <= 10.0) ...", where "<=" is a user-defined operator (in this'
  say '    case, working on "float:" tags).'
  say ''
  say 'Symptoms of detected bug: "tag mismatch" warning, plus that the value of the'
  say 'ALT register should be saved around the call to the user-defined operator, as'
  say 'the user-defined operator is likely to clobber it.'
  say '-----'
  pawncc ' -d2 USEROP_CHAINOP= float'
  pawnrun ' float.amx'
  return

test47:
  say '47. The following test should compile successfully. When it runs, it should'
  say '    print:'
  say '           result = First'
  say '           result = Second'
  say ''
  say '    The has expression a conditional operator (a ? b : c) where b and c are'
  say '    arrays (strings); this construct appears inside a printf().'
  say ''
  say 'Symptoms of detected bug: the conditional operator marked the result as an'
  say '"expression" (with a numeric value) instead of as an array. When passed to'
  say 'printf(), the address of the expression was passed instead of its value instead'
  say 'of its value (which is the address of the appropriate array).'
  say '-----'
  pawncc ' COND_OPER_ARRAY= test2'
  pawnrun ' test2.amx'
  return

test48:
  say '48. The following test should issue error 017 (undefined symbol) TWICE.'
  say ''
  say 'Symptoms of detected bug: in the first pass, an error is detected, but'
  say 'swallowed. The compiler then misses a synchronization point to restart parsing,'
  say 'and then sees a function call as a function declaration. This causes the'
  say 'error to go undetected in the second pass.'
  say '-----'
  pawncc ' test9'
  return

test49:
  say '49. The following test should issue error 025 (function header differs from'
  say '    prototype).'
  say ''
  say '    A function is re-declared with more parameters (the first parameters match'
  say '    the previous definition).'
  say ''
  say 'Symptoms of detected bug: the function argument verification loop did not'
  say 'check for the number of arguments in the previous definition, and so it could'
  say 'cause a protection faulth when comparing the last (new) argument with the'
  say 'non-existing old declaration.'
  say '-----'
  pawncc ' -p REDECLARE_EXPAND= test1'
  return

test50:
  say '50. The following test should compile successfully.'
  say ''
  say '    A stock function is never used. In its body it calls a function that is not'
  say '    implemented. This is okay, as long as the function is indeed never used.'
  say ''
  say 'Symptoms of detected bug: the compiler drops in an assertion because it assumes'
  say 'that a function symbol in its tables is either called or defined (or both). In'
  say 'the case of stock functions, the "called" bit may not get set.'
  say '-----'
  pawncc ' -p MISSING_UNUSED_FUNC= test1'
  return

test51:
  say '51. The following test should issue warning 209.'
  say ''
  say '    A program uses the value of a function, but the function does not return'
  say '    a value.'
  say ''
  say 'Symptoms of detected bug: the warning was absent when the function result was'
  say 'used in a variable declaration (initialization).'
  say '-----'
  pawncc ' -p NO_RETURN= test1'
  return

test52:
  say '52. The following test should issue error 021 (followed by more errors).'
  say ''
  say '    Declaring a function with the same name as an existing global variable.'
  say ''
  say 'Symptoms of detected bug: the compiler crashed, because it attempted to compare'
  say 'the argument lists of the new and the old declaration (the variable does not'
  say 'have a parameter list, of course).'
  say '-----'
  pawncc ' -p REDECLARE_VAR_FUNC= test1'
  return

test53:
  say '53. The following TWO tests should BOTH issue warning 225 (unreachable code).'
  say ''
  say '    Code following a "return" statement at the same compound block level is'
  say '    unreachable. This exhibit of inefficient coding probably hides an error.'
  say ''
  say '    A more advanced test also checks whether both branches of an "if" statement'
  say '    end with a "return". If so, the "return" is in fact unconditional.'
  say '-----'
  pawncc ' -p UNREACHABLE_CODE1= test1'
  pawncc ' -p UNREACHABLE_CODE2= test1'
  return

test54:
  say '54. The following test should issue warning 226 TWICE (226 = self-assignment).'
  say ''
  say '    A statement like "x=x" displays inefficient coding, but it might hide an'
  say '    error. The first warning is for a simple assignment, the second for an'
  say '    array assignment.'
  say '-----'
  pawncc ' -p SELF_ASSIGNMENT= test1'
  return

test55:
  say '55. The following TWO tests should both issue error 003.'
  say ''
  say '    A declaration of a local variable as the only statement of a function or a'
  say '    if/for/while/do statement is useless. Due to implementation difficulties,'
  say '    it is flagged as "invalid".'
  say '-----'
  pawncc ' -p USELESS_DECLARE1= test1'
  pawncc ' -p USELESS_DECLARE2= test1'
  return

test56:
  say '56. The following test should compile successfully. Then, on execution, it'
  say '    should halt with run-time error 4 (bounds-check).'
  say ''
  say '    An attempt to access an array element that is just out of bounds should'
  say '    cause this run-time error.'
  say ''
  say 'Symptoms of detected bug: being 1 element beyond the array bounds was not'
  say 'flagged (e.g. "new array[10]; new x = array[10];" worked).'
  say '-----'
  pawncc ' -p OUT_OF_BOUNDS= test1'
  pawnrun ' test1.amx'
  return

test57:
  say '57. The following test should give warning 203, but the compiler should not'
  say '    drop into an assertion.'
  say ''
  say '    This example declares an array at the bottom of the file, which is legal.'
  say ''
  say 'Symptoms of detected bug: an assertion, because the literal queue was not'
  say 'cleared correctly. When a function followed the array, the literal queue was'
  say 're-initialized, so there is no error in the common case (variables must be'
  say 'declared before use).'
  say '-----'
  pawncc ' -p LITERAL_QUEUE= test1'
  return

test58:
  say '58. The following test should issue error 052 and ONLY error 052.'
  say ''
  say '    2-dimensional arrays must be completely initialized (or not at all).'
  say '    Partial initialization is not allowed.'
  say ''
  say 'Symptoms of detected bug: after detecting the error, the compiler proceded with'
  say 'trying to find expressions that are initializers of a sub-array. This may end'
  say 'up "eating" part of other declarations or functions, or attempting to read past'
  say 'the end of file.'
  say '-----'
  pawncc ' INCOMPLETE_2D_ARRAY= test10'
  return

test59:
  say '59. The following test should compile successfully. On execution, it should'
  say '    print:'
  say ''
  say '       Before: 0'
  say '       After:  1'
  say ''
  say '    An variable that is passed to printf() and post-incremented (for example'
  say '    printf("%d", a++)) must pass the old value, not the new value.'
  say ''
  say 'Symptoms of detected bug: the compiler passed the address of the variable, in'
  say 'this particular case an incorrect optimization because the post-incremented'
  say 'variable is no longer an lvalue.'
  say '-----'
  pawncc ' POST_INCREMENT_REF= test2'
  pawnrun ' test2.amx'
  return

test60:
  say '60. The following TWO tests should both issue error 032.'
  say ''
  say '    A negative array index is always out of bounds, whether it is used in an'
  say '    assignment or passed as a parameter.'
  say ''
  say 'Symptoms of detected bug: the compiler did not catch this bug.'
  say '-----'
  pawncc ' NEGATIVE_INDEX1= test2'
  pawncc ' NEGATIVE_INDEX2= test2'
  return

test61:
  say '61. The following TWO tests should both compile successfully, but drop into'
  say '    run-time error 4 ("out-of-bounds") when run'
  say ''
  say '    A negative array index is always out of bounds, whether it is used in an'
  say '    assignment or passed as a parameter.'
  say ''
  say 'Symptoms of detected bug: the run-time did not catch all instances of this bug.'
  say 'Note: when you compile without run-time checks (compiler option -d0), you'
  say 'should still get run-time error 5 ("memory access").'
  say '-----'
  pawncc ' NEGATIVE_INDEX3= test2'
  pawnrun ' test2.amx'
  pawncc ' NEGATIVE_INDEX4= test2'
  pawnrun ' test2.amx'
  return

test62:
  say '62. The following test should compile successfully. When run, compare the'
  say '    results with those printed in parantheses behind every result.'
  say ''
  say '    Note: the "off-by-0.001" error in raising to the 3rd power is a known'
  say '    problem that can only be fixed by using internal calculations with more'
  say '    than 3 decimals.'
  say '-----'
  pawncc ' tstfixed'
  pawnrun ' tstfixed.amx'
  return

test63:
  say '63. The following test should compile successfully.'
  say ''
  say '    Self-assignment is not the case when an unary operator is applied.'
  say ''
  say 'Symptoms of detected bug: warning 226 on expressions like "var = !var".'
  say '-----'
  pawncc ' -p NO_SELF_ASSIGNMENT= test1'
  return

test64:
  say '64. The following test should give error 021, but WITHOUT memory leakage report.'
  say ''
  say '    The compiler must use FORTIFY for memory leakage detection.'
  say ''
  say 'Symptoms of detected bug: A double declaration of a native function caused'
  say 'arguments to be allocated another time, as the prototype flag was cleared.'
  say '-----'
  pawncc ' DOUBLE_NATIVE_DECLARE= test2'
  return

test65:
  say '65. The following test should compile successfully. When run, it should print:'
  say '      Eenie, Meenie, Meinie, Moe'
  say '      Out Goes You'
  say ''
  say '    Tests for 2-dimensional arrays, where both the major and the minor'
  say '    dimensions are unspecified.'
  say '-----'
  pawncc ' -p array'
  pawnrun ' array.amx'
  return

test66:
  say '66. The following test should compile successfully. When run, it should print:'
  say '      Eenie, Meenie, Meinie, Moe'
  say '      Out Goes You'
  say ''
  say '    Basically the same test as the earlier release, but now with a mix of'
  say '    specified and non-specified dimensions.'
  say ''
  say 'Symptoms of detected bug: the compiler dropped into an assertion.'
  say '-----'
  pawncc ' -p MIX_DIMENSIONS= array'
  pawnrun ' array.amx'
  return

test67:
  say '67. The following test should compile successfully.'
  say ''
  say '    Calling a function before it is defined is valid in a 2-pass compiler.'
  say ''
  say 'Symptoms of detected bug: an assertion due to a parsing error after picking up'
  say 'the undefined function.'
  say '-----'
  pawncc ' CALL_BEFORE_DEF= test2'
  return

test68:
  say '68. The following FOUR tests should compile successfully. When run, each should'
  say '    print the lines:'
  say '        1,1,1,1|'
  say '        1,1,1,1|2,2,2,2|3,3,3,3|'
  say '        1,1,1,1|2,2,2,2|3,3,3,3|10,10,10,10|20,20,20,20|30,30,30,30|'
  say '-----'
  pawncc ' -v0 DIMxxx= array3d'
  pawnrun ' array3d.amx'
  pawncc ' -v0 DIMxx_= array3d'
  pawnrun ' array3d.amx'
  pawncc ' -v0 DIMx__= array3d'
  pawnrun ' array3d.amx'
  pawncc ' -v0 DIM___= array3d'
  pawnrun ' array3d.amx'
  return

test69:
  say '69. The following test should compile successfully.'
  say ''
  say '    The preprocessor should run over expressions in compiler directives; in'
  say '    parsing for text substitutions, omit substituting a symbol that follows the'
  say '    keyword "defined", as in "#if defined TESTMODE".'
  say ''
  say 'Symptoms of detected bug: an expression like "#if TESTMODE > 2" gave an error,'
  say 'because a "#define" does not put the name TESTMODE in the symbol table.'
  say '-----'
  pawncc ' -p PREPROCESS_DIRECTIVES= test1'
  return

test70:
  say '70. The following test should compile successfully.'
  say ''
  say '    Various tests on expressions using the conditional operator.'
  say ''
  say 'Symptoms of detected bug: the trailing colon of a tag name was mis-interpretted'
  say 'as the colon of the conditional operator. The new syntax requires such'
  say 'ambiguous expression to be contained in parantheses.'
  say '-----'
  pawncc ' -p TAGS_IN_COND_OPER_OK= test1'
  return

test71:
  say '71. The following test should issue warning 220 (followed by errors).'
  say ''
  say '    Using sub-expressions with tag overrides inside a conditional operator.'
  say ''
  say 'Symptoms of detected bug: the trailing colon of a tag name was mis-interpretted'
  say 'as the colon of the conditional operator. The new syntax requires such'
  say 'ambiguous expression to be contained in parantheses.'
  say '-----'
  pawncc ' -p TAGS_IN_COND_OPER_WRONG= test1'
  return

test72:
  say '72. The following test should compile successfully.'
  say ''
  say '    The control character "^" should still work when configured.'
  say ''
  say 'Symptoms of detected bug: the function detecting single-line comments did not'
  say 'consider the control character value, but used a hardcoded "\".'
  say '-----'
  pawncc ' -p -^^ CARET_CTRL_CHAR= test1'
  return

test73:
  say '73. The following test should give warning 229.'
  say ''
  say '    Arrays declared with different tags for their indices are not "coercible".'
  say ''
  say 'Symptoms of detected bug: this case was not detected in assignments.'
  say '-----'
  pawncc ' ARRAY_INDEX_TAG_ASSIGN= test11'
  return

test74:
  say '74. The following test should give warning 229.'
  say ''
  say '    Arrays declared with different tags for their indices are not "coercible".'
  say ''
  say 'Symptoms of detected bug: this case was not detected in function calls.'
  say '-----'
  pawncc ' ARRAY_INDEX_TAG_CALL= test11'
  return

test75:
  say '75. The following test should give error 25.'
  say ''
  say '    Arrays indices should be tag checked between declaration and definition.'
  say ''
  say 'Symptoms of detected bug: only array dimensions and sizes were checked (and the'
  say 'tag of an array cell), but not the tags of the indices.'
  say '-----'
  pawncc ' ARRAY_INDEX_TAG_DECL= test11'
  return

test76:
  say '76. The following test should compile successfully.'
  say ''
  say '    When copying an array into an indexed array, the index tag checking should'
  say '    be skipped.'
  say ''
  say 'Symptoms of detected bug: warning 229, which could not be avoided by whatever'
  say 'tag override you could think of.'
  say '-----'
  pawncc ' ARRAY_INDEX_TAG_ASSIGN2= test11'
  return

test77:
  say '77. The following test should compile successfully. When run, it should print:'
  say ''
  say '        one (should be one)'
  say '        exit = 2 (should be 2)'
  say ''
  say '    The expression between the parentheses of a switch stament has a side'
  say '    effect (like in "switch (a++) { ... }").'
  say ''
  say 'Symptoms of detected bug: When the expression between the parentheses of a'
  say 'switch stament had a side effect, part of the expression could be optimized'
  say 'out. This was due to the switch marking an "end of expression".'
  say '-----'
  pawncc ' SWITCH_SIDE_EFFECT= test2'
  pawnrun ' test2.amx'
  return

test78:
  say '78. The following test should compile successfully. When run, it should print:'
  say ''
  say '        5 5 5'
  say ''
  say '    Chained assignment of array elements (a[0] = a[1] = a[2] = 5).'
  say ''
  say 'Symptoms of detected bug: The compiler failed in an assertion.'
  say '-----'
  pawncc ' CHAINED_ARRAY_ASSIGN= test2'
  pawnrun ' test2.amx'
  return

test79:
  say '79. The following test should compile successfully.'
  say ''
  say '    Copy one array item into another, where one of these is a constant.'
  say ''
  say 'Symptoms of detected bug: The compiler issued warning 226 (self-assignment).'
  say '-----'
  pawncc ' -p ARRAY_CELL_ASSIGN_NOSELF= test1'
  return

test80:
  say '80. The following test should issue error 021, but NOT crash.'
  say ''
  say '    A field of an enumeration has the same name as another symbol.'
  say ''
  say 'Symptoms of detected bug: The compiler crashed; the redefinition was caught'
  say 'in the first pass (error messages are silenced), but the redefinition proceeded'
  say 'anyway (no "drop-out").'
  say '-----'
  pawncc ' ENUM_REDEFINES_SYM= test2'
  return

test81:
  say '81. The following test should compile successfully.'
  say ''
  say '    A constant (enumeration) passed to a function with variable arguments.'
  say ''
  say 'Symptoms of detected bug: The compiler crashed. Functions that accept variable'
  say 'arguments get those arguments "by reference". When it is a constant, it is'
  say 'copied to the heap. The "variable is written" usage flag is then also set. This'
  say 'flag overlapped with the "variable is an enumeration root" flag.'
  say '-----'
  pawncc ' CONST_WRITE_USAGE= test2'
  return

test82:
  say '82. The following test should compile successfully.'
  say ''
  say '    A long symbol name (26 characters) for a local variable.'
  say ''
  say 'Symptoms of detected bug: Although the compiler accepts symbol names up to 32'
  say 'characters, the peephole optimizer still had a test for a shorter name. The'
  say 'compiler dropped into an assertion for names over 21 characters.'
  say '-----'
  pawncc ' SYMBOL_TOO_LONG_FOR_OPTIMIZER= test2'
  return

test83:
  say '83. The following test should compile successfully. When running, it must print'
  say '    9 lines with "Hello world"'
  say ''
  say '    Several tests for string functions (insertion, deletion, selection, ...).'
  say '-----'
  pawncc ' strtst1'
  pawnrun ' strtst1'
  return

test84:
  say '84. The following test should compile successfully. When running, it must print'
  say '    lines where the value beginning each line must match the one following it.'
  say ''
  say '    More tests for string functions (number conversions).'
  say '-----'
  pawncc ' strtst2'
  pawnrun ' strtst2'
  return

test85:
  say '85. The following test should compile successfully. When running, it does not'
  say '    print anything, but it should not drop into an assertion.'
  say ''
  say '    Even more tests for string functions (searching and comparing).'
  say '-----'
  pawncc ' strtst3'
  pawnrun ' strtst3'
  return

test86:
  say '86. The following test should compile successfully. When running, it does not'
  say '    print anything, but it should not drop into an assertion.'
  say ''
  say '    A 3-dimensional array with a variable last dimension.'
  say ''
  say 'Symptoms of detected bug: The indirection table for the second level was copied'
  say 'over all instances of the second level, instead of being recalculated.'
  say '-----'
  pawncc ' -p MULTIDIM_ARRAY_VARDIM= test1'
  pawnrun ' test1'
  return

test87:
  say '87. The following test should issue error 052.'
  say ''
  say '    A 2-dimensional array with a variable last dimension and an incomplete'
  say '    initialization.'
  say ''
  say 'Symptoms of detected bug: The error was detected, but the compiler dropped in'
  say 'an assertion when proceeding to initialize the indirection tables.'
  say '-----'
  pawncc ' -p ARRAY_VARDIM_INCOMPLETE= test1'
  return

test88:
  say '88. The following test should issue error 009 (followed by others).'
  say ''
  say '    A 2-dimensional array with a variable last dimension and an absent'
  say '    initialization (due to a syntax error).'
  say ''
  say 'Symptoms of detected bug: The error was detected, but the compiler dropped in'
  say 'an assertion when proceeding to initialize the indirection tables.'
  say '-----'
  pawncc ' -p ARRAY_VARDIM_NONINIT= test1'
  return

test89:
  say '89. The following test should compile correctly. When run, it should print the'
  say '    values that follow behind in parentheses.'
  say ''
  say '    Various tests on arrays combined with enumerations.'
  say '-----'
  pawncc ' test12'
  pawnrun ' test12'
  return

test90:
  say '90. The following test should issue error 032.'
  say ''
  say '    Out-of-range error on an enumerated sub-array.'
  say ''
  say 'Symptoms of detected bug: the error was not detected, because the compiler'
  say 'used the size of the array symbol instead of the size of the enumeration field.'
  say '-----'
  pawncc ' OUT_OF_BOUNDS= test12'
  return

test91:
  say '91. The following test should compile successfully. When running, it must'
  say '    print the lines:'
  say '         7: 1abcdef'
  say '         7: 12abcde'
  say '         7: 123abcd'
  say '         7: 1234abc'
  say '         11: 1abcdefghij'
  say '         12: 12abcdefghij'
  say '         13: 123abcdefghij'
  say '         14: 1234abcdefghij'
  say '-----'
  pawncc ' strtst4'
  pawnrun ' strtst4'
  return

test92:
  say '92. The following test should compile successfully.'
  say ''
  say '    Named automatons (instead of the default).'
  say ''
  say 'Symptoms of detected bug: errors due to the parser not picking up the code'
  say 'correctly after seeing an automaton being used before declaration (in the'
  say 'scanning phase).'
  say '-----'
  pawncc ' NAMED_AUTOMATON= states'
  return

test93:
  say '93. The following TWO tests should BOTH issue error 088.'
  say ''
  say '    An attempt to declare public and local state variables.'
  say '-----'
  pawncc ' PUBLIC_STATE_VAR= test1'
  pawncc ' LOCAL_STATE_VAR= test1'
  return

test94:
  say '94. The following test should issue error 089.'
  say ''
  say '    An attempt to declare a state variable with an initialler.'
  say '-----'
  pawncc ' INITIALIZED_STATE_VAR= test1'
  return

test95:
  say '95. The following test should issue error 017 but NOT warning 219.'
  say ''
  say '    A function uses a local variable which it does not declare (error 017).'
  say '    Another function has a local variable with the same name. This is okay.'
  say ''
  say 'Symptoms of detected bug: in a special syntax (procedure call), the undeclared'
  say 'variable was interpreted as a function (use before declaration).'
  say '-----'
  pawncc ' WRONG_PROC_CALL= test13'
  return

test96:
  say '96. The following test should compile successfully.'
  say ''
  say '    A script using an include file, where the include file contains both a'
  say '    static and a stock function.'
  say ''
  say 'Symptoms of detected bug: a compiler crash, because the assembler could not'
  say 'find the static function (wrong file number).'
  say '-----'
  pawncc ' mainpgm'
  return

test97:
  say '97. The following test should issue warning 235.'
  say ''
  say '    A public function is not prototyped. This may indicate that the user typed'
  say '    the wrong name for the public function (so this is a warning for a common'
  say '    error.'
  say '-----'
  pawncc ' UNDECLARED_PUBLIC= test1'
  return

test98:
  say '98. The following test should compile successfully (without memory log).'
  say ''
  say '    A script predefining several (unused) public functions.'
  say ''
  say 'Symptoms of detected bug: a memory leak, because the tags of the forward'
  say 'declaration were not removed after unflagging the public function as'
  say 'prototyped.'
  say '-----'
  pawncc ' PROTOTYPED_PUBLIC= test1'
  return

test99:
  say '99. The following test should issue error 033 (array is not indexed).'
  say ''
  say '    Arrays in a logical expression, with && and ||, must always by fully.'
  say '    indexed.'
  say ''
  say 'Symptoms of detected bug: this was not checked by the compiler.'
  say '-----'
  pawncc ' ARRAY_LOGIC_EXPR= test1'
  return

test100:
  say '100. The following test should compile successfully. When running, it should'
  say '     print:'
  say ''
  say '         Passed a Sentient 2'
  say '         Passed a Foo 1'
  say '         Passed something else 0'
  say ''
  say '    The tagof operator with functions accepting multiple tags.'
  say ''
  say 'Symptoms of detected bug: tag was taken from a variable, not of an expression.'
  say '-----'
  pawncc ' TAGOF_PARAM= test2'
  pawnrun ' test2.amx'
  return

test101:
  say '101. The following test should issue error 009 (invalid array size)'
  say ''
  say '    An array that exceeds 4 GiB.'
  say ''
  say 'Symptoms of detected bug: no size check; invalid code generation.'
  say '-----'
  pawncc ' ARRAY_TOO_LARGE= test1'
  return

test102:
  say '102. The following test should issue warning 235 TWICE (missing forward'
  say '     declaration)'
  say ''
  say '    A public function calls another public function; there are no forward.'
  say '    declarations for the public functions.'
  say ''
  say 'Symptoms of detected bug: compiler crashed.'
  say '-----'
  pawncc ' INTERNAL_PUBLIC_CALL= test14'
  return

test103:
  say '103. The following test should issue warning 21 TWICE (redefined symbol)'
  say ''
  say '    Redefinition of constants.'
  say ''
  say 'Symptoms of detected bug: redefinition was silently allowed.'
  say '-----'
  pawncc ' REDEFINE_CONSTANTS= test1'
  return

test104:
  say '104. The following test should compile successfully'
  say ''
  say '    Redefinition of enumeration fields (with different tags) is allowed.'
  say '-----'
  pawncc ' REDEFINE_ENUM= test1'
  return

test105:
  say '105. The following TWO tests should BOTH compile successfully (NO error 38)'
  say ''
  say '    #elseif with an expression.'
  say ''
  say 'Symptoms of detected bug: #elseif did not parse through the expression when.'
  say 'it had already found a "true" case; it should parse and ignore the expression.'
  say '-----'
  pawncc ' ELSEIF_EXPR=1 test1'
  pawncc ' ELSEIF_EXPR=2 test1'
  return

test106:
  say '106. The following test should compile successfully. When running, it should'
  say '     print:'
  say ''
  say '        %1test'
  say ''
  say '    A pre-processor macro that contains a % in a string, which should be copied'
  say '    literally.'
  say ''
  say 'Symptoms of detected bug: the parameter was replaced (by an empty string).'
  say '-----'
  pawncc ' MACRO_PARM_INSTR= test2'
  pawnrun ' test2.amx'
  return

test107:
  say '107. The following test should issue warning 236 (followed by errors)'
  say ''
  say '    A pre-processor uses a parameter in replacement that is not in the source.'
  say ''
  say 'Symptoms of detected bug: the parameter would replaced by an empty string,'
  say 'without warning.'
  say '-----'
  pawncc ' MACRO_PARM_UNKNOWN= test2'
  return

test108:
  say '108. The following test should compile successfully. When running, it should'
  say '     print:'
  say ''
  say '        (+8,+3)  q=+2 r=+2'
  say '        (+8,-3)  q=-3 r=-1'
  say '        (-8,+3)  q=-3 r=+1'
  say '        (-8,-3)  q=+2 r=-2'
  say '        (+9,+3)  q=+3 r=+0'
  say '        (+9,-3)  q=-3 r=+0'
  say '        (-9,+3)  q=-3 r=+0'
  say '        (-9,-3)  q=+3 r=+0'
  say ''
  say '     Tests for floored division.'
  say '-----'
  pawncc ' FLOORED_DIVISION= test2'
  pawnrun ' test2.amx'
  return

test109:
  say '109. The following test should issue warning 225 (unreachable code)'
  say ''
  say '    Code below an infinite loop, which does not contain a "break".'
  say '-----'
  pawncc ' -p UNREACHABLE_CODE3= test1'
  return

test110:
  say '110. The following test should issue error 001 (expected an identifier instead'
  say '     of "new"), followed by other errors'
  say ''
  say '    you cannot mix expressions and variable declarations in a "for" loop.'
  say ''
  say 'Symptoms of detected bug: obscure error messages.'
  say '-----'
  pawncc ' FOR_MIX_EXPR_VAR= test1'
  return

test111:
  say '111. The following test should issue warning 215'
  say ''
  say '    With optional parentheses, expressions may become ambiguous.'
  say ''
  say 'Symptoms of detected bug: obscure error message followed by a crash.'
  say '-----'
  pawncc ' AMBIGUOUS_CALL= test1'
  return

test112:
  say '112. The following test should compile successfully; when run, it should print'
  say '     the value 2'
  say ''
  say '    Using the prefix increment operator in a return/exit/sleep statement.'
  say ''
  say 'Symptoms of detected bug: incorrect optimization.'
  say '-----'
  pawncc ' RETURN_WITH_INCR= test2'
  pawnrun ' test2.amx'
  return

test113:
  say '113. The following test should compile successfully; when run, it should print:'
  say ''
  say '         result=123'
  say '         result=1'
  say ''
  say '    Ternary operator combined with functions returning arrays.'
  say ''
  say 'Symptoms of detected bug: heap underflow, because heap was restored for either.'
  say 'branch, while only one branch is taken.'
  say '-----'
  pawncc ' COND_EXP_ARRAY= test2'
  pawnrun ' test2.amx'
  return

test114:
  say '114. The following test should compile successfully; when run, it should print'
  say ''
  say '         queue: 15%'
  say '         queue:'
  say ''
  say '    before dropping into run-time error 10 (native function failed)'
  say ''
  say '    The native printf function did not support %% correctly. The run-time error'
  say '    in this script is correct because the second printf lacks the parameter.'
  say ''
  say 'Symptoms of detected bug: heap underflow, because heap was restored for either.'
  say 'branch, while only one branch is taken.'
  say '-----'
  pawncc ' PRINTF_PCT= test2'
  pawnrun ' test2.amx'
  return

/* ??? global variable set to a negative floating point value */
