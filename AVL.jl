
#
# This module implenets AVL trees in particular. Should be possible to replace this with other trees
# as long as the nodes have key, value, count, and child[] fields
#

# module AVL
# import Base.*
		
# export KEY, VALUE, LEFT, RIGHT
# export Avl, Node, Nil
# export copy, deeper_copy, isempty, notempty, isequal
# export assign,  del, del_last, del_first
# export tjoin, tsplit
# export valid_avl, valid_count, valid_sort

const KEY = 1
const VALUE = 2
const BALANCED = int8(0)
const LEFT = int8(1)
const RIGHT = int8(2)
const UNISIDE = LEFT + RIGHT 

# I hate this function. It maps (-1, 0, +1) to 1, 0, 2. 
# I am on the verge of introducing parent pointers just to avoid it.
bal_conv(bal) = (LEFT, BALANCED, RIGHT)[bal + 2] 

abstract Avl{K, V} 

abstract Associative{K, V}

type SortDict{K, V} <: Associative{K, V}
	tree :: Avl{K, V}
	cf :: Function # compare function
end

type Nil{K, V} <: Avl{K, V}
end

nil(K, V) = Nil{K, V}()

type Node{K, V} <: Avl{K, V}
	child :: Array{Avl{K, V}, 1}
	key :: K
	value :: V
	count :: Int
	bal :: Int8
	# NOTE: the count and balance fields can later be packed into one 64 (62+2), or 32 (30+2) bit integer. 
	# It's just simpler to keep them apart while working on the algorithms
end

function Node{K, V}(key :: K, value :: V) 
	node = Node(Array(Avl{K, V}, 2), key, value, 1, BALANCED)
	node.child = [nil(K, V), nil(K, V)]
	return node
end
# shallow copy
copy{K, V}(node :: Nil{K, V}) = node
function copy{K, V}(node :: Node{K, V}) 
	out = Node(node.key, node.value)
	out.child[LEFT]  = copy(node.child[LEFT])
	out.child[RIGHT] = copy(node.child[RIGHT])
	out.count = node.count
	out.bal = node.bal
	out
end

# depth is all relative
deeper_copy{K, V}(node :: Nil{K, V}) = node
function deeper_copy{K, V}(node :: Node{K, V}) 
	out = Node(copy(node.key), copy(node.value))
	out.child[LEFT]  = deeper_copy(node.child[LEFT])
	out.child[RIGHT] = deeper_copy(node.child[RIGHT])
	out.count = node.count
	out.bal = node.bal
	out
end


isempty (node :: Avl) = isa(node, Nil)
notempty (node :: Avl) = isa(node, Node)

length{K, V}(node :: Nil{K, V}) = 0
length{K, V}(node :: Node{K, V}) = node.count

# follow highest path to bottom
height{K, V}(node :: Nil{K, V}) = 0
function height{K, V}(node :: Node{K, V})
	if node.bal != RIGHT
		return 1 + height(node.child[LEFT])
	end
	1 + height(node.child[RIGHT])
end

isequal{K,V}(a ::  Nil{K,V}, b :: Nil{K,V}, cf :: Function) = true
isequal{K,V}(a :: Node{K,V}, b :: Nil{K,V}, cf :: Function) = false
isequal{K,V}(a ::  Nil{K,V}, b :: Node{K,V}, cf :: Function) = false
function isequal{K,V}(a :: Node{K,V}, b :: Node{K,V}, cf :: Function) 
	   (!cf(a.key, b.key)) &&
	   (!cf(b.key, a.key)) &&
	   (isequal(a.value, b.value)) &&
	   (isequal(a.child[LEFT], b.child[LEFT], cf)) &&
	   (isequal(a.child[RIGHT], b.child[RIGHT], cf)) 
	# no need to bother with validity here
end


