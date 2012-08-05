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
# 
# # The keys must be sorted. This is tested in higher level functions. For a set, the keys must also be unique
# function build{K, V}(ks :: Vector{K}, vs :: Vector{V})
# 	function rec(fst, lst)
# 		len = (lst - fst) + 1
# 		if len <= 0
# 			return 0, 0, Nil{K, V}()
# 		end
# 		mid = fst + ifloor(len / 2) 
# 		node = Node(ks[mid], vs[mid])
# 		hl, cl, node.child[LEFT] = rec(fst, mid - 1)
# 		hr, cr, node.child[RIGHT] = rec(mid + 1, lst)
# 		count = cl + cr + 1
# 		node.count = count
# 		node.bal = [LEFT, BALANCED, RIGHT] [(hr - hl) + 2]
# 		return max(hl, hr) + 1, count, node
# 	end
# 	h, c, n = rec(1, length(vs))
# 	return n
# end

function Node{K, V}(key :: K, value :: V) 
	node = Node(Array(Avl{K, V}, 2), key, value, 1, BALANCED)
	node.child = [nil(K, V), nil(K, V)]
	return node
end

isempty (node :: Avl) = isa(node, Nil)
notempty (node :: Avl) = isa(node, Node)

length{K, V}(node :: Nil{K, V}) = 0
length{K, V}(node :: Node{K, V}) = node.count

height{K, V}(node :: Nil{K, V}) = 0
function height{K, V}(node :: Node{K, V})
	if node.bal == RIGHT
		1 + height(node.child[LEFT])
	end
	1 + height(node.child[RIGHT])
end


######################################################################
# WHY MUST I DO THIS:
copy{K, V}(node :: Nil{K, V}) = node 
function copy{K, V}(node :: Node{K, V})
	left = copy(node.child[LEFT])
	right = copy(node.child[RIGHT])
	Node([left, right], node.count, node.bal)
end

# INSTEAD OF THIS?
# copy{K,V}(node :: Nil{K, V}) = node
# function copy{K,V}(node :: Node{K, V})  
# 	Node([copy(node.child[LEFT]), copy(node.child[RIGHT])],
# 	node.key, node.value, node.count, node.bal)
# end
######################################################################3

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






# TO BE REMOVED
#
function show{K, V}(node :: Avl{K, V})
	#until = last(node)
	#for pair in node
		
	function rec (node :: Avl)
		if isempty(node) 
			return ""
		end
		# I couldn't figure out how to add spaces and commas correctly
		return strcat (rec(node.child[LEFT]), " (", node.key, ":", node.value, ") ", rec(node.child[RIGHT]))
	end
 	print (strcat ("(", rec(node), ")\n"))
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

get{K, V} (node :: Nil{K, V}, key :: K, cf :: Function) = throw(KeyError(key))
function get{K, V}(node :: Node{K, V}, key :: K, cf :: Function)
	if cf(key, node.key)
		get(node.child[LEFT], key, cf)
	elseif cf(node.key, key)
		get(node.child[RIGHT], key, cf)
	else
		return (node.key, node.value)
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
		if lst < n.key
			rec(n.child[LEFT])
		elseif fst > n.key
			rec(n.child[RIGHT])
		else
			rec(n.child[LEFT])
			push(out, (n.key, n.value))
			rec(n.child[RIGHT])
		end
		nothing
	end
	rec(node) 
	out 
end

# returns tuple of (array of keys, array of values)
# non destructive
function flatten{K, V} (node :: Avl{K, V}, len :: Int)
	ks = Array(K, len)
	vs = Array(V, len)
	stack = Array(Avl{K, V}, 0)
	push(stack, nil(K, V)) # guard element
	i = 1 
	while notempty(node)
		while notempty(node.child[LEFT])
			s_node = Node(node.key, node.value)
			s_node.child[RIGHT] = node.child[RIGHT]
			push(stack, s_node)
			node = node.child[LEFT]
		end	
		ks[i] = node.key
		vs[i] = node.value
		i += 1
		node = node.child[RIGHT]
		
		if empty(node)
			node = pop(stack)
		end 
	end 
	return (ks, vs)
end


# Backup of flatten
# # returns tuple of (array of keys, array of values)
# function flatten{K, V} (node :: Avl{K, V})
# 	ks = Array(K, 0)
# 	vs = Array(V, 0)
# 	stack = Array(Avl{K, V}, 0)
# 	push(stack, nil(K, V))
# 	while notempty(node)
# 		while notempty(node)
# 			if notempty(node.child[LEFT])
# 				s_node = Node(node.key, node.value)
# 				s_node.child[RIGHT] = node.child[RIGHT]
# 				push(stack, s_node)
# 				node = node.child[LEFT]
# 			else 
# 				push(ks, node.key)
# 				push(vs, node.value)
# 				node = node.child[RIGHT]
# 			end
# 		end 
# 		node = pop(stack)
# 	end 
# 	return (ks, vs)
# end




