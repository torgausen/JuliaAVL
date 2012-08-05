#
# 	functions that operate on the tree as if it was a vector
#	or any other ordered collection
#

require ("AVLbase.jl")



ref{K,V}(node :: Nil{K, V}, rng :: Range1{K}, cf :: Function) = Array((K, V), 0)
function ref{K, V}(node :: Node{K, V}, rng :: Range1{K})
	# return array of key,value pairs
	#
	# currently you can't assign to the tree with a range
	# Maybe should not be exported
	
	out = Array((K, V), 0)
	range(n :: Nil{K, V}) = Array((K, V), 0)
	function range(n :: Node{K, V})
		if lst < n.key
			range(n.child[LEFT])
		elseif fst > n.key
			range(n.child[RIGHT])
		else
			range(n.child[LEFT])
			push(out, (n.key, n.value))
			range(n.child[RIGHT])
		end
	end
	fst = first(rng)
	lst = last(rng)
	
	range(node) 
	out # sort(out) # , compare_function)
end



type Stack_and_node {K, V}
	stack :: Array{Avl{K, V}, 1}
	node :: Avl{K, V}
end

# todo: add arbitrary iterators
#
# type Forward{K, V}
# 	node :: Avl{K,V}
# end
# 
# function Forward{K, V}(node :: Avl{K, V}, key :: K, cf :: Function)
# 	stack = Array(Avl{K, V}, 0)
# 	push(stack, nil(K, V))
# 	if cf(key, node.key)
# 		s_node = Node(node.key, node.value) 
# 		s_node.child[RIGHT] = node.child[RIGHT]
# 		push(stack, s_node)
# 		node = node.child[LEFT]
# 	elseif cf(node.key, key)
# 		node = node.child[RIGHT]
# 	else
# 		return Stack_and_node{K, V}(stack, node)
# 	end
# end
# 
# function start{K, V} (Node :: Avl{K, V}) 
# 	iter
# end	





######################

function start{K, V} (node :: Avl{K, V}) 
	state = Stack_and_node(Array(Avl{K, V}, 0), node)
	push(state.stack, nil(K, V)) # guard element
	state
end

done{K, V}(junk :: Avl{K, V}, state :: Stack_and_node {K, V}) = isempty(state.stack)

function next{K, V} (junk :: Avl{K, V}, state :: Stack_and_node {K, V}) 
	stack = state.stack
	node = state.node
	while notempty(node.child[LEFT])
		s_node = Node(node.key, node.value)
		s_node.child[RIGHT] = node.child[RIGHT]
		push(stack, s_node)
		node = node.child[LEFT]
	end 
	elem = (node.key, node.value)
	node = node.child[RIGHT]
	if isempty(node)
		node = pop(stack)
	end 
	state.stack = stack
	state.node = node
	return elem, state
end

#for x in iter(sd, key, false)
	

# # general version of 'before' and 'after' with direction flag
# nextto{K, V} (node :: Nil{K, V}, key :: K, dir :: Bool) = throw("nextto called on Nil{$K, $V}")
# function nextto{K, V} (node :: Node{K, V}, key :: K, dir :: Bool) 
# 	stack = Array((K, V), 0)
# 	function find_in_path()
# 		if isempty(stack)
# 			throw("node has no key before $key")
# 		end
# 		best = pop(stack)
# 		while best[1] > key
# 			best = pop(stack)
# 		end
# 		for pair in stack
# 			if pair[1] <= key && pair[1] > best[1]
# 				best = pair
# 			end
# 		end
# 		best
# 	end
# 	while notempty(node)
# 		if key < node.key
# 			push(stack, (node.key, node.value))
# 			node = node.child[LEFT]
# 		elseif key > node.key
# 			push(stack, (node.key, node.value))
# 			node = node.child[RIGHT]
# 		else
# 			if isempty(node.child[LEFT])
# 				break
# 			else
# 				return last(node.child[LEFT])
# 			end
# 		end 
# 	end 
# 	return find_in_path()
# end


# # backup
# # before and after could perhaps also be written with rank and select?
# before{K, V} (node :: Nil{K, V}, key :: K) = throw("before called on Nil{$K, $V}")
# function before{K, V} (node :: Node{K, V}, key :: K) 
# 	stack = Array((K, V), 0)
# 	function find_in_path()
# 		if isempty(stack)
# 			throw("node has no key before $key")
# 		end
# 		best = pop(stack)
# 		while best[1] > key
# 			best = pop(stack)
# 		end
# 		for pair in stack
# 			if pair[1] <= key && pair[1] > best[1]
# 				best = pair
# 			end
# 		end
# 		best
# 	end
# 	while notempty(node)
# 		if key < node.key
# 			push(stack, (node.key, node.value))
# 			node = node.child[LEFT]
# 		elseif key > node.key
# 			push(stack, (node.key, node.value))
# 			node = node.child[RIGHT]
# 		else
# 			if isempty(node.child[LEFT])
# 				break
# 			else
# 				return last(node.child[LEFT])
# 			end
# 		end 
# 	end 
# 	return find_in_path()
# end
# 