function rotate(node, side)
	edis = UNISIDE - side
	side_bal = node.child[side].bal
	if side_bal == edis 
		
		
	#	side-edis rotate, 'side' is left, 'edis' is right (in this drawing)
	#
	#
	#                  Z                            Y'
	#                 / \                         /   \
	#                /   \                       /     \
	#               /     \                     /       \
	#              X       d       -->         X'        Z'
	#             / \                         / \       / \                         
	#            /   \                       /   \     /   \
	#           a     Y                     a     b   c     d
	#                / \
	#               b   c
	#
		node_X = node.child[side]
		node_Y = node_X.child[edis]
		node.child[side] = node_Y.child[edis]		# node = Z at this point
		node_X.child[edis] = node_Y.child[side]
		node_Y.child[side] = node_X
		node_Y.child[edis] = node
		
		count_X = node_X.count - node_Y.count + length(node_X.child[edis]) # X' = X - Y + b
		count_Z = node.count - node_X.count + length(node.child[side]) # Z' = Z - X + c
		node_Y.count = count_X + count_Z + 1
		node_X.count = count_X
		node.count = count_Z
		
		if node_Y.bal == side 
			node_Y.child[side].bal = BALANCED
			node_Y.child[edis].bal = edis
		elseif node_Y.bal == edis 
			node_Y.child[side].bal = side
			node_Y.child[edis].bal = BALANCED
		elseif node_Y.bal == BALANCED 
			# in case of delete
			node_Y.child[side].bal = BALANCED
			node_Y.child[edis].bal = BALANCED
		end
		node_Y.bal = BALANCED
	
		return (false, node_Y)
	end

#            side-side rotate,  'side' is left, 'edis' is right
#
#
#                  Y                           X'
#                 / \                         / \
#                /   \                       /   \
#               /     \                     /     \
#              X       c     -->           a       Y'
#             / \                                 / \                         
#            /   \                               /   \
#           a     b                             b     c
#
#
	node_Y = node	 
	node = node.child[side]	
	count_X = node.count	
	count_b = length(node.child[edis])
	count_Y = node_Y.count - count_X + count_b 
	node_Y.count = count_Y
	node.count = node.count - count_b + count_Y
	node_Y.child[side] = node.child[edis]
	node.child[edis] = node_Y
	
	if side_bal == side 
		node.child[edis].bal = BALANCED
		node.bal = BALANCED
	elseif side_bal == BALANCED 
		# may happen after delete
		node.bal = edis
		node.child[edis].bal = side
		return (true, node)
	end
	
	return (false, node)
end

assign{K, V}(node :: Nil{K, V}, key :: K, value :: V, cf :: Function) = (true, 1, Node(key, value))
function assign{K, V}(node :: Node{K, V}, key :: K, value :: V, cf :: Function)
	if cf(key, node.key)
		side = LEFT
	elseif cf(node.key, key)
		side = RIGHT
	else
		node.value = value
		return (false, 0, node)
	end
	edis = UNISIDE - side 
	longer, increment, node.child[side] = assign(node.child[side], key, value, cf)
	node.count += increment
	if longer
		if node.bal == edis 
			node.bal = BALANCED
			longer = false
		elseif node.bal == BALANCED 
			node.bal = side
		else  
			longer, node = rotate(node, side)
		end
	end
	return (longer, increment, node)
end

# may be destructive to either tree
function tjoin{K, V}(t1 :: Avl{K, V}, m :: (K, V), t2 :: Avl{K, V})
	function rec(p, h) 
		if h <= h2 + 1
			n = Node(m[KEY], m[VALUE])
			if side == RIGHT
				n.bal = bal_conv(h2 - h)
			else
				n.bal = bal_conv(h - h2)
			end
			n.child[edis] = p
			n.child[side] = t2
			n.count = length(p) + length(t2) + 1
			return(true, n) 
		end
		longer, p.child[side] = rec(p.child[side], h - 1 - (p.bal == edis)) 
		p.count = length(p.child[LEFT]) + length(p.child[RIGHT]) + 1
		if longer
			if p.bal == edis 
				p.bal = BALANCED
				longer = false
			elseif p.bal == BALANCED 
				p.bal = side
			else  
				longer, p = rotate(p, side)
			end
		end

		return (longer, p)
	end
		
	side = RIGHT 
	h1 = height(t1)
	h2 = height(t2)
	if h2 > h1
		# make sure h1 >= h2
		t1, t2 = t2, t1
		h1, h2 = h2, h1
		side = LEFT
	end
	edis = UNISIDE - side
	longer, node = rec(t1, h1) 
	node
