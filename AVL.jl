
# TODO:
# work out system of exceptions
# more sanity tests, add performance tests to find good values for algorithm choice
# set difference, symmetric difference
# refs with range and vector?
# improve union to use intelligent split + merge intersection + join. 
# more constructors! Harder than it should be. 
# floor, ceil (to work on ranks, not keys), (but one can just use select and before/after)
# * isless(x, y)
# ? convert(type, x)
# * probably should have WeakKeySort
# * add(collection, key) ... hmmmm
# * choose(s) ...hmmmmmmmmm just use shift?
# ? reverse. possible but clumsy
# ? Memory-mapped I/O ?
# ? Parallel/Distributed trees?


#module AVL
	
#import Base.*
		
require("AVLbase.jl")
require("AVLutil.jl")
require("AVLset_ops.jl") 

#export SortDict
#export isempty, length, show
#export assign, has, get, shift, pop, del
#export first, last, before, after, rank, select
#export valid
#export union, intersect#, join, split

abstract Associative{K, V}


type SortDict{K, V} <: Associative{K, V}
	tree :: Avl{K, V}
	cf :: Function # compare function
end

SortDict() = SortDict(nil(Any,Any), isless)
SortDict{K, V}(ks :: Vector{K}, vs :: Vector{V}) = SortDict(ks, vs, isless)
SortDict(K :: Type, V :: Type) = SortDict{K, V} (nil(K, V), isless)

function SortDict{K, V} (ks :: Vector{K}, vs :: Vector{V}, cf :: Function)
	if ! issorted(ks, cf)
		throw ("SortDict constructor: keys must be sorted by function $cf")
	elseif length(ks) != length(vs)
		throw ("SortDict constructor: key vector and value vector must have same length")
	end
	tree = build(ks, vs)
	return SortDict(tree, cf)
end

eltype{K, V}(sd :: SortDict{K, V}) = (K, V)

isempty (sd :: SortDict) = isempty(sd.tree)

length{K, V}(sd :: SortDict{K, V}) = length(sd.tree)
numel{K, V}(sd :: SortDict{K, V}) = length(sd.tree)

#shallow copy
copy{K,V}(sd :: SortDict{K,V}) = SortDict(copy(sd.tree), sd.cf)

# deeper than shallow copy, but keys and values are just copies, not deep copies
deeper_copy{K,V}(sd :: SortDict{K,V}) = SortDict(deeper_copy(sd.tree), sd.cf)

=={K,V}(sda :: SortDict{K, V}, sdb :: SortDict{K, V}) = (sda.cf == sdb.cf) && (sda.tree == sdb.tree) 
isequal{K,V}(sda :: SortDict{K, V}, sdb :: SortDict{K, V}) = (sda == sdb)


del_all{K, V}(sd :: SortDict{K, V}) = (sd.tree = nil(K, V); sd)


function start_left{K, V} (node :: Avl{K, V}, key :: K, cf :: Function) 
 	stack = Array(Node{K, V}, 0)
	while notempty(node)
		if cf(key, node.key)
			node = node.child[LEFT]
		elseif cf(node.key, key)
			push(stack, node)
			node = node.child[RIGHT]
		else
			push(stack, node)
			break
		end
	end
	return stack
end

function start_right{K, V} (node :: Avl{K, V}, key :: K, cf :: Function) 
 	stack = Array(Node{K, V}, 0)
	while notempty(node)
		if cf(key, node.key)
			push(stack, node)
			node = node.child[LEFT]
		elseif cf(node.key, key)
			node = node.child[RIGHT]
		else
			push(stack, node)
			break
		end
	end
	return stack
end


function next_left{K, V} (node :: Avl{K, V}, stack :: Array{Node{K, V}, 1})
	node = pop(stack)
	elem = (node.key, node.value)
	node = node.child[LEFT]
	if notempty(node)
		push(stack, node) 
		node = node.child[RIGHT]
		while notempty(node) 
			push(stack, node)
			node = node.child[RIGHT]
		end
	end
	elem, stack
end

function next_right{K, V} (node :: Avl{K, V}, stack :: Array{Node{K, V}, 1})
	node = pop(stack)
	elem = (node.key, node.value)
	node = node.child[RIGHT]
	if notempty(node)
		push(stack, node) # go one step right
		node = node.child[LEFT]
		while notempty(node) # and then all the way left
			push(stack, node)
			node = node.child[LEFT]
		end
	end
	elem, stack
end

