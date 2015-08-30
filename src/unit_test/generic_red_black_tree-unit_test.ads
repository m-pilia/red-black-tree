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

with Ada.Containers.Ordered_Sets;
with Ada.Numerics.Generic_Elementary_Functions;

with AUnit; use AUnit;
with AUnit.Test_Cases;

generic
    with function Random_Key return T;
    with function "="(Left, Right: T) return Boolean is <>;
package Generic_Red_Black_Tree.Unit_Test is

    type Tree_Test is new Test_Cases.Test_Case with null record;

    -- Provide name identifying the test case
    function Name(Test: Tree_Test) return Message_String;

    -- Register routines to be run
    procedure Register_Tests(Test: in out Tree_Test);

    package Math is new Ada.Numerics.Generic_Elementary_Functions (Float);

    package T_Ordered_Set is new Ada.Containers.Ordered_Sets (T);
    use T_Ordered_Set;

    -- Test Routines:                        
    procedure Test_Insertion(Test: in out Test_Cases.Test_Case'Class);
    procedure Test_Removal(Test: in out Test_Cases.Test_Case'Class);

end Generic_Red_Black_Tree.Unit_Test;