# before and after could perhaps also be written with rank and select?
before{K, V} (node :: Nil{K, V}, key :: K) = throw("before called on Nil{$K, $V}")
function before{K, V} (node :: Node{K, V}, key :: K, cf :: Function) 
	stack = Array((K, V), 0)
	function find_in_path()
		if isempty(stack)
			throw("node has no key before $key")
		end
		best = pop(stack)
		while cf(key, best[KEY])
			best = pop(stack)
		end
		for pair in stack
			if cf(pair[KEY], key) && cf(best[KEY], pair[KEY])
				best = pair
			end
		end
		best
	end
	while notempty(node)
		if cf(key, node.key)
			push(stack, (node.key, node.value))
			node = node.child[LEFT]
		elseif cf(node.key, key)
			push(stack, (node.key, node.value))
			node = node.child[RIGHT]
		else
			if isempty(node.child[LEFT])
				break
			else
				return last(node.child[LEFT])
			end
		end 
	end 
	return find_in_path()
end

# before and after could perhaps also be written with rank and select?
after{K, V} (node :: Nil{K, V}, key :: K) = throw("after called on Nil{$K, $V}")
function after{K, V} (node :: Node{K, V}, key :: K, cf :: Function) 
	stack = Array((K, V), 0)
	function find_in_path()
		if isempty(stack)
			throw("node has no key after $key")
		end
		best = pop(stack)
		while cf(best[KEY], key)
			best = pop(stack)
		end
		for pair in stack
			if cf(key, pair[KEY]) && cf(pair[KEY], best[KEY])
				best = pair
			end
		end
		best
	end
	while notempty(node)
		if cf(node.key, key)
			push(stack, (node.key, node.value))
			node = node.child[RIGHT]
		elseif cf(key, node.key)
			push(stack, (node.key, node.value))
			node = node.child[LEFT]
		else
			if isempty(node.child[RIGHT])
				break
			else
				return first(node.child[RIGHT])
			end
		end 
	end 
	return find_in_path()
end





function select{K, V}(node :: Avl{K, V}, ind :: Int)
	rec(n :: Nil, left :: Int) = throw("select: index $left out of range")
	function rec(n :: Node, left :: Int)
		sofar = left + length(n.child[LEFT])
		if sofar == ind
			return (n.key, n.value)
		elseif sofar < ind
			return rec(n.child[RIGHT], sofar + 1)
		else
			return rec(n.child[LEFT], left)
		end
	end	
	rec(node, 0)
end



# rev_rank, rev_select (simple, just select (sd.n - i)
#rev_rank{K, V}(node :: Avl{K, V}, key ::) = length(node) - rank(node, key)	   
function rank{K, V}(node :: Avl{K, V}, key :: K, cf :: Function)
	rec(n :: Nil, left :: Int) = left 
	function rec(n :: Node, left)
		if cf(key, n.key)
			return rec(n.child[LEFT], left)
		elseif cf(n.key, key)
			left += length(n.child[LEFT]) + 1
			return rec(n.child[RIGHT], left)
		else
			return length(n.child[LEFT]) + left
		end
	end
	rec(node, 0)
end



# first (node, n) # same as take in haskell

# last (node, b)

first{K, V}(node :: Nil{K, V}) = throw ("function first called on empty SordDict{$K, $V}") 
function first{K, V}(node :: Node{K, V})
	while notempty(node.child[LEFT]) 
		node = node.child[LEFT]
	end
	(node.key, node.value)
end

last{K, V}(node :: Nil{K, V}) = throw ("function last called on empty SordDict{$K, $V}") 
function last{K, V}(node :: Node{K, V})
	while notempty(node.child[RIGHT]) 
		node = node.child[RIGHT]
	end
	(node.key, node.value)
end

# deletes either first or last element accodring to variable side, which should be LEFT or RIGHT
function del_extreme{K, V}(node :: Avl{K, V}, side :: Int8)
	edis = UNISIDE - side
	if isempty(node.child[side])  # at the bottom yet?
		return (true, 1, (node.key, node.value), node.child[edis])
	end
 
	shorter, decrement, ret_val, node.child[side] = del_extreme(node.child[side], side)
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

function test_rank()
	t = nil(Int,Float64)
	for i in 5:30
		if i != 15
			f, c, t = assign(t, i, rand(), isless)
		end
	end
	draw(t, false, true, 128)

	println(rank(t, 8))
	println(rank(t, 18))
	println(rank(t, 1))
	println(rank(t, 344))
	println(rank(t, -1210))
	println(rank(t, 15))
	println(rank(t, 16))
end
