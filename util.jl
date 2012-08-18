
#require ("AVLbase.jl")
#require ("AVLorder.jl")
#require ("AVLiter.jl")


# is a vector sorted by function cf ?
function issortedset{T}(a :: Vector{T}, cf :: Function)
	for i = 2 : length(a)
		if ! cf(a[i-1], a[i])
			return false
		end
	end
	return true
end


map{K, V}(f :: Function, node :: Nil{K, V}) = node
function map{K, V}(f :: Function, node :: Node{K, V})
	out = Node(node.key, f(node.value))
	out.child[LEFT]  = map(f, node.child[LEFT])
	out.child[RIGHT] = map(f, node.child[RIGHT])
	out.count = node.count
	out.bal = node.bal
	out
end		

map!{K, V}(fn :: Function, node :: Nil{K, V}) = node
function map!{K, V}(fn :: Function, node :: Node{K, V})
	node.value = fn(node.value)
	map!(fn, node.child[LEFT])
	map!(fn, node.child[RIGHT])
end		



# The keys must be sorted. For a set, the keys must also be unique
function build{K, V}(ks :: Vector{K}, vs :: Vector{V})
	function rec(fst, lst)
		len = (lst - fst) + 1
		if len <= 0
			return 0, 0, Nil{K, V}()
		end
		mid = fst + div(len, 2) 
		node = Node(ks[mid], vs[mid])
		hl, cl, node.child[LEFT] = rec(fst, mid - 1)
		hr, cr, node.child[RIGHT] = rec(mid + 1, lst)
		count = cl + cr + 1
		node.count = count
		node.bal = [LEFT, BALANCED, RIGHT] [(hr - hl) + 2]
		return max(hl, hr) + 1, count, node
	end
	h, c, n = rec(1, length(ks))
	return n
end

function flatten {K, V} (node :: Avl{K, V}) 
	ks = Array(K, length(node))
	vs = Array(V, length(node))
 	stack = Node{K, V}[]
	while notempty(node)
		push(stack, node)
		node = node.child[LEFT]
	end
	i = 1
	while notempty(stack) 
		node = pop(stack)
		ks[i] = node.key
		vs[i] = node.value
		i += 1
		
		node = node.child[RIGHT]
		if notempty(node)
			push(stack, node) 
			node = node.child[LEFT]
			while notempty(node) 
				push(stack, node)
				node = node.child[LEFT]
			end
		end
	end
	(ks, vs)
end


