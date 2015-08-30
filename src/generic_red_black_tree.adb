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

with System; use all type System.Address;

package body Generic_Red_Black_Tree is


    -------------------------------------------------------------------
    -- ### ITERATION STUFF
    -------------------------------------------------------------------


    -- Return true if a next element is present.
    function Has_Element(Position: Cursor) return Boolean is
    begin
        return Position.Node /= Nil;
    end Has_Element;


    -- Return the value of the current element under the Cursor.
    function Element(Position: Cursor) return T is
    begin
        if Position.Container = Null then
            raise Program_Error
                with "Element: invalid Null container";
        elsif Position.Node = Nil then
            raise Program_Error
                with "Element: invalid cursor position";
        end if;

        return Position.Node.Key;
    end Element;


    -- Return an iterator starting from the first tree item.
    function Iterate(Container: Red_Black_Tree) 
        return Iterator_Interfaces.Reversible_Iterator'Class is
    begin
        return It: constant Iterator := Iterator'(
            Container'Unrestricted_Access, 
            Minimum_Node(Container.Root));
    end Iterate;


    -- Return an iterator starting from a custom position.
    function Iterate(Container: Red_Black_Tree; Start: Cursor)
        return Iterator_Interfaces.Reversible_Iterator'Class is
    begin
        -- ensure the Iterator and the Cursor refer to the same tree
        if Container'Unrestricted_Access /= Start.Container then
            raise Program_Error
                with "Position cursor refers to a wrong container";
        end if;

        return It: constant Iterator := Iterator'(
            Container'Unrestricted_Access,
            Start.Node);
    end Iterate;


    -- Return a cursor pointing to the first element of the tree.
    function First(Container: Red_Black_Tree) return Cursor is
    begin
        return Cursor'(
            Container'Unrestricted_Access, 
            Minimum_Node(Container.Root));
    end First;

                                            
    -- Return a cursor pointing to the last element of the tree.
    function Last(Container: Red_Black_Tree) return Cursor is
    begin
        return Cursor'(
            Container'Unrestricted_Access,
            Minimum_Node(Container.Root));
    end Last;


    -- Return a Cursor pointing to the first object in the tree.
    function First(Object: Iterator) return Cursor is
    begin
        return Cursor'(Object.Container, Minimum_Node(Object.Container.Root));
    end First;


    -- Return a Cursor pointing to the last object in the tree.
    function Last(Object: Iterator) return Cursor is
    begin
        return Cursor'(Object.Container, Maximum_Node(Object.Container.Root));
    end Last;


    -- Return a Cursor pointing to the next object for the Iterator.
    function Next(Object: Iterator; Position: Cursor) return Cursor is
    begin
        -- ensure the Iterator and the Cursor refer to the same tree
        if Object.Container /= Position.Container then
            raise Program_Error
                with "Next: Position cursor refers to a wrong container";
        end if;

        return Next(Position);
    end Next;


    -- Return a Cursor pointing to the next key in the tree.
    function Next(Position: Cursor) return Cursor is
    begin
        -- ensure the container is valid
        if Position.Container = Null then
            raise Program_Error
                with "Next: invalid Null container";
        end if;

        return Cursor'(Position.Container, Next_Node(Position.Node));
    end Next;


    -- Advance the Cursor to the next position.
    procedure Next(Position: in out Cursor) is
    begin
        Position := Next(Position);
    end Next;


    -- Return a Cursor pointing to the next object for the Iterator.
    function Previous(Object: Iterator; Position: Cursor) return Cursor is
    begin
        -- ensure the Iterator and the Cursor refer to the same tree
        if Object.Container /= Position.Container then
            raise Program_Error
                with "Position cursor refers to a wrong container";
        end if;

        return Previous(Position);
    end Previous;


    -- Return a Cursor pointing to the previous object in the tree.
    function Previous(Position: Cursor) return Cursor is
    begin
        -- ensure the container is valid
        if Position.Container = Null then
            raise Program_Error
                with "Next: invalid Null container";
        end if;

        return Cursor'(Position.Container, Previous_Node(Position.Node));
    end Previous;


    -- Move the iterator to the previous element.
    procedure Previous(Position: in out Cursor) is
    begin
        Position := Previous(Position);
    end Previous;


    -- Replace the element under the cursor with a new item.
    procedure Replace_Element(
        Container: in out Red_Black_Tree; 
        Position: in Cursor;
        New_Item: in T) is
    begin
        if Container'Unrestricted_Access /= Position.Container then
            raise Program_Error
                with "Replace_Element: Cursor refers to a wrong container";
        elsif Position.Node = Nil then
            raise Node_Position_Exception
                with "Replace_Element: trying to replace Nil element";
        end if;
        Position.Node.Key := New_Item;
    end Replace_Element;


    -- Call the Process procedure on the item under the cursor.
    procedure Query_Element(
        Position: in Cursor;
        Process: not null access procedure(Element: in T)) is
    begin
        if Position.Node = Nil then
            raise Node_Position_Exception
                with "Query_Element: trying to query Nil element";
        end if;
        Process(Position.Node.Key);
    end Query_Element;

    -- Call the Process procedure on the item under the cursor.
    procedure Update_Element(
        Container: in out Red_Black_Tree;
        Position: in Cursor;
        Process: not null access procedure(Element: in out T)) is
    begin
        if Container'Unrestricted_Access /= Position.Container then
            raise Program_Error
                with "Update_Element: Cursor refers to a wrong container";
        elsif Position.Node = Nil then
            raise Node_Position_Exception
                with "Update_Element: trying to update Nil element";
        end if;
        Process(Position.Node.Key);
    end Update_Element;


    -- Return a reference to the current element under the cursor.
    function Reference(Container: aliased Red_Black_Tree; Position: Cursor)
        return Reference_Type is
    begin
        if Container'Unrestricted_Access /= Position.Container then
            raise Program_Error
                with "Reference: Position cursor refers to a wrong container";
        end if;

        -- return a Reference_Type object
        return (Element => Position.Node.Key'Access);
    end Reference;


    -- Return a constant reference to the current element under the cursor.
    function Constant_Reference(Container: aliased Red_Black_Tree; 
        Position: Cursor)
        return Constant_Reference_Type is
    begin
        if Container'Unrestricted_Access /= Position.Container then
            raise Program_Error
                with "Constant_Reference: Position cursor refers to " & 
                     "a wrong container";
        end if;

        -- return a Constant_Reference_Type object
        return (Element => Position.Node.Key'Access);
    end Constant_Reference;


    -------------------------------------------------------------------
    -- ### DATA STRUCTURE PUBLIC STUFF
    -------------------------------------------------------------------


    -- Add a new key to the tree.
    procedure Insert(
        Tr: in out Red_Black_Tree;
        Obj: T) is
        Last: Node_Ptr := Tr.Root;
        Penultimate: Node_Ptr := Nil;
        New_Node: Node_Ptr;
    begin
        -- find the parent for the new node
        while Last /= Nil loop
            Penultimate := Last;

            -- chech if the key is already present
            if Obj = Last.Key then
                return;
            end if;

            Last := (if Obj < Last.Key then Last.Left else Last.Right);
        end loop;

        -- create new node
        New_Node := new Node'(
            Key    => Obj,
            Left   => Nil,
            Right  => Nil,
            Parent => Penultimate,
            Color  => Red);

        -- add node
        if Penultimate = Nil then
            Tr.Root := New_Node;
        elsif Obj < Penultimate.Key then
            Penultimate.Left := New_Node;
        else
            Penultimate.Right := New_Node;
        end if;

        -- restore color properties of the tree
        Insert_Color_Fix(Tr, New_Node);

        -- update tree size
        Tr.Size := Tr.Size + 1;
    end Insert;


    -- Remove a key from the tree.
    procedure Remove(
        Tr: in out Red_Black_Tree;
        Obj: T) is
        N: Node_Ptr := Tr.Root;
        Minimum_Right: Node_Ptr;
        Tracked_Color: Node_Color := N.Color;
        Replacement_Node: Node_Ptr;
    begin
        -- search in the tree for the node N containing Obj as key 
        while N /= Nil and N.Key /= Obj loop
            N := (if Obj < N.Key then N.Left else N.Right);
        end loop;

        -- Obj not found
        if N = Nil then
            return;
        end if;

        -- if N node has only a left child, replace N with it
        if N.Left = Nil then
            Replacement_Node := N.Right;
            Transplant(Tr, N, N.Right);

        -- if N node has only a right child, replace N with it
        elsif N.Right = Nil then
            Replacement_Node := N.Left;
            Transplant(Tr, N, N.Left);

        -- replace N with the minimum node in its right subtree
        else
            Minimum_Right := Minimum_Node(N.Right);
            Tracked_Color := Minimum_Right.Color;
            Replacement_Node := Minimum_Right.Right;
            -- replace the minimum node with its right child
            if Minimum_Right.Parent /= N then
                Transplant(Tr, Minimum_Right, Minimum_Right.Right);
                Minimum_Right.Right := N.Right;
                Minimum_Right.Right.Parent := Minimum_Right;
            end if;
            Transplant(Tr, N, Minimum_Right);
            Minimum_Right.Left := N.Left;
            Minimum_Right.Left.Parent := Minimum_Right;
            Minimum_Right.Color := N.Color;
        end if;

        -- restore red-black properties if needed
        if Tracked_Color = Black then
            Remove_Color_Fix(Tr, Replacement_Node);
        end if;

        -- destroy removed node
        Free_Node(N);

        -- update tree size
        Tr.Size := Tr.Size - 1;
    end Remove;
    

    -- Return true if the tree contains the key, false otherwise.
    function Contains(Tr: Red_Black_Tree; Key: T) return Boolean is
        N: Node_Ptr := Tr.Root;
    begin
        while N /= Nil loop
            if N.Key = Key then
                return True;
            elsif Key < N.Key then
                N := N.Left;
            else
                N := N.Right;
            end if;
        end loop;
        return False;
    end Contains;


    -- Get the smallest key inside the tree.
    function Minimum(Tr: Red_Black_Tree) return T is
    begin
        if Tr.Root = Nil then
            raise Empty_Tree_Exception;
        else
            return Minimum_Node(Tr.Root).Key;
        end if;
    end Minimum;


    -- Get the largest key inside the tree.
    function Maximum(Tr: Red_Black_Tree) return T is
    begin
        if Tr.Root = Nil then
            raise Empty_Tree_Exception;
        else
            return Maximum_Node(Tr.Root).Key;
        end if;
    end Maximum;


    -- Two trees are equal if they contain the same keys.
    function "=" (Left, Right: Red_Black_Tree) return Boolean is
        Left_Cursor:  Cursor;
        Right_Cursor: Cursor;
    begin
        -- check if the two trees are actually the same
        if Left'Address = Right'Address then
            return True;

        -- ensure the two trees have the same size
        elsif Left.Length = Right.Length then
            return False;
        end if;

        -- for each left key, ensure it is in the right tree too
        Left_Cursor  := Left.First;
        Right_Cursor := Right.First;
        while Has_Element(Left_Cursor) loop
            if not Has_Element(Right_Cursor) then
                return False;
            elsif Element(Left_Cursor) /= Element(Right_Cursor) then
                return False;
            end if;
            Next(Left_Cursor);
            Next(Right_Cursor);
        end loop;

        return True;
    end "=";


    -- Return the number of keys inside the tree.
    function Length(Container: Red_Black_Tree) return Count_Type is
    begin
        return Container.Size;
    end Length;


    -- Return True if the tree contains no key.
    function Is_Empty(Container: Red_Black_Tree) return Boolean is
    begin
        return Container.Size = Count_Type'(0);
    end Is_Empty;


    -- Remove all keys from the tree.
    procedure Clear(Container: in out Red_Black_Tree) is
        N: Node_Ptr;
        To_Remove: Node_Ptr;
    begin
        if Container.Size = Count_Type'(0) then
            return;
        end if;

        N := Minimum_Node(Container.Root);
        while N /= Nil loop
            To_Remove := N;
            N := Next_Node(N);
            Free_Node(To_Remove);
        end loop;

        Container.Root := Nil;
        Container.Size := Count_Type'(0);
    end Clear;


    -- Remove Target's nodes and add Source's nodes to it.
    procedure Assign(
        Target: in out Red_Black_Tree;
        Source: in Red_Black_Tree) is
    begin
        if Target'Address = Source'Address then
            return;
        end if;

        Clear(Target);

        Target := Copy(Source);
    end Assign;


    -- Return a copy of the input tree.
    function Copy(Source: Red_Black_Tree) return Red_Black_Tree is
        Result: Red_Black_Tree;
    begin
        Result.Root := Clone_Subtree(Source.Root, Nil);
        Result.Size := Source.Size;
        return Result;
    end Copy;

    
    -- Assign Source to target, then clear Source.
    procedure Move(Target, Source: in out Red_Black_Tree) is
    begin
        if Target'Address = Source'Address then
            return;
        end if;

        Assign(Target, Source);
        Clear(Source);
    end Move;


    -------------------------------------------------------------------
    -- ### DATA STRUCTURE PRIVATE STUFF
    -------------------------------------------------------------------
    
    
    -- Destroy all the nodes when the tree is deallocated.
    procedure Finalize(Tree: in out Red_Black_Tree) is
    begin
        Clear(Tree);
    end Finalize;


    -- Recursively clone the subtree rooted in N, returning a pointer to
    -- the new subtree's root. The parent for the new subtree's root is
    -- passed as argument.
    -- 
    -- The tree is balanced, so the recursion depth is limited to 
    --   2 * log_2(Subtree_Size)
    function Clone_Subtree(N: not null Node_Ptr;
        Parent: not null Node_Ptr) return not null Node_Ptr is
        New_Root: Node_Ptr;
    begin
        if N = Nil then
            return Nil;
        end if;

        -- create node for the new root
        New_Root := new Node'(
            Key    => N.Key,
            Left   => Null,
            Right  => Null,
            Parent => Parent,
            Color  => N.Color);

        -- recursively clone child subtrees
        New_Root.Left  := Clone_Subtree(N.Left, New_Root);
        New_Root.Right := Clone_Subtree(N.Right, New_Root);

        return New_Root;
    end Clone_Subtree;


    -- Replace the subtree rooted in Replaced with the subtree rooted
    -- in Replacement.
    procedure Transplant(
        Tr: in out Red_Black_Tree;
        Replaced: not null Node_Ptr;
        Replacement: not null Node_Ptr) is
    begin
        if Replaced.Parent = Nil then
            Tr.Root := Replacement;
        elsif Replaced = Replaced.Parent.Left then
            Replaced.Parent.Left := Replacement;
        else 
            Replaced.Parent.Right := Replacement;
        end if;
        if Replacement /= Nil then
            Replacement.Parent := Replaced.Parent;
        end if;
    end Transplant;


    -- Get a pointer to the node containing the smallest key in the tree.
    function Minimum_Node(N: not null Node_Ptr) 
        return Node_Ptr is
    begin
        return M: Node_Ptr := N do
            while M.Left /= Nil loop
                M := M.Left;
            end loop;
        end return;
    end Minimum_Node;


    -- Get a pointer to the node containing the biggest key in the tree.
    function Maximum_Node(N: not null Node_Ptr) 
        return Node_Ptr is
    begin
        return M: Node_Ptr := N do
            while M.Right /= Nil loop
                M := M.Right;
            end loop;
        end return;
    end Maximum_Node;


    -- Return a pointer to the node following N in the tree.
    --
    -- The tree has a parent pointer for each node, so it can be transversed
    -- storing the last seen node only. 
    --
    -- There are three possible cases; the last seen node...
    -- * has a right child: the next node is that child
    -- * is a left child:   the next node is his parent
    -- * is a right child:  the next node is the first ancestor whose child is
    --                      the root (i.e. the sentinel node Nil, which is the 
    --                      roots parent; if so, all the nodes has been
    --                      visited) or a left child
    --       
    function Next_Node(N: not null Node_Ptr) return Node_Ptr is
        Next: Node_Ptr;
    begin
        if N = Nil then
            raise Node_Position_Exception
                with "Next_Node: Nil's next node is undefined";
        end if;

        -- N node has a right child
        if N.Right /= Nil then
            Next := Minimum_Node(N.Right);

        -- N node is a left child
        elsif N.Parent.Left = N then
            Next := N.Parent;

        -- N node is a right child
        else
            Next := N.Parent;

            -- find the first ancestor which is a left child or the root
            while Next.Parent /= Nil and Next.Parent.Left /= Next loop
                Next := Next.Parent;
            end loop;

            Next := Next.Parent;
        end if;

        return Next;
    end Next_Node;


    -- As Next_Node, with all Left/Right directions reversed.
    function Previous_Node(N: not null Node_Ptr) return Node_Ptr is
        Prev: Node_Ptr;
    begin
        if N = Nil then
            raise Node_Position_Exception
                with "Previous_Node: Nil's previous node is undefined";
        end if;

        -- N node has a left child
        if N.Left /= Nil then
            Prev := Minimum_Node(N.Left);

        -- N node is a right child
        elsif N.Parent.Right = N then
            Prev := N.Parent;

        -- N node is a left child
        else
            Prev := N.Parent;

            -- find the first ancestor which is a right child or the root
            while Prev.Parent /= Nil and Prev.Parent.Right /= Prev loop
                Prev := Prev.Parent;
            end loop;

            Prev := Prev.Parent;
        end if;

        return Prev;
    end Previous_Node;


    -- Right rotation of the N node:
    --
    --                  N.Parent                   N.Parent
    --                     |                          |
    --                     |                          |
    --                     N         ====>          Old_L
    --                    / \                       /  \
    --                   /   \                     /    \
    --                Old_L  N.Right       Old_L.Left    N
    --                /  \                              / \
    --               /    \                            /   \
    --       Old_L.Left  Old_L.Right          Old_L.Right  N.Right
    --
    procedure Right_Rotate(Tree: in out Red_Black_Tree; 
        N: not null Node_Ptr) is
        Old_Left: Node_Ptr := N.Left;
    begin
        if N = Nil then
            raise Node_Position_Exception 
                with "Right_Rotate: N cannot be Nil";
        end if;
        if Old_Left = Nil then
            raise Node_Position_Exception 
                with "Right_Rotate: N must have a left child";
        end if;

        -- put Old_Left's right child as N's left child
        N.Left := Old_Left.Right;
        if N.Left /= Nil then
            N.Left.Parent := N;
        end if;

        -- put Old_Left as N.Parent's child
        Old_Left.Parent := N.Parent;
        if Old_Left.Parent = Nil then
            Tree.Root := Old_Left;
        else
            if Old_Left.Parent.Left = N then
                Old_Left.Parent.Left := Old_Left;
            else
                Old_Left.Parent.Right := Old_Left;
            end if;
        end if;

        -- put N as Old_Left's right child
        Old_Left.Right := N;
        N.Parent := Old_Left;
    end Right_Rotate; 


    -- Left rotation of the N node:
    --
    --            N.Parent                      N.Parent
    --               |                             |
    --               |                             |
    --               N           ====>           Old_R
    --              / \                          /  \
    --             /   \                        /    \
    --        N.Left  Old_R                    N    Old_R.Right
    --                /  \                    / \
    --               /    \                  /   \
    --       Old_R.Left  Old_R.Right     N.Left  Old_R.Left
    --
    procedure Left_Rotate(Tree: in out Red_Black_Tree; 
        N: not null Node_Ptr) is
        Old_Right: Node_Ptr := N.Right;
    begin
        if N = Nil then
            raise Node_Position_Exception 
                with "Right_Rotate: N cannot be Nil";
        end if;
        if Old_Right = Nil then
            raise Node_Position_Exception 
                with "Right_Rotate: N must have a right child";
        end if;

        -- put Old_Right's left child as N's right child
        N.Right := Old_Right.Left;
        if N.Right /= Nil then
            N.Right.Parent := N;
        end if;

        -- put Old_Right as N.Parent's child
        Old_Right.Parent := N.Parent;
        if Old_Right.Parent = Nil then
            Tree.Root := Old_Right;
        else
            if Old_Right.Parent.Left = N then
                Old_Right.Parent.Left := Old_Right;
            else
                Old_Right.Parent.Right := Old_Right;
            end if;
        end if;

        -- put N as Old_Right's left child
        Old_Right.Left := N;
        N.Parent := Old_Right;
    end Left_Rotate;


    -- Change the color of N.Parent to Black, and the color of 
    -- N.Parent.Parent to Red.
    procedure Set_Ancestor_Color(N: Node_Ptr) is
    begin
        if N.Parent = Nil then
            raise Node_Position_Exception
                with "Set_Ancestor_Color: N's parent should not be Nil";
        end if;
        N.Parent.Color := Black;
        N.Parent.Parent.Color := Red;
    end Set_Ancestor_Color;


    -- Restore the color properties of the tree after the insertion of the
    -- Z node.
    --
    -- The new node is red, so a problem may rise if its parent is Red. The 
    -- last instruction sets the color to Black, ensuring the tree color, so
    -- the remaining problem is related to having a red node with a red child.
    -- There are three possible cases when Z is left child (for a right 
    -- child is the same with all the left/right directions inverted:
    --
    --  (1) Z's uncle is Red: 
    --      color both Z's parent and uncle with black, moving the problem on
    --      Z's grandparent.
    --
    --              Z.P.P (B)                 Z.P.P (R)
    --               /  \                      /  \
    --          Z.P (R)  U (R)    ===>    Z.P (B)  U (B)
    --             /                         /
    --           Z (R)                    Z (R)
    --
    --  (2) Z's uncle is Black and Z is a right child: 
    --      left rotatate Z.Parent, falling into case (3).
    --
    --              Z.P.P (B)               Z.P.P (B)
    --               /  \                    /  \
    --          Z.P (R)  U (B)    ===>    Z (R)  U (B)
    --               \                     /
    --               Z (R)              Z.P (R)
    --
    --  (3) Z's uncle is Black and Z is a left child:
    --      swap the colors of Z.Parent and Z.Parent.Parent, then right rotate
    --      Z.Parent.Parent.
    --
    --              Z.P.P (B)                Z.P (B)
    --               /  \                    /  \
    --          Z.P (R)  U (B)    ===>    Z (R)  Z.P.P (R)
    --             /                               \
    --            Z (R)                             U (B)
    --
    procedure Insert_Color_Fix(Tree: in out Red_Black_Tree; 
        N: not null Node_Ptr) is
        Z: Node_Ptr := N; -- mutable pointer to a node
        Uncle: Node_Ptr;  -- node for N's uncle
    begin
        while Z.Parent.Color = Red loop

            -- if Z's parent is a left child
            if Z.Parent.Parent.Left = Z.Parent then
                Uncle := Z.Parent.Parent.Right;
                if Uncle.Color = Red then
                    -- case (1)
                    Set_Ancestor_Color(Z);
                    Uncle.Color := Black;
                    Z := Z.Parent.Parent;
                else
                    if Z.Parent.Right = Z then
                        -- case (2)
                        Z := Z.Parent;
                        Left_Rotate(Tree, Z);
                    end if;
                    -- case (3)
                    Set_Ancestor_Color(Z);
                    Right_Rotate(Tree, Z.Parent.Parent);
                end if;

            -- if Z's parent is a right child
            else
                Uncle := Z.Parent.Parent.Left;
                if Uncle.Color = Red then
                    -- case (1)
                    Set_Ancestor_Color(Z);
                    Uncle.Color := Black;
                    Z := Z.Parent.Parent;
                else
                    if Z.Parent.Left = Z then
                        -- case (2)
                        Z := Z.Parent;
                        Right_Rotate(Tree, Z);
                    end if;
                    -- case (3)
                    Set_Ancestor_Color(Z);
                    Left_Rotate(Tree, Z.Parent.Parent);
                end if;
            end if;
        end loop;
        Tree.Root.Color := Black;
    end Insert_Color_Fix;


    -- Restore the color properties of the tree after a black node removal.
    -- The node N was moved in the tree, possibly violating the color
    -- properties.
    --
    -- The removal of a black node causes an inbalance in the black height
    -- of different subtrees, violating the axiom V of red black trees. The 
    -- subtree rooted in N is missing a black node, so if N is red it suffices 
    -- to color N with black to restore, otherwise some rotations are needed
    -- before the black coloring in the last instruction, which also ensures 
    -- the tree color is black.
    --
    -- There are four possible cases when N is a left child (for a right
    -- child it is the same with all left/right directions inverted):
    --
    --  (1) N's sibling S is red:
    --      this case falls in one of the other three after a left rotation
    --      and swapping the color of S and N.Parent (which must be black).
    --
    --           N.P (B)                          S (B)
    --            /  \                            /   \
    --        N (B)   S (R)         ===>     N.P (R)   S.R (B)
    --                /   \                  /    \
    --            S.L (B)  S.R (B)         N (B)  S.L (B)
    --
    --  (2) S is black, both S's children are black:
    --      S may be colored with red, moving the color imbalance problem
    --      from N to N.Parent.
    --
    --           N.P (?)                        N.P (B)
    --            /  \                           /  \
    --        N (B)   S (B)         ===>      N (B)  S (R)
    --                /   \                          /   \
    --            S.L (B)  S.R (B)               S.L (B)  S.R (B)
    --
    --  (3) S is black, S's right children is black:
    --      this case falls in (4) after a right rotation of S and swapping
    --      the color of Z and S.Left (which is red, otherwise this would 
    --      fall under case (2)).
    --
    --           N.P (?)                        N.P (?)
    --            /  \                           /  \
    --        N (B)   S (B)         ===>      N (B)  S.L (B)
    --                /   \                            \
    --            S.L (R)  S.R (B)                      S (R)
    --                                                   \
    --                                                   S.R (B)
    --
    --  (4) S is black, S's right children is red:
    --      the imbalance is solved left-rotating N.Parent, then swapping the
    --      color of X.Parent and S, and coloring S.Right with black.
    --
    --           N.P (?)                            S (?)
    --            /  \                              /   \
    --        N (B)   S (B)         ===>      N.P (B)    S.R (B)
    --                /   \                   /  \       
    --            S.L (?)  S.R (R)        N (B)  S.L (?) 
    --
    procedure Remove_Color_Fix(Tree: in out Red_Black_Tree;
        N: not null Node_Ptr) is
        Z: Node_Ptr := N;  -- mutable pointer to node
        S: Node_Ptr; -- Z's sibling
    begin
        while Z.Color = Black and Z /= Tree.Root loop
            -- Z is a left child
            if Z = Z.Parent.Left then
                S := Z.Parent.Right;
                if S.Color = Red then
                    -- case (1)
                    S.Color := Black;
                    Z.Parent.Color := Red;
                    Left_Rotate(Tree, Z.Parent);
                    S := Z.Parent.Right;
                end if;
                if S.Left.Color = Black and S.Right.Color = Black then
                    -- case (2)
                    S.Color := Red;
                    Z := Z.Parent;
                else
                    if S.Right.Color = Black then
                        -- case (3)
                        S.Left.Color := Black;
                        S.Color := Red;
                        Right_Rotate(Tree, S);
                        S := Z.Parent.Right;
                    end if;
                    -- case (4)
                    S.Color := Z.Parent.Color;
                    Z.Parent.Color := Black;
                    S.Right.Color := Black;
                    Left_Rotate(Tree, Z.Parent);
                    Z := Tree.Root;
                end if;

            -- Z is a right child (all symmetric to the previous case)
            else
                S := Z.Parent.Left;
                if S.Color = Red then
                    -- case (1)
                    S.Color := Black;
                    Z.Parent.Color := Red;
                    Right_Rotate(Tree, Z.Parent);
                    S := Z.Parent.Left;
                end if;
                if S.Right.Color = Black and S.Left.Color = Black then
                    -- case (2)
                    S.Color := Red;
                    Z := Z.Parent;
                else
                    if S.Left.Color = Black then
                        -- case (3)
                        S.Right.Color := Black;
                        S.Color := Red;
                        Left_Rotate(Tree, S);
                        S := Z.Parent.Left;
                    end if;
                    -- case (4)
                    S.Color := Z.Parent.Color;
                    Z.Parent.Color := Black;
                    S.Left.Color := Black;
                    Right_Rotate(Tree, Z.Parent);
                    Z := Tree.Root;
                end if;
            end if;
        end loop;
        Z.Color := Black;
    end Remove_Color_Fix;


    -- Recursive function to compute the height of a subtree rooted in the
    -- node passed as a parameter.
    function Height(N: not null Node_Ptr) return Count_Type is
    begin
        if N = Nil then
            return 0;
        end if;
        return 1 + Count_Type'Max(Height(N.Left), Height(N.Right));
    end Height;
    

    -- Compute the height of a tree.
    function Height(Tree: Red_Black_Tree) return Count_Type is
    begin 
        return Height(Tree.Root);
    end Height;


-- initialization body
begin
    Sentinel_Null_Node.Color := Black;
    Sentinel_Null_Node.Left := Nil;
    Sentinel_Null_Node.Right := Nil;
    Sentinel_Null_Node.Parent := Nil;
end Generic_Red_Black_Tree;
