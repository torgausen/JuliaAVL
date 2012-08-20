# 	functions that operate on the tree as if it was a vector
#	or any other ordered collection

range_kv{K,V}(node :: Nil{K, V}, fst :: K, lst :: K, cf :: Function) = Array((K, V), 0)
function range_kv{K, V}(node :: Node{K, V}, fst :: Integer, lst :: Integer, cf :: Function)
	# return array of key,value pairs
	
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

range{K,V}(node :: Nil{K, V}, fst :: K, lst :: K, cf :: Function) = Array((V), 0)
function range{K, V}(node :: Node{K, V}, fst :: Integer, lst :: Integer, cf :: Function)
	# return array values
	
	out = Array(V, 0)
	rec(n :: Nil{K, V}) = nothing
	function rec(n :: Node{K, V})
		if cf(lst, n.key)
			rec(n.child[LEFT])
		elseif cf(n.key, fst)
			rec(n.child[RIGHT])
		else
			rec(n.child[LEFT])
			push(out, n.value)
			rec(n.child[RIGHT])
		end
	end
	rec(node) 
	out
end



before{K, V} (node :: Nil{K, V}, key :: K, cf :: Function) = throw("before: before called on Nil{$K, $V}")
function before{K, V} (node :: Node{K, V}, key :: K, cf :: Function)
	best = nothing
	while notempty(node)
		if cf(key, node.key)
			node = node.child[LEFT]
			if isempty(node)
				if best == nothing
					throw("before: nothing before $key")
				end
				return best
			end
		elseif cf(node.key, key)
			best = (node.key, node.value)
			node = node.child[RIGHT]
		else
			if isempty (node.child[LEFT])
				if best == nothing
					throw("before: nothing before $key")
				end
				return best
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
				if best == nothing
					throw("before: nothing after $key")
				end
				return best
			end
		else
			if isempty (node.child[RIGHT])
				if best == nothing
					throw("after: nothing after $key")
				end
				return best
			else
				return first(node.child[RIGHT])
			end
		end
	end
	return best
end



select{K, V}(n :: Nil, ind :: Int, left :: Int) = throw("select: index $left out of range")
function select{K, V}(n :: Node{K, V}, ind :: Int, left :: Int)
	sofar = left + length(n.child[LEFT])
	if sofar == ind
		(n.key, n.value)
	elseif sofar < ind
		select(n.child[RIGHT], ind, sofar + 1)
	else
		select(n.child[LEFT], ind, left)
	end
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


