#
#	Basic constants, functions, types and algorithms. 
# 	None of these are exported?
#	

		
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
	# It's just simpler to keep them appart while working on the algorithms
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


=={K,V}(a ::  Nil{K,V}, b :: Nil{K,V}) = true
=={K,V}(a :: Node{K,V}, b :: Nil{K,V}) = false
=={K,V}(a ::  Nil{K,V}, b :: Node{K,V}) = false
function =={K,V}(a :: Node{K,V}, b :: Node{K,V}) 
	(a.key == b.key) &&
	(a.value == b.value) &&
	(a.child[LEFT] == b.child[LEFT]) &&
	(a.child[RIGHT] == b.child[RIGHT]) 
	# no need to bother with validity here
end

has{K}(node :: Nil, key :: K, cf :: Function) = false
function has{K, V}(node :: Node{K, V}, key :: K, cf :: Function)
	if cf(key, node.key)
		has(node.child[LEFT], key, cf)
	elseif cf(node.key, key)
		has(node.child[RIGHT], key, cf)
	else
		return true
	end
end

get{K, V} (node :: Nil{K, V}, key :: K, default :: V, cf :: Function) = default
function get{K, V}(node :: Node{K, V}, key :: K, default :: V, cf :: Function)
	if cf(key, node.key)
		get(node.child[LEFT], key, default, cf)
	elseif cf(node.key, key)
		get(node.child[RIGHT], key, default, cf)
	else
		return node.value
	end
end

ref{K,V}(node :: Nil{K, V}, key :: K, cf :: Function) = throw(KeyError(key))
function ref{K, V}(node :: Node{K, V}, key :: K, cf :: Function)
	if cf(key, node.key)
		ref(node.child[LEFT], key, cf)
	elseif cf(node.key, key)
		ref(node.child[RIGHT], key, cf)
	else
		return node.value
	end
end

range{K,V}(node :: Nil{K, V}, fst :: K, lst :: K, cf :: Function) = Array((K, V), 0)
function range{K, V}(node :: Node{K, V}, fst :: K, lst :: K, cf :: Function)
	out = Array((K, V), 0)
	rec(n :: Nil{K, V}) = nothing
	function rec(n :: Node{K, V})
		if cf(lst, n.key)
			rec(n.child[LEFT])
		elseif cf(n.key, fst)
			rec(n.child[RIGHT])
		else
			rec(n.child[LEFT])
			push(out, (n.key, n.value))
			rec(n.child[RIGHT])
		end
	end
	rec(node) 
	out 
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

notempty {T} (a :: Array{T, 1}) = length(a) > 0



tsplit{K, V}(node :: Nil{K, V}, key :: K, cf :: Function) = nil(K, V), nil(K, V), nothing
function tsplit{K, V}(node :: Node{K, V}, key :: K, cf :: Function)
	lts = Array(Node{K,V}, 0) 
	gts = Array(Node{K,V}, 0)
	theK = 777
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
			theK = (node.key, node.value)
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
	return t1, t2, theK
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
del_first{K, V}(node :: Avl{K, V}) = del_ultra(node, false) # might perhaps want special verison of this for del... dunno

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

# TOR! YOU HAVE TO REFACTOR MORE!
del_any{K, V}(node :: Nil{K, V}, key :: K, cf :: Function) = (false, 0, nothing, node)
function del_any{K, V}(node :: Avl{K, V}, key :: K, cf :: Function)
	side = cf(key, node.key)
	if side != LEFT 
		if cf(node.key, key)
			side = RIGHT
		else
			return del_helper(node)
		end
	end

	shorter, decrement, ret_val, node.child[side] = del_any(node.child[side], key, cf)

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




