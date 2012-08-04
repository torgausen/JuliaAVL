
# todo: check for small size ratios before using linear time merge
#
# something like: 
#	if n < m * log(n)  
#		build(merge(a,b))
#	else
#		insertall(a,b)
#	end

require ("AVLutil.jl")

union{K, V}(a :: Nil{K, V}, b :: Node{K, V}) = b
union{K, V}(a :: Node{K, V}, b :: Nil{K, V}) = a
function union{K, V}(a :: Node{K, V}, b :: Node{K, V}, cf :: Function)
	if length(a) < length(b)
		a, b = b, a
	end
	n = length(a)
	m = length(b)
	if UNION_RATIO * n < m * log2(n)
		a, b = merge(a, b, cf)
		node = build(a, b)
		return node
	else
		return assign_all(a, b, cf)
	end
end


# wait a minute... there must be a better way to do this?
function intersect{K, V}(n1 :: Avl{K, V}, n2 :: Avl{K, V}, cf :: Function)

	ks = Array(K, 0)
	vs = Array(V, 0)
	
	s1 = Array(Avl{K, V}, 0)
	s2 = Array(Avl{K, V}, 0)
	
	push(s1, nil(K, V))
	push(s2, nil(K, V))
	
	while notempty(n1) && notempty(n2)
		while notempty(n1.child[LEFT])
			s_node = Node(n1.key, n1.value)
			s_node.child[RIGHT] = n1.child[RIGHT]
			push(s1, s_node)
			n1 = n1.child[LEFT]
		end 
		while notempty(n2.child[LEFT])
			s_node = Node(n2.key, n2.value)
			s_node.child[RIGHT] = n2.child[RIGHT]
			push(s2, s_node)
			n2 = n2.child[LEFT]
		end
		
		if cf(n1.key, n2.key)
			n1 = n1.child[RIGHT]
			if isempty(n1)   
				n1 = pop(s1)   
			end
		elseif cf(n2.key, n1.key)
			n2 = n2.child[RIGHT]
			if isempty(n2)   
				n2 = pop(s2)   
			end
		else
			push(ks, n1.key)
			push(vs, n1.value)
			
			n1 = n1.child[RIGHT]
			if isempty(n1)   
				n1 = pop(s1)   
			end
			n2 = n2.child[RIGHT]
			if isempty(n2)   
				n2 = pop(s2)   
			end
		end	
	end 
	node = build(ks,vs)
	return node
end
	


 
# # After completion, it dawned on me that this isn't linear time
# # I'll keep it here for a while just in case 
# function intersect{K, V} (n1 :: Avl{K, V}, n2 :: Avl{K, V})
# 	cut{K, V}(n1 :: Nil{K, V}, n2 :: Nil{K, V}) = n1
# 	cut{K, V}(n1 :: Node{K, V}, n2 :: Nil{K, V}) = n1
# 	cut{K, V}(n1 :: Nil{K, V}, n2 :: Node{K, V}) = n2
# 	function cut{K, V}(n1 :: Node{K, V}, n2 :: Node{K, V})
# 		if n1.key < n2.key
# 			cut(n1.child[RIGHT], n2)
# 			cut(n1, n2.child[LEFT])
# 		elseif n1.key > n2.key
# 			cut(n1.child[LEFT], n2)
# 			cut(n1, n2.child[RIGHT])
# 		else
# 
# 			flag, node = assign(node, n1.key, n1.value)
# 			cut(n1.child[LEFT], n2.child[LEFT])
# 			cut(n1.child[RIGHT], n2.child[RIGHT])
# 		end
# 	end
# 	node = nil(K, V)
# 	cut(n1, n2)
# 	node
# end
 
