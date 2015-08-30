-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as 
-- published by the Free Software Foundation; either version 3 of 
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses/>.
--  
-- Copyright (C) Martino Pilia <martino.pilia@gmail.com>, 2015

with AUnit.Assertions;

package body Generic_Red_Black_Tree.Unit_Test is

    -- Name for the test case.
    function Name(Test: Tree_Test) return Test_String is
    begin
        return Format("Red-Black Tree Tests");
    end Name;


    -- Register test routines to call.
    procedure Register_Tests(Test: in out Tree_Test) is
        use AUnit.Test_Cases.Registration;
    begin
        Register_Routine(
            Test,
            Test_Insertion'Unrestricted_Access,
            "Test insertion");
        Register_Routine(
            Test,
            Test_Removal'Unrestricted_Access,
            "Test removal");
    end Register_Tests;
    

    -- Test the insertion procedure, checking the keys are present after 
    -- the insertion and ensuring the tree height is bounded by 2 ln_2(n). 
    procedure Test_Insertion(Test: in out Test_Cases.Test_Case'Class) is
        Tree: Red_Black_Tree;
        Key_Set: Set;
        Key: T;
        Log_Length: Count_Type;
    begin
        -- do 99_999 addings of random keys to the tree, and memorize the keys
        -- in a set too
        for I in 1..99_999 loop
            Key := Random_Key;
            Tree.Insert(Key);
            Key_Set.Include(Key);
        end loop;
        
        -- for each key in the set, search it into the tree
        for K of Key_Set loop
            AUnit.Assertions.Assert(
                Tree.Contains(K),
                "Missing an inserted key");
        end loop;

        -- check tree size
        AUnit.Assertions.Assert(
            Tree.Length = Key_Set.Length,
            "Wrong tree length");

        -- ensure the height of the tree is bounded
        Log_Length := 2 * Count_Type(Math.Log(Float(Tree.Length), 2.0));
        AUnit.Assertions.Assert(
            Tree.Height < 2 * Log_Length,
            "Tree height out of logarithmic bound");

    end Test_Insertion;


    -- Test the removal procedure.
    procedure Test_Removal(Test: in out Test_Cases.Test_Case'Class) is
        Tree: Red_Black_Tree;
        Key_Set: Set;
        Key: T;
    begin
        -- do 99_999 addings of random keys to the tree, and memorize the keys
        -- in a set too
        for I in 1..99_999 loop
            Key := Random_Key;
            Tree.Insert(Key);
            Key_Set.Include(Key);
        end loop;

        -- remove all keys from the tree, then ensure they're not present
        -- anymore
        for K of Key_Set loop
            Tree.Remove(K);

            AUnit.Assertions.Assert(
                not Tree.Contains(K),
                "Found a removed key");
        end loop;

        -- check tree size
        AUnit.Assertions.Assert(
            Tree.Length = 0,
            "Wrong final size");

    end Test_Removal;


end Generic_Red_Black_Tree.Unit_Test;