type Goright{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

Goright{K, V}(sd :: SortDict{K, V}) = Goright(sd.tree, first(sd)[KEY], sd.cf)
Goright{K, V}(sd :: SortDict{K, V}, key :: K) = Goright(sd.tree, key, sd.cf)

type Gorightkv{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

Gorightkv{K, V}(sd :: SortDict{K, V}) = Gorightkv(sd.tree, first(sd)[KEY], sd.cf)
Gorightkv{K, V}(sd :: SortDict{K, V}, key :: K) = Gorightkv(sd.tree, key, sd.cf)

type Goleft{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

Goleft{K, V}(sd :: SortDict{K, V}) = Goleft(sd.tree, last(sd)[KEY], sd.cf)
Goleft{K, V}(sd :: SortDict{K, V}, key :: K) = Goleft(sd.tree, key, sd.cf)

type Goleftkv{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

Goleftkv{K, V}(sd :: SortDict{K, V}) = Goleftkv(sd.tree, last(sd)[KEY], sd.cf)
Goleftkv{K, V}(sd :: SortDict{K, V}, key :: K) = Goleftkv(sd.tree, key, sd.cf)

start{K, V} (iter :: SortDict{K, V}) = start_right(iter.tree, first(iter)[KEY], iter.cf)

start{K, V} (iter :: Goleft{K, V}) = start_left(iter.node, iter.key, iter.cf)
start{K, V} (iter :: Goright{K, V}) = start_right(iter.node, iter.key, iter.cf)

start{K, V} (iter :: Goleftkv{K, V}) = start_left(iter.node, iter.key, iter.cf)
start{K, V} (iter :: Gorightkv{K, V}) = start_right(iter.node, iter.key, iter.cf)

next{K, V} (iter :: SortDict{K, V}, stack :: Array{Node{K, V}, 1}) = ((elem, stack) = next_right(iter.tree, stack); (elem[KEY], stack))

next{K, V} (iter :: Goleft{K, V}, stack :: Array{Node{K, V}, 1}) = ((elem, stack) = next_left(iter.node, stack); (elem[KEY], stack))
next{K, V} (iter :: Goright{K, V}, stack :: Array{Node{K, V}, 1}) = ((elem, stack) = next_right(iter.node, stack); (elem[KEY], stack))

next{K, V} (iter :: Goleftkv{K, V}, stack :: Array{Node{K, V}, 1}) = ((elem, stack) = next_left(iter.node, stack); (elem, stack))
next{K, V} (iter :: Gorightkv{K, V}, stack :: Array{Node{K, V}, 1}) = ((elem, stack) = next_right(iter.node, stack); (elem, stack))

done{K, V} (iter :: SortDict{K, V}, stack :: Array{Node{K, V}, 1}) = isempty(stack)

done{K, V} (iter :: Goleft{K, V}, stack :: Array{Node{K, V}, 1}) = isempty(stack)
done{K, V} (iter :: Goright{K, V}, stack :: Array{Node{K, V}, 1}) = isempty(stack)

done{K, V} (iter :: Goleftkv{K, V}, stack :: Array{Node{K, V}, 1}) = isempty(stack)
done{K, V} (iter :: Gorightkv{K, V}, stack :: Array{Node{K, V}, 1}) = isempty(stack)


# stolen from dict.jl ;)
function show{K, V}(io, sd::SortDict{K, V})
	if isempty(sd)
		print(io, "SortDict($K, $V)")
	else
	print(io, "{")
	fst = true
	for (k, v) in Gorightkv(sd.tree, first(sd)[KEY], sd.cf)
		fst || print(io, ',')
		fst = false
		show(io, k)
		print(io, "=>")
		show(io, v)
	end
	print(io, "}")
	end
end

issorted(sd :: SortDict) = true

function map{K, V}(f :: Function, sd :: SortDict{K, V})
	sd.tree = map(f, sd.tree)
	sd
end		

function keys{K, V}(sd :: SortDict{K, V})
	ks = Array(K, length(sd))
	i = 1
	for k in sd
		ks[i] = k
		i += 1
	end
	ks
end

function values{K, V}(sd :: SortDict{K, V})
	vs = Array(K, length(sd))
	i = 1
	for kv in Gorightkv(sd)
		vs[i] = kv[VALUE]
		i += 1
	end
	vs
end

function split{K, V} (sd :: SortDict{K, V}, key :: K) 
	t1, t2, mid = tsplit(sd.tree, key, sd.cf)
	if mid != nothing
		# what to do with that extra element? I'll just insert it in t2 for now
		f, c, t2 = assign(t2, mid[KEY], mid[VALUE], sd.cf)
	end
	return SortDict(t1, sd.cf), SortDict(t2, sd.cf)
end


# all of sd1's keys must be less than all of sd2's keys
# note: destructive to the tree with the 'highest' values (when using isless as compare function)
function join{K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V}) 
	cf = sd1.cf
	if cf != sd2.cf
		throw ("SortDicts to be joined must have the same compare functions")
	elseif isempty(sd1)# 
		return sd2 #
	elseif isempty(sd2)# oh, well
		return sd1 #
	elseif cf(first(sd2), last(sd1))
		sd1, sd2 = sd2, sd1
	end
	if !cf(last(sd1), first(sd2))
	     throw ("join: keys must not overlap")
	end
	key = shift(sd2)
	node = tjoin(sd1.tree, key, sd2.tree)
	del_all(sd2) # hopefully this is less confusing than keeping sd2 with one node missing
	return SortDict(node, cf)
end

first{K, V} (sd :: SortDict{K, V}) = first(sd.tree)
 
last{K, V} (sd :: SortDict{K, V}) = last(sd.tree)

length{K, V}(sd :: SortDict{K, V}) = length(sd.tree)

# Check three main properties of sortdict
function valid{K,V}(sd :: SortDict{K,V}) 
	v_avl = valid_avl(sd.tree)[1]
	v_count = valid_count(sd.tree)[1]
	v_set = valid_sort(sd.tree, sd.cf)
	return v_avl && v_count && v_set
end

function ref{K, V}(sd :: SortDict{K, V}, key :: K)
	ref(sd.tree, key, sd.cf)
end 

# returns an array
function ref{K, V} (sd :: SortDict{K, V}, ind :: Range1{K}) 
	range(sd.tree, first(ind), last(ind), sd.cf)
end 

# function ref{K, V} (sd :: SortDict{K, V}, ind :: Range{K}) 
# 	println(ind)
# 	#range(sd.tree, first(ind), last(ind), sd.cf)
# end 

# ref{K, V} (sd :: SortDict, ind :: Vector{K}) 


function assign{K, V}(sd :: SortDict{K, V}, value :: V, key :: K) 
	h, c, sd.tree = assign(sd.tree, key, value, sd.cf)
end

function shift{K, V} (sd :: SortDict{K, V})
	if length(sd.tree) == 0
		throw("Cannot shift empty SortDict")
	end
	f, c, out, sd.tree = del_first(sd.tree)
	out
end

function pop{K, V} (sd :: SortDict{K, V}) 
	if length(sd.tree) == 0
		throw("Cannot pop empty SortDict")
	end
	f, c, out, sd.tree = del_last(sd.tree)
	out
end

function del_extreme{K, V} (sd :: SortDict{K, V}, side :: Bool) 
	if length(sd.tree) == 0
		throw("Cannot delete from empty SortDict")
	end
	f, c, out, sd.tree = del_ultra(sd.tree, side + 1)
	out
end


function del{K, V} (sd :: SortDict{K, V}, key :: K)
	f, c, out, sd.tree = del(sd.tree, key, sd.cf)
	out
end

has{K, V} (sd :: SortDict{K, V}, key :: K) = has(sd.tree, key, sd.cf)

get{K, V} (sd :: SortDict{K, V}, key :: K, default :: V) = get(sd.tree, key, default, sd.cf)

rank{K, V} (sd :: SortDict{K, V}, key :: K) = rank(sd.tree, key, sd.cf) + 1

select{K, V} (sd :: SortDict{K, V}, ind :: Int) = select(sd.tree, ind - 1)

# keyselect (range) 3 variants: upto k, between k1, k2, from k, but these can be accessed with refs

before{K, V} (sd :: SortDict{K, V}, key :: K) = before(sd.tree, key, sd.cf)

after{K, V} (sd :: SortDict{K, V}, key :: K) = after(sd.tree, key, sd.cf)




const UNION_RATIO = 1.0
function union {K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V})
	if sd1.cf != sd2.cf 
		throw ("AVL union: no union with non-identical compare functions")
	end
	if length(sd1) < length(sd2)
		sd1, sd2 = sd2, sd1
	end
	n = length(sd1)
	m = length(sd2)
	if UNION_RATIO * n < m * log2(n)
#		println("union linear")
		SortDict(union_linear(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
	else
#		println("union mlogn")
		SortDict(union_mlogn(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
	end
end
 
const INTERSECT_RATIO = 1.0
function intersect {K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V}) 
	if sd1.cf != sd2.cf 
		throw ("AVL union: intersect with non-identical compare functions")
	end
	if length(sd1) < length(sd2)
		sd1, sd2 = sd2, sd1
	end
	
	n = length(sd1)
	m = length(sd2)

	if INTERSECT_RATIO * n < m * log2(n)
#		println("intersect linear")
		SortDict(intersect_linear(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
	else
#		println("intersect mlogn")
		SortDict(intersect_mlogn(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
	end
end




#end # module



# TEST CODE
#import AVL.*


# add tests: iterators, join, split

function run_tests()	# very basic sanity tests

	sd = SortDict(Int, Float64)

	assert(length(sd) == 0, "SortDict length broken")
	sd[1] = 1.1
	assert((sd[1]) == 1.1, "SortDict ref broken")
	assert(length(sd) == 1, "SortDict length broken")
	assert(get(sd, 1, 99.99) == 1.1, "SortDict get broken")
	assert(get(sd, 33, 99.99) == 99.99, "SortDict get broken")
	assert(has(sd, 1), "SortDict has broken")
	assert(!has(sd, 111), "SortDict has broken")
	del_all(sd)
	assert(length(sd) == 0, "SortDict length broken")
	assert(isa(sd.tree, Nil), "SortDict length broken")
	
	a = [-10 : 10]
	b = [11 : 22] 
	sd1 = SortDict(a, 1/a)
	sd2 = SortDict(b, 1/b)
	sd = join(sd1, sd2)
	assert(keys(sd) == [-10:22], "join broken")
	sd1, sd2 = split(sd, -6)
	
	assert(keys(sd1) == [-10:-7], "split, broken")
	assert(keys(sd2) == [-6:22], "split, broken")
	
	sd = SortDict(['a', 'd', 'e'], [1:3]) 
	assert(valid(sd), "SortDict constructor broken")
	sd2 = copy(sd)
	assert(sd == sd2)
	sd2['d'] = 9
	assert(sd['d'] != sd2['d'], "SortDict copy broken")
	sd = SortDict([-10 : 10], [-10 : 10] +1)
	assert(first(sd) == (-10, -9))
	assert(last(sd) == (10, 11))
	
	sd = SortDict([5 : 10], [5.0:10.0])
	assert(keys(sd) == [5:10], "keys() broken")
	assert(values(sd) == [5.0 : 10.0], "values() broken")
	
	arr = {}
	for x in sd
		push(arr, x)
	end
	assert (arr == [5.0:10.0], "general SortDict iterator broken")
	
	arr = {}
	for x in Goleft(sd, 7)
		push(arr, x)
	end
	assert (arr == [7.0, 6.0, 5.0], "Goleft iterator broken")
	
	arr = {}
	for x in Gorightkv(sd, 7)
		push(arr, x)
	end
	assert (arr == [(7,7.0), (8,8.0), (9,9.0), (10, 10.0)], "Gorightkv iterator broken")

	sd = map(-,sd)
	assert(values(sd) == -[5.0:10.0], "map broken")
	
	sd1 = SortDict([1:26], ['a':'z'])
	sd2 = SortDict([1:26], ['a':'z'])
	assert(isequal(sd1, sd2), "isequal broken")
	map(uppercase, sd1)
	assert(!isequal(sd1, sd2), "isequal broken")
	map(uppercase, sd2)
	assert(isequal(sd1, sd2), "isequal broken")
	
	sd = SortDict([5 : 10], [5.0:10.0])
	
	assert(rank(sd, 6) == 2, "rank broken")
	assert(select(sd, 3) == (7,7.0), "select broken")
	assert(after(sd, 7) == (8, 8.0), "after broken")
	assert(after(sd, -77) == (5, 5.0), "after broken")
	assert(before(sd, 7) == (6, 6.0), "before broken")
	assert(before(sd, 77) == (10, 10.0), "before broken")

	a = sort(rand(150))
	sd = SortDict(a, a+1)
	(ks,vs) = flatten(sd.tree); assert(sd.tree == build(ks, vs), "build or flatten broken")
	b = Array(Any, 0)
	while ! isempty(sd)
		x = (del(sd, sd.tree.key))
		push(b, x[1])
		assert(valid(sd), "SortDict del broken")
	end
	b = sort(b)
	assert(a == b, "SortDict del broken")

	a = SortDict([3 : 11], [3//1 : 11//1])
	b = SortDict([-3 : 7], [-3//1 : 7//1])
	c = SortDict([0 : 99], [0//1 : 99//1])
	assert(union(a, b) == SortDict([-3 : 11], [-3//1 : 11//1]), "SortDict union broken")
	assert(union(a, c) == SortDict([0 : 99], [0//1 : 99//1]), "SortDict union broken")
	assert(intersect(a, b) == SortDict([3 : 7], [3//1 : 7//1]), "SortDict intersect broken")
	assert(intersect(a, c) == SortDict([3 : 11], [3//1 : 11//1]), "SortDict intersect broken")
	println("Passed basic sanity tests. But remember, that doesn't mean a thing.")
end
run_tests()




