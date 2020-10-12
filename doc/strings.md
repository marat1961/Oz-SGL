# String repository

## Why is it good

Managed data types have a lot of overhead.
This also applies to string type.
I am already coming to the idea that in some places it would be useful to use some kind of repository for strings.
Then we could use PChar instead of a string.

Storing strings in a dictionary is probably a good idea.
Finding a string in a hashmap can be done efficiently.
Most commonly used strings are immutable values.

Typically, strings are used to describe metadata, such as field names, class names, and enumeration values.
When designing a user interface, we deal with a lot of labels.

For example, when we pass data to json, most of this data is field names.
If we use Google protocol buffer, integer encoding without leading zeros is used to encode the fields.

Compression algorithms come with a lot of overhead.

Consider, for example, passing tabular data to display a report.
String data is column names, display styles, width, alignment method, and the values ​​themselves,
which should be for each cell in the table.
It is possible to identify a repeated set of string data for a specific report type with each transmission.
So we can tell you the dataset for report # 9.
Some fields will have a very limited set of values ​​based on the enumerated type.

## Permanent string repository.
The immutable part of the data, which may be in each transmission, must be declared as a part of a specific data format and transmitted to the client side once.

## Variable string repository.
We pass the modified part as field values ​​or in a separate part of the message.
It is also possible to combine this piece of data with the applicable data and national language encoding.