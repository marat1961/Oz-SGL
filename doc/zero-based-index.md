# How to check the zero-based index.

How many comparison operations it takes to check the occurrence of a value from 0 .. Count - 1.
index, fCount: Integer

How many comparison operations it takes to check the occurrence of a value from 0 .. Count - 1.
index, fCount: Integer

It would seem that it could be easier and here we write the code:

`Assert((index >= 0) and (index < fCount), 'Array bounds error')`

This is exactly the message I saw when rangecheck was on. 
on my very first and favorite compiler for Pascal - 1 for PDP-11.
First love does not rust.

This is equivalent to two checks and if you open the CPU window 
we can see that this is indeed the case.
We use commands that take into account the upper character bit.
```
Oz.SGL.Test.pas.459: fCount := 5;
0066E55D C745F405000000 mov [ebp-$0c],$00000005

Oz.SGL.Test.pas.460: index := -2;
0066E564 C745F8FEFFFFFFF mov [ebp-$08],$fffffffe

Oz.SGL.Test.pas.461: Assert((index >= 0) and (index < fCount), 'Array bounds error');
0066E56B 837DF800 cmp dword ptr [ebp-$08],$00
0066E56F 7C08 jl $0066e579
0066E571 8B45F8 mov eax,[ebp-$08]
0066E574 3B45F4 cmp eax,[ebp-$0c]
0066E577 7C14 jl $0066e58d

0066E579 B9CD010000 mov ecx,$000001cd
0066E57E BABCE56600 mov edx,$0066e5bc
0066E583 B818E66600 mov eax,$0066e618
0066E588 E853C8D9FF call @Assert
```

Some microprocessors have special commands to check the entry of the index, 
who can perform this check with a single command.

But if you use the command of comparing unsigned numbers 
we can simplify the expression and write the following code

`Assert(Cardinal(index) < Cardinal(fCount), 'Array bounds error');`

and then we can do the same check using a single comparison.
This reduces the price of the check by exactly half.
```
Oz.SGL.Test.pas.462: Assert(Cardinal(index) < Cardinal(fCount), 'Array bounds error');
0066E58D 8B45F8 mov eax,[ebp-$08].
0066E590 3B45F4 cmp eax,[ebp-$0c]
0066E593 7214 jb $0066e5a9

0066E595 B9CE010000 mov ecx,$000001ce
0066E59A BABCE56600 mov edx,$0066e5bc
0066E59F B818E66600 mov eax,$0066e618
0066E5A4 E837C8D9FF call @Assert
```
Usually when debugging I try to remember to enable rangecheck.
But in the release version all checks are usually turned off.
That is, in training flights we fly with a parachute.
But in the combat flight (in the release version) we leave this parachute at home.
Then hackers use it to crack through our programs.
Do not forget to check at least the input buffer of your program.
