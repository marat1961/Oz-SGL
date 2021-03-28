Dictionaries, Hashing and Performance

The search speedup for hashmaps in this case is ~ 1/N, where N is the size of the table.

As long as the table is not completely filled with less than < 0.7
the table works well, and then comes performance degradation.

In such cases, the table size is increased and all data is moved to the new table.
This takes extra time and also means that while you do this, your system will not be able to serve clients.

In my opinion, up to about 16 elements, it is better to use a regular unsorted list and a linear search.
Then it makes sense to use either a TList with sorting each time a new key is added, ~ N * log2(N) for quicksort, or a tree where search and insertion with order maintenance is an inexpensive log2(N).

Advantages of hashmaps.
Search time for hashmap includes: hash generation + 1 to m equality comparisons.


Ideal hash function:
1. must be fast
2. Does not create collisions (does not generate the same key for different keys).

I have compared many hash functions in my time and realized that even the simplest ones provide good results on real data.

I have tested it on a database of addresses with about a million entries and for a client base with about 500,000 entries.
The algorithms included md5, sha-2, sha-3, src32, multiplicative hash.

For strings, a function that takes string length in characters into account when calculating the hash is useful.
For floating point numbers, it is better to use an algorithm that hashes the exponent and the mantissa of the number separately.
If it's an object or a record, sometimes it makes sense to write your own function that hashes selected key fields of the object.

I like hash table implementations with chains.
I usually know the approximate number of objects in the system and can immediately set the required input table size N.
This will require a bit more memory, but you know right away what the speedup will be and there will be no time wasted on dynamically increasing the table.

There is no point in increasing the size of the table much more than N.


Since the input index is determined by the search
index_input := hash mod N;

You can't choose a table size multiple of a byte, it increases the crowding of data in the table.

For many hashing algorithms, if you choose a size other than a prime number, the probability of collisions will increase and it will degrade the statistics.

