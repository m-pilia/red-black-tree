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

with Ada.Finalization;
with Ada.Iterator_Interfaces;
with Ada.Unchecked_Deallocation;
with Ada.Containers; use Ada.Containers;

generic
    type T is private;
    with function "<"(X, Y: T) return Boolean is <>;
package Generic_Red_Black_Tree is

    -- tree type
    type Red_Black_Tree is tagged private
        with
        Constant_Indexing => Constant_Reference,
        Variable_Indexing => Reference,
        Default_Iterator  => Iterate,
        Iterator_Element  => T;

    -------------------------------------------------------------------
    -- ### DATA STRUCTURE INTERFACE 
    -------------------------------------------------------------------

    -- Add a key to the tree.
    procedure Insert(Tr: in out Red_Black_Tree; Obj: T);

    -- Remove a key from the tree. 
    procedure Remove(Tr: in out Red_Black_Tree; Obj: T);

    -- Check wether the tree contains the key.
    function Contains(Tr: Red_Black_Tree; Key: T) return Boolean;

    -- Return the smallest key in the tree. 
    function Minimum(Tr: Red_Black_Tree) return T;

    -- Return the biggest key in the tree.
    function Maximum(Tr: Red_Black_Tree) return T;

    -- Return true if two trees contain the same keys.
    function "="(Left, Right: Red_Black_Tree) return Boolean;

    -- Return the number of keys in the tree.
    function Length(Container: Red_Black_Tree) return Count_Type with inline;
    
    -- Return true if the tree contains no keys.
    function Is_Empty(Container: Red_Black_Tree) return Boolean with inline;
    
    -- Remove all the keys from the tree.
    procedure Clear(Container: in out Red_Black_Tree);
    
    -- Remove all the keys from the target and add it the keys from the source.
    procedure Assign(Target: in out Red_Black_Tree; Source: in Red_Black_Tree);
    
    -- Return a new tree containing the same keys as the source.
    function Copy(Source: Red_Black_Tree) return Red_Black_Tree;
    
    -- Assign the source to the target, then clear the source.
    procedure Move(Target, Source: in out Red_Black_Tree);


    -------------------------------------------------------------------
    -- ### ITERATION STUFF 
    -------------------------------------------------------------------


    type Red_Black_Tree_Access is access Red_Black_Tree;

    type Cursor is private;

    -- Return true if the cursor indicates a valid key.
    function Has_Element(Position: Cursor) return Boolean;

    -- Return the key of the node under the cursor.
    function Element(Position: Cursor) return T;

    -- Package for Ada 2012 iteration.
    package Iterator_Interfaces is new Ada.Iterator_Interfaces
        (Cursor, Has_Element);

    -- Return an iterator for the tree starting from the smallest item.
    function Iterate(Container: Red_Black_Tree) 
        return Iterator_Interfaces.Reversible_Iterator'Class;

    -- Return an iterator for the tree starting from a custom position.
    function Iterate(Container: Red_Black_Tree; Start: Cursor)
        return Iterator_Interfaces.Reversible_Iterator'Class;

    -- Return a cursor pointing to the smallest item in the tree.
    function First(Container: Red_Black_Tree) return Cursor;

    -- Return a cursor pointing to the biggest item in the tree.
    function Last(Container: Red_Black_Tree) return Cursor;
    
    -- Return a cursor pointing to the next (bigger) item. 
    function Next(Position: Cursor) return Cursor;
    
    -- Advance the cursor to the next item.
    procedure Next(Position: in out Cursor);

    -- Return a cursor pointing to the previous (smaller) item.
    function Previous(Position: Cursor) return Cursor;

    -- Withdraw the cursor to the preceeding item.
    procedure Previous(Position: in out Cursor);

    -- Change the key of the item under the cursor.
    procedure Replace_Element(
        Container: in out Red_Black_Tree; 
        Position: in Cursor;
        New_Item: in T);

    -- Apply the procedure to the key of the item under the cursor.
    procedure Query_Element(
        Position: in Cursor;
        Process: not null access procedure (Element: in T));

    -- Apply the procedure to the key of the item under the cursor.
    procedure Update_Element(
        Container: in out Red_Black_Tree;
        Position: in Cursor;
        Process: not null access procedure (Element: in out T));

    -- Type defining a reference to a key (needed for Ada 2012 iteration).
    type Reference_Type(Element: not null access T)
        is private
        with Implicit_Dereference => Element;

    -- Type defining a constant reference to a key (needed for Ada 2012
    -- iteration).
    type Constant_Reference_Type(Element: not null access constant T) 
        is private
        with Implicit_Dereference => Element;

    -- Return a reference to the key under the cursor.
    function Reference(Container: aliased Red_Black_Tree; Position: Cursor)
        return Reference_Type;

    -- Return a constant reference to the key under the cursor.
    function Constant_Reference(Container: aliased Red_Black_Tree;
        Position: Cursor)
        return Constant_Reference_Type;

    Empty_Tree_Exception: exception;

