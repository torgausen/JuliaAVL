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




before{K, V} (node :: Nil{K, V}, key :: K, cf :: Function) = throw("before: before called on Nil{$K, $V}")
function before{K, V} (node :: Node{K, V}, key :: K, cf :: Function)
	best = nothing
	while notempty(node)
		if cf(key, node.key)
			node = node.child[LEFT]
			if isempty(node)
				throw("before: nothing before $key")
			end
		elseif cf(node.key, key)
			best = (node.key, node.value)
			node = node.child[RIGHT]
		else
			if isempty (node.child[LEFT])
				if best != nothing
					return best
				end
				throw("before: nothing before $key")
			else
				return last(node.child[LEFT])
			end
		end
	end
	return best
end

after{K, V} (node :: Nil{K, V}, key :: K, cf :: Function) = throw("after: after called on Nil{$K, $V}")
function after{K, V} (node :: Node{K, V}, key :: K, cf :: Function)
	best = nothing
	while notempty(node)
		if cf(key, node.key)
			best = (node.key, node.value)
			node = node.child[LEFT]
		elseif cf(node.key, key)
			node = node.child[RIGHT]
			if isempty(node)
				throw("after: nothing after $key")
			end
		else
			if isempty (node.child[RIGHT])
				if best != nothing
					return best
				end
				throw("after: nothing after $key")
			else
				return first(node.child[RIGHT])
			end
		end
	end
	return best
end



function select{K, V}(node :: Avl{K, V}, ind :: Real)
	rec(n :: Nil, left :: Int) = throw("select: index $left out of range")
	function rec(n :: Node{K, V}, left :: Int)
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

# if key in node, return rank, else throw key error
function rank{K, V}(node :: Avl{K, V}, key :: K, cf :: Function)
	rec(n :: Nil, left :: Int) = throw(KeyError(key))
	function rec(n :: Node{K, V}, left :: Int)
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

# last (node, n)

first{K, V}(node :: Nil{K, V}) = throw ("first called on empty SortDict{$K, $V}") 
function first{K, V}(node :: Node{K, V})
	while notempty(node.child[LEFT]) 
		node = node.child[LEFT]
	end
	(node.key, node.value)
end

last{K, V}(node :: Nil{K, V}) = throw ("last called on empty SortDict{$K, $V}") 
function last{K, V}(node :: Node{K, V})
	while notempty(node.child[RIGHT]) 
		node = node.child[RIGHT]
	end
	(node.key, node.value)
end

ultra{K, V}(node :: Nil{K, V}, side :: Bool) = throw ("ultra called on empty SortDict{$K, $V}") 
function ultra{K, V}(node :: Node{K, V}, side :: Bool)
	side += 1
	while notempty(node.child[side]) 
		node = node.child[side]
	end
	(node.key, node.value)
end


# deletes either first or last element accodring to variable side, which should be LEFT or RIGHT
function del_ultra{K, V}(node :: Avl{K, V}, side :: Bool)
	side += 1
	edis = UNISIDE - side
	if isempty(node.child[side])  # at the bottom yet?
		return (true, 1, (node.key, node.value), node.child[edis])
	end
 
	shorter, decrement, ret_val, node.child[side] = del_ultra(node.child[side], side)
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
