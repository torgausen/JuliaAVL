
require ("nodes.jl")
require ("debug.jl")

# is a vector sorted by function cf ?
function issorted{T}(a :: Vector{T}, cf :: Function)
	for i = 2 : length(a)
		if cf(a[i], a[i-1])
			return false
		end
	end
	return true
end

assert(issorted ([5.0, 4.0, 3.0, 2.0, 1.0], >))
assert(issorted ([5.0], isless))
assert(issorted ([], isless))

# Check three main properties of sortdict
function valid{K,V}(sd :: SortDict{K,V}) 
	va = valid_avl(sd.root)
	vc = valid_count(sd.root)
	vsd = valid_sort_dict(sd.root, sd.cf)
	return va[1] && vc[1] && vsd
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


# test build constructor
assert(valid(SortDict([4,3,2,1], [1.0, 2.0, 3.0, 4.0], >)))

function test_union()
end

# print out some trees, scroll up the terminal and see if they are valid
function test_valid()
	t = nil(Int,Float64)
	for i in 1:20
		f, c, t = assign(t, int(rand()*30)+1, rand(), cf)
		println("avl structure: $(valid_avl(t)[1])")
		println("correct count: $(valid_count(t)[1])")
		println("    valid set: $(valid_sort_dict(t, <))")
		draw(t, false, true, 128)
	end
	println(repeat("#", 128))

	while notempty(t)
		f, c, v, t = del(t, t.key)
		println("avl structure: $(valid_avl(t)[1])")
		println("correct count: $(valid_count(t)[1])")
		println("    valid set: $(valid_sort_dict(t, <))")
		draw(t, false, true, 128)
	end
end


function test_union()
	t = nil(Int,Float64)
	for i in 1:15
		f, c, t = assign(t, int(rand()*30)+1, rand(), isless)
	end
	draw(t, false, true, 128)

	println(repeat("#", 128))
	u = nil(Int,Float64)
	for i in 1:15
		f, c, u = assign(u, 100+int(rand()*30)+1, rand(), isless)
	end
	draw(u, false, true, 128)

	println(repeat("#", 128))
	v = union(t, u)
	println("avl structure: $(valid_avl(v)[1])")
	println("correct count: $(valid_count(v)[1])")
	println("    valid set: $(valid_sort_dict(v, <))")
	draw(v, false, true, 128)
end
function test_intersection()
	t = nil(Int,Float64)
	for i in 1:20
		f, c, t = assign(t, int(rand()*30)+1, rand(), isless)
	end
	draw(t, false, true, 128)

	println(repeat("#", 128))
	u = nil(Int,Float64)
	for i in 1:20
		f, c, u = assign(u, 10 + int(rand()*30)+1, rand(), isless)
	end
	draw(u, false, true, 128)

	println(repeat("#", 128))
	v = intersect(t, u)
	println("avl structure: $(valid_avl(v)[1])")
	println("correct count: $(valid_count(v)[1])")
	println("    valid set: $(valid_sort_dict(v, <))")
	draw(v, false, true, 128)
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
