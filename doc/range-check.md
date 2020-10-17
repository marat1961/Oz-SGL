# Range checking in library code

In the process of development on the level of the subject area you want to see the problem at the moment of its occurrence.
Memory destruction from outside the array may be detected too late.

In complicated cases, it may take **several days of your life** to find such an error.

Do you need to optimize your program?
And if necessary, for the program code more than adhere to the principle of Pareto 80/20 (here you probably need to amplify by 10 times) 98% of the time takes 2% of the code.
You need to optimize this 2%, and even if it is critical for you.

Even when I was programming microprocessors where the average execution time of one instruction was 3-10 µs LSI-11 and only 8-16k memory I was not saving on safety.
 
I programmed in Pascal with all the checks included.
And yet my program code was more functional and faster than the programs of my colleagues who programmed on Assembler.
I usually had a better program due to better Pascal code control.
When I was still young and green, immediately after graduating from the Radio Engineering Department of the university, with no specialized training in programming, I tried to detect a repeating code and to extract it to a parameterized subprogram.
I had my favorite book, "Algorithms and Data Structures", by Niklaus Wirth, Mir Publishing House, 1985, which is always next to me, although it already has a double glued cover and some pages are already scattered from use.

If my developed algorithm will work correctly for data in some value domain, I will add a check of this condition.
Unlike some of my colleagues who honor my uniform and think that the appearance of an error message is a bad tone.
Some of them do not show any errors or even close the error output.

I know what the mistake is and exactly where it happened. 
I will also try to react quickly and preferably close the problem by the evening and post an extraordinary release.
As a result, I don't have problems with my programs' support for a long time already.
As a result of this approach, I am mainly engaged in extending the functionality of my programs, rather than closing holes in them.

Rarely is 100% code coverage by tests in real projects.
And even 100% code coverage by tests does not guarantee absence of errors in the code.
If the logic is complex, there is no guarantee that every variant of a passing branch has been tested.
A test can detect an error, but tests do not guarantee that there are no errors in code.

In principle, an effectively implemented iterator could provide a fast and safety iteration of array elements.
For me it would be best if the iterator returned the element address.
it is possible to check the fields of the element and change something in it if necessary.

The fastest way to search is with sentinel, when we only compare values and do not check the element index.
To do this we add sentinel to the list at the end of the list and set the key value in sentinel.
```
p := List.First;
List.Sentinel.Key := x; 
while p.key <> x do Inc(p, Itemsize);
if p <> List.Sentinel then ...
```
At the end of the list we check which element we have reached if it means that the sentinel is not looking for it.
The structures with sentinel are not only a list.

The current version of the Delphi iterator is not quite perfect,
it requires the call of two methods.
It would be better if the iterator or list executed the code until it said "I did what I wanted".
```
DoSomething: TEnumFunc;﻿
list.Enumerate(DoSomething);
```