end

notempty {T} (a :: Array{T, 1}) = !isempty(a)

tsplit{K, V}(node :: Nil{K, V}, key :: K, cf :: Function) = nil(K, V), nil(K, V), nothing
function tsplit{K, V}(node :: Node{K, V}, key :: K, cf :: Function)
	lts = Array(Node{K,V}, 0) 
	gts = Array(Node{K,V}, 0)
	mid = nothing
	t1 = nil(K, V)
	t2 = nil(K, V)
	while notempty(node)
		if cf(key, node.key)
			push(gts, node)
			node = node.child[LEFT]
		elseif cf(node.key, key)
			push(lts, node)
			node = node.child[RIGHT]
		else
			t1 = node.child[LEFT]
			t2 = node.child[RIGHT]
			mid = (node.key, node.value)
			break
		end
	end
	while notempty(lts)
		left = pop(lts)
		t1 = tjoin(left.child[LEFT], (left.key, left.value), t1)
	end
	while notempty(gts)
		right = pop(gts)
		t2 = tjoin(t2, (right.key, right.value), right.child[RIGHT])
	end
	return t1, t2, mid
end


# del first or last, according to b. Assumes node not empty
function del_ultra{K, V}(node :: Node{K, V}, b :: Bool)
	side  = b + 1
	edis = UNISIDE - side
	if isempty(node.child[side])  # at the bottom yet?
		return (true, 1, (node.key, node.value), node.child[edis])
	end
 
	shorter, decrement, ret_val, node.child[side] = del_ultra(node.child[side], b)
	node.count -= decrement
	
	if shorter == false
		return (false, decrement, ret_val, node)
	end
	
	if node.bal == side 
		node.bal = BALANCED
	elseif node.bal == BALANCED 
		node.bal = edis
		shorter = false
	else node.bal == edis
		longer, node = rotate(node, edis)
		shorter = !longer
	end
	return (shorter, decrement, ret_val, node) 
end

del_last{K, V}(node :: Avl{K, V}) = del_ultra(node, true)

del_first{K, V}(node :: Avl{K, V}) = del_ultra(node, false) 

function del_helper{K, V} (node :: Avl{K, V})
	if isempty(node.child[LEFT]) 
		return (true, 1, (node.key, node.value), node.child[RIGHT])
	elseif isempty(node.child[RIGHT]) 
		return (true, 1, (node.key, node.value), node.child[LEFT])
	end 
	
	shorter, decrement, ret_val, node.child[RIGHT] = del_first(node.child[RIGHT])
	node.count -= decrement
	ret_val, node.key, node.value = (node.key, node.value), ret_val[KEY], ret_val[VALUE] 
	if shorter 
		if node.bal == RIGHT 
			node.bal = BALANCED
		elseif node.bal == BALANCED 
			node.bal = LEFT
			shorter = false
		elseif node.bal == LEFT 
			longer, node = rotate (node, LEFT)
			shorter = !longer
		end
	end
	
 	return (shorter, decrement, ret_val, node)
end


# Consider rotating to the bottom instead, perhaps more cache efficient?
del{K, V}(node :: Nil{K, V}, key :: K, cf :: Function) = throw (KeyError(key))
function del{K, V}(node :: Avl{K, V}, key :: K, cf :: Function)
	side = cf(key, node.key)
	if side != LEFT 
		if cf(node.key, key)
			side = RIGHT
		else
			return del_helper(node)
		end
	end
	edis = UNISIDE - side 

	shorter, decrement, ret_val, node.child[side] = del(node.child[side], key, cf)
	
	node.count -= decrement
	if shorter == false 
		return (false, decrement, ret_val, node)
	end
 
	if node.bal == side 
		node.bal = BALANCED
	elseif node.bal == BALANCED 
		node.bal = edis
		shorter = false 
	elseif node.bal == edis 
		longer, node = rotate(node, edis)
		shorter = !longer 
	end
	
	return (shorter, decrement, ret_val, node)
