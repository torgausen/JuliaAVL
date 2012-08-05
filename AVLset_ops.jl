
const UNION_RATIO = 1.0
const INTERSECT_RATIO = 1.0


require ("AVLutil.jl")


# union of two trees in linear time (n + m)
function linear_non_destr_union{K, V} (n1 :: Avl{K, V}, n2 :: Avl{K, V}, cf :: Function)
	ks = Array(K, 0)
	vs = Array(V, 0)
	
	s1 = Array(Avl{K, V}, 0)
	s2 = Array(Avl{K, V}, 0)
	
	push(s1, nil(K, V))
	push(s2, nil(K, V))
	
	# establish a guard
	first1 = first(n1)
	first2 = first(n2)
	if cf(first1[KEY], first2[KEY])
		push(ks, first1[KEY])
		push(vs, first1[VALUE])
	else
		push(ks, first2[KEY])
		push(vs, first2[VALUE])
	end
	
	while notempty(n1) && notempty(n2)
		# get leftmost position for both trees
		while notempty(n1.child[LEFT])
			s_node = Node(n1.key, n1.value) # non destructive
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
			if cf(last(ks), n1.key)
				push(ks, n1.key)
				push(vs, n1.value)
			end
			n1 = n1.child[RIGHT]
			if isempty(n1)   
				n1 = pop(s1)   
			end
		else cf(n2.key, n1.key) # elseif ... need combination function here
			if cf(last(ks), n2.key)
				push(ks, n2.key)
				push(vs, n2.value)
			end
			n2 = n2.child[RIGHT]
			if isempty(n2)   
				n2 = pop(s2)   
			end
		end	
	end 
	
	if isempty(n1)
		node = n2
		stack = s2
	else
		node = n1
		stack = s1
	end
	
	while notempty(node)
		while notempty(node)
			if notempty(node.child[LEFT])
				s_node = Node(node.key, node.value)
				s_node.child[RIGHT] = node.child[RIGHT]
				push(stack, s_node)
				node = node.child[LEFT]
			else 
				if cf(last(ks), node.key)
					push(ks, node.key)
					push(vs, node.value)
				end
				node = node.child[RIGHT]

			end
		end 
		node = pop(stack)
	end 
	return build(ks, vs)
end



# non-destructive union of two trees in m log n time
function union_nlogn_non_destr{K, V} (big :: Avl{K, V}, small :: Avl{K, V}, cf :: Function)
	stack = Array(Avl{K, V}, 0)
	push(stack, nil(K, V))
	out = copy(n1)
	while notempty(small)
		while notempty(small)
			if notempty(small.child[LEFT])
				s_node = Node(small.key, small.value)
				s_node.child[RIGHT] = small.child[RIGHT]
				push(stack, s_node)
				small = small.child[LEFT]
			else 
				assign(out, small.key, small.value, cf)
				small = small.child[RIGHT]
			end
		end 
		small = pop(stack)
	end 
	out
end



# wait a minute... there must be a better way to do this?
function intersect_linear_non_destr{K, V}(n1 :: Avl{K, V}, n2 :: Avl{K, V}, cf :: Function)

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
	


# insert all items of small into big, return big
function intersect_nlogn_non_destr{K, V}(big :: Node{K, V}, small :: Node{K, V}, cf :: Function)
	stack = Array(Avl{K, V}, 0)
	push(stack, nil(K, V))
	out = copy(big)
	while notempty(small)
		while notempty(small)
			if notempty(small.child[LEFT])
				s_node = Node(small.key, small.value)
				s_node.child[RIGHT] = small.child[RIGHT]
				push(stack, s_node)
				small = small.child[LEFT]
			else 
				assign(out, small.key, small.value, cf)
				small = small.child[RIGHT]
			end
		end 
		small = pop(stack)
	end 
	out
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
 
