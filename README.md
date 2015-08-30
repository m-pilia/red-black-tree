Red-Black Tree
==============

This is an Ada 2012 implementation of a 
[red-black tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree),
a kind of self-balanced binary search tree.

The tree uses the standard <code>Ada.Iterator_Interfaces</code> for iteration.

```ada
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Text_IO; use Ada.Text_IO;
with Generic_Red_Black_Tree;

procedure Sample is
    package Int_Tree is new Generic_Red_Black_Tree (Integer);
    use Int_Tree;
    T: Red_Black_Tree;
    C: Cursor;
begin
    -- populate the tree
    -- ...

    -- Ada 2005 iteration
    C := First(T);
    while Has_Element(C) loop
        Put(Element(C));
        New_Line;
        Next(C);
    end loop;
    
    -- Ada 2012 generalized iterator
    for C in T.Iterate loop
        Put(Element(C));
        New_Line;
    end loop;

    -- Ada 2012 container element iterator
    for K of T loop
        Put(K);
        New_Line;
    end loop;
end Sample;
```

A simple unit test is written with 
[AUnit](http://libre.adacore.com/tools/aunit/).

License
=======

The project is licensed under GPL 3. See [LICENSE](./LICENSE)
file for the full license.