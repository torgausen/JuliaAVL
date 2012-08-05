JuliaAVL
========

Simple AVL tree for Julia


PLEASE NOTE: This whole library is still under construction and will likely be remolded with heights instead of (or in addition to?) balance factors. The reason is that I just discovered an AVL tree should support log(n) 'join' and 'split' operations. This is why I do not worry much about api yet. I hope to get a 0.01 release this month. 


An AVL tree is a balanced binary search tree. Example:
              
                  8
                 / \
               /     \
             /         \
           /             \
          4              10 
         / \            /  \
        /   \          /    \
       /     \        /      \
      3       5      9       12
     / \     / \            / 
    1   2   6   7         11 


The left side, rooted at 4, is completely balanced, and all children of node 4 have balance factor 0.
Node 12 has two sub trees, one of height 1, the other of height 0, so the balance factor at 12 is (right - left) = (0 - 1) or -1
The height of a node is the maximum of its left and right children's height plus one. No node (Nil) means height zero.
The left child of node 10 has height 1, while the right child has height 2, so the factor at 10 is 2-1 = 1. Node 8 has more stuff on the left side than on the right side, but it still has balance factor zero, because the height difference is the same.

An AVL tree cannot have balance factors other than -1, 0 1. This translates to a maximum height of about 1.44 log n, which is pretty good. See http://en.wikipedia.org/wiki/Avl_tree for details.


The core data structure in AVL.jl is the node: 

type Node{K, V} <: Avl{K, V}
	child :: Array{Avl{K, V}, 1}
	key :: K
	value :: V
	count :: Int
	bal :: Int8
end

Children are kept in a length-2 array, so that they can be selected with variables, rather than 'hard coded'. If they were named node.left and node.right, one could still do that, but as far as I can tell, one would then need an if branch. 

The count field keeps track of how many nodes are in the tree (this node included). The ascii tree above would have a value of 12. This field allows methods like select and rank on the tree. That is, you can efficiently find node number n from the left, or determine how many nodes are to the left of a given node.

The balance information (bal) needs 2 bits (actually less...). For convenience, the count and balance fields are stored separately, but they can later be packed into one 64 bit or 32 bit field.

I may have to add height info to the tree as well, in order to implement join and split. All the extra node information should still fit in a 64 bit field. Special code for 32 bit machines can eventually be added with macros, I suppose. 


