# How to check the zero-based index.

How many comparison operations it takes to check the occurrence of a value from 0 .. Count - 1.
index, fCount: Integer

How many comparison operations it takes to check the occurrence of a value from 0 .. Count - 1.
index, fCount: Integer

## Obvious implementation
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

## Unsigned Casting Implementation
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

## Implementation with System.SysUtils.Inrange
It would seem that we should get the same behavior when using the Inrange function from System.SysUtils,
but I didn't like the compiler code at all.

```
Oz.SGL.Test.pas.465: Assert(Inrange(index, 0, fHigh));
0066E41A 85DB             test ebx,ebx
0066E41C 0F9DC0           setnl al
0066E41F 3BFB             cmp edi,ebx
0066E421 0F9DC2           setnl dl
0066E424 84D0             test al,dl
0066E426 7514             jnz $0066e43c
0066E428 B9D1010000       mov ecx,$000001d1
0066E42D BA98E46600       mov edx,$0066e498
0066E432 B828E56600       mov eax,$0066e528
0066E437 E8A4C9D9FF       call @Assert
Oz.SGL.Test.pas.466: Assert(Inrange(Cardinal(index), 0, Cardinal(fHigh)));
0066E43C 8BC3             mov eax,ebx
0066E43E 33D2             xor edx,edx
0066E440 83FA00           cmp edx,$00
0066E443 7508             jnz $0066e44d
0066E445 83F800           cmp eax,$00
0066E448 0F93C1           setnb cl
0066E44B EB03             jmp $0066e450
0066E44D 0F9DC1           setnl cl
0066E450 8BC3             mov eax,ebx
0066E452 33D2             xor edx,edx
0066E454 52               push edx
0066E455 50               push eax
0066E456 8BC7             mov eax,edi
0066E458 33D2             xor edx,edx
0066E45A 3B542404         cmp edx,[esp+$04]
0066E45E 7508             jnz $0066e468
0066E460 3B0424           cmp eax,[esp]
0066E463 0F93C0           setnb al
0066E466 EB03             jmp $0066e46b
0066E468 0F9DC0           setnl al
0066E46B 83C408           add esp,$08
0066E46E 84C1             test cl,al
0066E470 7514             jnz $0066e486
0066E472 B9D2010000       mov ecx,$000001d2
0066E477 BA98E46600       mov edx,$0066e498
0066E47C B828E56600       mov eax,$0066e528
0066E481 E85AC9D9FF       call @Assert
```

I think the compiler developers have work to do.

In my opinion, of all the pascal compilers I have worked with, the best code generated was Pascal - 2 Oregon software for pdp-11.

Amazing register optimization. 
Carrying out expressions for cycles and much more.
This compiler generated better code than the C compiler.