end

# TOR! YOU HAVE TO REFACTOR BETTER
del{K, V}(node :: Nil{K, V}, key :: K, default, cf :: Function) = (false, 0, default, node)
function del{K, V}(node :: Avl{K, V}, key :: K, default, cf :: Function)
	side = cf(key, node.key)
	if side != LEFT 
		if cf(node.key, key)
			side = RIGHT
		else
			return del_helper(node)
		end
	end

	shorter, decrement, ret_val, node.child[side] = del(node.child[side], key, default, cf)

	edis = UNISIDE - side 

	node.count -= decrement
	if shorter == false 
		return (false, decrement, ret_val, node)
	end
 
	if node.bal == side 
		node.bal = BALANCED
	elseif node.bal == BALANCED 
		node.bal = edis
		shorter = false 
	elseif node.bal == edis 
		longer, node = rotate(node, edis)
		shorter = !longer 
	end
	
	return (shorter, decrement, ret_val, node)
end


# checks structure, that is, is node balanced as an AVL tre?
valid_avl{K, V}(node :: Nil{K, V}) = (true, 0) 
function valid_avl{K, V}(node :: Node{K, V})
	(valid_l, height_l) = valid_avl (node.child[LEFT])
	(valid_r, height_r) = valid_avl (node.child[RIGHT])
	bal = height_r - height_l 
	valid = node.bal == [LEFT, BALANCED, RIGHT] [(height_r - height_l) + 2] # check avl structure
	return (valid && valid_l && valid_r, max(height_l, height_r) + 1)		
end

# is node the root of an avl tree?
valid_count{K, V}(node :: Nil{K, V}) = (true, 0)
function valid_count{K, V}(node :: Node{K, V})
	(true_l, count_l) = valid_count (node.child[LEFT])
	(true_r, count_r) = valid_count (node.child[RIGHT])
	count = count_l + count_r + 1
	return ((count == node.count) && true_l && true_r, count)
end

# is node sorted, that is, do the keys form a set, and are they sorted?
valid_sort{K, V}(node :: Nil{K, V}, cf :: Function) = true
function valid_sort{K, V}(node :: Node{K, V}, cf :: Function)
	prev = first(node)
	flag = true
	for kv in Goright_kv(node, first(node)[KEY], cf)
		if flag then
			flag = false
			continue # skip first iteration
		end
		if ! cf(prev[KEY], kv[KEY])
			return false
		end
		prev = kv
	end
	return true
end

# call this on a tree to display it's structure. Works with very small trees only
# a number is followed by '-', "", or '+' indicates count and balance factors
# below is either a key or key, value pair, according to show_values bool parameter

function draw(node, show_values, show_counts, screen_cols)
	function draw_rec (n, x, y, space)
		function plot_text(str, x, y)
			local s = text[y]
			text[y] = strcat (s[1:x-1], str, s[x + length(str):])
		end
		if isempty(n) return end
		bal = ("=", ">", "<")[n.bal + 1]
		
		yp = y
		plot_text(string(bal), x, yp)
		yp += 1
		if show_counts
			plot_text(strcat(n.count), x, yp)
			yp += 1
		end
		if show_values
			plot_text(string(n.key,":",n.value), x, yp)
		else
			plot_text(string(n.key), x, yp)
		end
		draw_rec(n.child[LEFT], x-space, y + 3, div(space, 2))
		draw_rec(n.child[RIGHT], x+space, y + 3, div(space, 2))
	end 

 	if isempty(node)
		println ("Tree empty")
		return
	end
	
	text = Array(String, 0)
	s = repeat(" ", screen_cols)
	for i = 1:300
		push(text, s)
	end

	draw_rec(node, div(screen_cols, 2), 2, div(screen_cols, 4))

	while last(text) == s
		pop(text)
	end
	
	for line in text
		println(line)
	end
	println(repeat("-", screen_cols))
end
draw(node) = draw(node, false, false, 128)
draw(node, a, b) = draw(node, a, b, 128)


#end # AVL