private
    
    type Node_Color is (Red, Black);

    type Node;
    type Node_Ptr is access all Node;

    -- A node for a red-black tree
    type Node is 
        record
            Key: aliased T;
            Left: Node_Ptr;
            Right: Node_Ptr;
            Parent: Node_Ptr;
            Color: Node_Color := Red;
        end record;

    -- Sentinel node, a shared object used to represent a sink node.
    Sentinel_Null_Node: aliased Node;

    -- Access to the sentinel node.
    Nil: constant Node_Ptr := Sentinel_Null_Node'Access;

    -- Type for the tree.
    type Red_Black_Tree is new Ada.Finalization.Controlled with 
        record
            Root: Node_Ptr   := Nil;
            Size: Count_Type := 0;
        end record;

    -- Finalize the tree object on deallocation.
    overriding
    procedure Finalize(Tree: in out Red_Black_Tree);

    type Cursor is
        record
            Container: Red_Black_Tree_Access;
            Node: Node_Ptr; -- Pointer to the node under the cursor.
        end record;

    type Iterator is limited new Iterator_Interfaces.Reversible_Iterator with
        record
            Container: Red_Black_Tree_Access;
            Node: Node_Ptr;
        end record;

    type Reference_Type(Element: not null access T) is
        null record;

    type Constant_Reference_Type(Element: not null access constant T) is
        null record;

    overriding
    function First(Object: Iterator) return Cursor;
    
    overriding
    function Last(Object: Iterator) return Cursor;
    
    overriding
    function Next(Object: Iterator; Position: Cursor) return Cursor;
    
    overriding
    function Previous(Object: Iterator; Position: Cursor) return Cursor;


    -------------------------------------------------------------------
    -- ### DATA STRUCTURE PRIVATE INTERFACE 
    -------------------------------------------------------------------


    -- Return a pointer to the minimum node in the subtree rooted in the
    -- node passed as parameter.
    function Minimum_Node(N: not null Node_Ptr) return Node_Ptr;

    -- Return a pointer to the maximum node in the subtree rooted in the
    -- node passed as parameter.
    function Maximum_Node(N: not null Node_Ptr) return Node_Ptr;

    -- Return a pointer to the node following N in the tree.
    function Next_Node(N: not null Node_Ptr) return Node_Ptr;

    -- Return a pointer to the node preceeding N in the tree.
    function Previous_Node(N: not null Node_Ptr) return Node_Ptr;

    -- Destroy a node.
    procedure Free_Node is new Ada.Unchecked_Deallocation
        (Object => Node, Name => Node_Ptr);

    -- Recursively clone the subtree rooted in N, returning a pointer to
    -- the new subtree's root.
    function Clone_Subtree(N: not null Node_Ptr;
        Parent: not null Node_Ptr) return not null Node_Ptr;

    -- Replace the subtree rooted in Replaced with the subtree rooted
    -- in Replacement.
    procedure Transplant(
        Tr: in out Red_Black_Tree; 
        Replaced: not null Node_Ptr;
        Replacement: not null Node_Ptr);

    -- Apply a right rotation to N.
    procedure Right_Rotate(Tree: in out Red_Black_Tree; N: not null Node_Ptr);

    -- Apply a left rotation to N.
    procedure Left_Rotate(Tree: in out Red_Black_Tree; N: not null Node_Ptr);

    -- Make N's parent Black and N's grandparent Red.
    procedure Set_Ancestor_Color(N: Node_Ptr) with inline;

    -- Restore color properties of the tree after inserting the N node.
    procedure Insert_Color_Fix(Tree: in out Red_Black_Tree;
        N: not null Node_Ptr);

    -- Restore color properties of the tree after removing the N node.
    procedure Remove_Color_Fix(Tree: in out Red_Black_Tree;
                               N: not null Node_Ptr);
    
    -- Compute the height of the subtree rooted in a node.
    function Height(N: not null Node_Ptr) return Count_Type;
    
    -- Compute the height of a binary tree.
    function Height(Tree: Red_Black_Tree) return Count_Type;
    
    Node_Position_Exception: exception;

end Generic_Red_Black_Tree;
