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

with Ada.Numerics.Discrete_Random;

with AUnit.Test_Suites; use AUnit.Test_Suites;

with Generic_Red_Black_Tree;
with Generic_Red_Black_Tree.Unit_Test;

package Tree_Test_Suite is
    -- provide a type for the keys
    type Number_Type is range -999_999..999_999;
    
    -- discrete random generator (initialization in the package body)
    package Rand is new Ada.Numerics.Discrete_Random(Number_Type);
    Seed: Rand.Generator;

    -- function which generates a random key
    function Random_Key return Number_Type is 
        (if True then Rand.Random(Seed) else 0);

    -- instance of the generic tree and its unit test
    package Integer_Tree is new Generic_Red_Black_Tree (Number_Type);
    package Tree_Tests is new Integer_Tree.Unit_Test (Random_Key);

    -- suite generation
    function Suite return AUnit.Test_Suites.Access_Test_Suite;
end Tree_Test_Suite;
