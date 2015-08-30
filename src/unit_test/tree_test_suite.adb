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

package body Tree_Test_Suite is

    S: aliased Test_Suite;

    T: aliased Tree_Tests.Tree_Test;

    function Suite return Aunit.Test_Suites.Access_Test_Suite is
    begin
        S.Add_Test(T'Access);
        return S'Access;
    end Suite;

end Tree_Test_Suite;
