
require ("AVLorder.jl")

# is a vector sorted by function cf ?
function issorted{T}(a :: Vector{T}, cf :: Function)
	for i = 2 : length(a)
		if cf(a[i], a[i-1])
			return false
		end
	end
	return true
end

# 
# assert(issorted ([5.0, 4.0, 3.0, 2.0, 1.0], >))
# assert(issorted ([5.0], isless))
# assert(issorted ([], isless))


# The keys must be sorted. For a set, the keys must also be unique
function build{K, V}(ks :: Vector{K}, vs :: Vector{V})
	function rec(fst, lst)
		len = (lst - fst) + 1
		if len <= 0
			return 0, 0, Nil{K, V}()
		end
		mid = fst + ifloor(len / 2) 
		node = Node(ks[mid], vs[mid])
		hl, cl, node.child[LEFT] = rec(fst, mid - 1)
		hr, cr, node.child[RIGHT] = rec(mid + 1, lst)
		count = cl + cr + 1
		node.counter = count
		node.bal = [LEFT, BALANCED, RIGHT] [(hr - hl) + 2]
		return max(hl, hr) + 1, count, node
	end
	h, c, n = rec(1, length(ks))
	return n
end



# returns tuple of (sorted array of keys, corresponding values)
function flatten{K, V} (node :: Avl{K, V})
	ks = Array(K, 0)
	vs = Array(V, 0)
	stack = Array(Avl{K, V}, 0)
	push(stack, nil(K, V))
	while notempty(node)
		while notempty(node)
			if notempty(node.child[LEFT])
				s_node = Node(node.key, node.value)
				s_node.child[RIGHT] = node.child[RIGHT]
				push(stack, s_node)
				node = node.child[LEFT]
			else 
				push(ks, node.key)
				push(vs, node.value)
				node = node.child[RIGHT]
			end
		end 
		node = pop(stack)
	end 
	return (ks, vs)
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
	return ((count == node.counter) && true_l && true_r, count)
end

# is node a sort_dict, that is, do the keys form a set, and are they sorted?
valid_sort_dict{K, V}(node :: Nil{K, V}, cf :: Function) = true
function valid_sort_dict{K, V}(node :: Node{K, V}, cf :: Function)
	prev = first(node)
	flag = true
	for kv in node
		if flag then
			flag = false
			continue # skip first iteration
		end
		if ! cf(prev[1], kv[1])
			return false
		end
		prev = kv
	end
	return true
end
# 
# # is node a multi-set sorted tree?
# valid_multi_sort_dict{K, V}(node :: Nil{K, V}, cf :: Function) = true
# function valid_multi_sort_dict{K, V}(node :: Node{K, V}, cf :: Function)
# 	prev = first(node)
# 	flag = true
# 	for kv in node
# 		if flag then
# 			flag = false
# 			continue
# 		end
# 		if cf(kv[1], prev[1])
# 			return false
# 		end
# 		prev = kv
# 	end
# 	return true
# end
# 



######################################################################
# WHY MUST I DO THIS:
copy{K, V}(node :: Nil{K, V}) = node 
function copy{K, V}(node :: Node{K, V}) 
	out = Node(node.key, node.value)
	out.child[LEFT]  = copy(node.child[LEFT])
	out.child[RIGHT] = copy(node.child[RIGHT])
	out.counter = node.counter
	out.bal = node.bal
	out
end

# INSTEAD OF SIMPLY THIS?
# copy{K,V}(node :: Nil{K, V}) = node
# function copy{K,V}(node :: Node{K, V})  
# 	Node([copy(node.child[LEFT]), copy(node.child[RIGHT])],
# 	node.key, node.value, node.counter, node.bal)
# end
######################################################################3



# returns tuple of (sorted array of keys, corresponding values)
# works on multisets
function merge{K, V} (n1 :: Avl{K, V}, n2 :: Avl{K, V}, cf :: Function)
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
	return (ks, vs)
end



# same as union but O(m log n) instead of O(n + m)
function assign_all{K, V} (n1 :: Avl{K, V}, n2 :: Avl{K, V}, cf :: Function)
	stack = Array(Avl{K, V}, 0)
	push(stack, nil(K, V))
	while notempty(n2)
		while notempty(n2)
			if notempty(n2.child[LEFT])
				s_node = Node(n2.key, n2.value)
				s_node.child[RIGHT] = n2.child[RIGHT]
				push(stack, s_node)
				n2 = n2.child[LEFT]
			else 
				assign(n1, n2.key, n2.value, cf)
				n2 = n2.child[RIGHT]
			end
		end 
		n2 = pop(stack)
	end 
	n1
end









# call this on a tree to display it's structure
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
			plot_text(strcat(n.counter), x, yp)
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
	for i = 1:30
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