# # only for multi-dicts
#
# insert{K, V}(node :: Nil{K, V}, key :: K, value :: V) = (true, Node(key, value))
# function insert{K, V}(node :: Node{K, V}, key :: K, value :: V)
# 	# will later use user supplied function with isless as default 
# 
# 	# side and edis are opposites, where LEFT = 1 and right = 2
# 	# so if side = 2 , edis = 1 and vice versa
# 	
# 	side = (key > node.key) + 1
# 	longer, node.child[side] = insert(node.child[side], key, value)
# 	
# 	edis = UNISIDE - side 
# 	if longer
# 		if node.bal == edis 
# 			node.bal = BALANCED
# 			longer = false
# 		elseif node.bal == BALANCED 
# 			node.bal = side
# 		else  
# 			longer, node = rotate(node, side)
# 		end
# 	end
# 	return (longer, node)
# end

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

# del_first included here because it's so important to del
# assumes node not empty
function del_first{K, V}(node :: Avl{K, V})
	if isempty(node.child[LEFT])  # at the bottom yet?
		return (true, 1, (node.key, node.value), node.child[RIGHT])
	end
 
	shorter, decrement, ret_val, node.child[LEFT] = del_first(node.child[LEFT])
	node.count -= decrement
	
	if shorter == false
		return (false, decrement, ret_val, node)
	end
	
	if node.bal == LEFT 
		node.bal = BALANCED
	elseif node.bal == BALANCED 
		node.bal = RIGHT
		shorter = false
	else node.bal == RIGHT 
		longer, node = rotate(node, RIGHT)
		shorter = !longer
	end
	return (shorter, decrement, ret_val, node) 
end
# assumes node not empty
function del_last{K, V}(node :: Avl{K, V})
	if isempty(node.child[RIGHT])  # at the bottom yet?
		return (true, 1, (node.key, node.value), node.child[LEFT])
	end
 
	shorter, decrement, ret_val, node.child[RIGHT] = del_last(node.child[RIGHT])
	node.count -= decrement
	
	if shorter == false
		return (false, decrement, ret_val, node)
	end
	
	if node.bal == RIGHT 
		node.bal = BALANCED
	elseif node.bal == BALANCED 
		node.bal = LEFT
		shorter = false
	else node.bal == LEFT 
		longer, node = rotate(node, LEFT)
		shorter = !longer
	end
	return (shorter, decrement, ret_val, node) 
end

# Handles the case of actually deleting a node when it's found
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
 
del{K, V}(node :: Nil{K, V}, key :: K, cf :: Function) = throw (KeyError(key))
function del{K, V}(node :: Avl{K, V}, key :: K, cf :: Function)
	side = key < node.key
	if side == false
		if key > node.key
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

function rotate(node, side)
	edis = UNISIDE - side
	side_bal = node.child[side].bal
	if side_bal == edis 
		
		
	#	side-edis rotate, 'side' is left, 'edis' is right
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



# 
# 
# # Doesn't even work yet !!!
# fast_insert2{K, V}(node :: Nil{K, V}, key :: K, value :: V) = Node(key, value)
# function fast_insert2{K, V}(node :: Node{K, V}, key :: K, value :: V)
# 	# try to use loops instead of recursion
# 	stack = Array((Node{K, V}, Int8), 0)  
# 	
# 	#find place to insert
# 	while notempty (node)
# 		side = (key > node.key) + 1
# 		push(stack, (node, side))
# 		node = node.child[side]
# 	end
# 	# insert new key
# 	node, side = pop(stack) 
# 	node.child[side] = Node(key, value)
#
#	
#	# eleiminate all but the necessary condtional branches
# 	longer = true
# 	while (longer) && (isempty(stack) == false) # if longer must check for balance changes
# 		if (node.bal == side) 
# 			longer, node = rotate(node, side) 
# 			parent, side = pop(stack) 
# 			parent.child[side] = node
# 			node = parent	
# 			break # during insert, rotate will never leave the branch higher
# 		end
# 		
# 		longer, node.bal = begin
# 			bal = node.bal
# 			nl = int8(!longer)
# 			nl |= nl << 1
# 			upper = bal & nl # bal if not longer
# 			m = bal $ bal >> 1
# 			m $= int8(1)
# 			m |= m << 1
# 			lower = m & side
# 			lower = (lower & ~nl) & 0x3 
# 			
# 			(bool(int8(longer) & ~(bal | bal >> 1)) , lower | upper)
# 		end
# 		
# 		parent, side = pop(stack) 
# 		parent.child[side] = node
# 		node = parent	
# 	end	
# 	while isempty(stack) == false
# 		parent, side = pop(stack) 
# 		parent.child[side] = node
# 		node = parent	
# 	end	
# 	return node
# end
# 


