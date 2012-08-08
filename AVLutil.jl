
require ("AVLbase.jl")
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

# returns f(x, y) if b is false, otherwise f(y, x)
turn (f :: Function, x, y, b :: Bool) = apply(f, ((x, y), (y, x)) [b + 1])


sshow{K, V}(io, nil :: Nil{K, V}) = "Avl{}"
function sshow{K, V}(io, node :: Node{K, V})
	flag = true
	str = "Avl{("
	for x in node
		if flag 
			str = strcat(str, string(x[KEY]), "=>", string(x[VALUE]), ")")
			flag = false
		else
			str = strcat(str, ", (", string(x[KEY]), "=>", string(x[VALUE]), ")")
		end
	end
	return strcat(str, "}")
end	

show{K, V}(x, node :: Avl{K, V}) = println(sshow(stdout_stream, node))




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
		node.count = count
		node.bal = [LEFT, BALANCED, RIGHT] [(hr - hl) + 2]
		return max(hl, hr) + 1, count, node
	end
	h, c, n = rec(1, length(ks))
	return n
end



# returns tuple of (array of keys, array of values)
# non destructive
flatten{K, V} (node :: Nil{K, V}) = (Array(K, 0), Array(V, 0))
function flatten{K, V} (node :: Node{K, V})
	len = node.count
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
		
		if isempty(node)
			node = pop(stack)
		end 
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
	return ((count == node.count) && true_l && true_r, count)
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
draw(node) = draw(node, false, true, 128)
draw(node, a, b) = draw(node, a, b, 128)


