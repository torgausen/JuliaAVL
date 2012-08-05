# TODO:
# fix printing, use sshow
# fix sd interator
# fix set ops! add nlogn intersect, add sanity tests, add performance tests to find good values for algorithm choice
# add arbitrary iterators Forward(node), Backward(node), Forward(node, key), Backward(node, key)
# Forward(key) and Backward(key) iterator constructors 
# sd[a:b] doesn't work yet
# set difference, (use '-' ?), 


module AVL
	
import Base.*
		
require ("AVLbase.jl")
require("AVLutil.jl")
require("AVLset_ops.jl") # stupid set ops don't work yet


export SortDict, valid, isempty, length, show, assign, first, last, shift, pop, del, has, get, del_extreme, LEFT, RIGHT
export before, after, rank, select
export union, intersect

abstract Associative{K, V}

type SortDict{K, V} <: Associative{K, V}
	tree :: Avl{K, V}
	cf :: Function # compare function
end

SortDict(K, V) = SortDict{K, V} (nil(K, V), isless)

SortDict{K,V}(ks :: Vector{K}, vs :: Vector{V}) = SortDict(ks, vs, isless)

isempty (sd :: SortDict) = isempty(sd.tree)

length{K, V}(sd :: SortDict{K, V}) = length(sd.tree)

copy{K,V}(sd :: SortDict{K,V}) = SortDict(copy(sd.tree), sd.cf)

=={K,V}(sda :: SortDict{K, V}, sdb :: SortDict{K, V}) = (sda.cf == sdb.cf) && (sda.tree == sdb.tree) 

del_all{K, V}(sd :: SortDict{K, V}) = (sd.tree = nil(K, V); sd)

function show{K, V}(sd :: SortDict{K, V}) 
	println("compare function: $(string(sd.cf))")
	show(sd.tree)
end	

issorted(sd :: SortDict) = true

first{K, V} (sd :: SortDict{K, V}) = first(sd.tree)
 
last{K, V} (sd :: SortDict{K, V}) = last(sd.tree)

length{K, V}(sd :: SortDict{K, V}) = length(sd.tree)

# Check three main properties of sortdict
function valid{K,V}(sd :: SortDict{K,V}) 
	v_avl = valid_avl(sd.tree)[1]
	v_count = valid_count(sd.tree)[1]
	v_set = valid_sort_dict(sd.tree, sd.cf)
	return v_avl && v_count && v_set
end

function SortDict{K, V} (ks :: Vector{K}, vs :: Vector{V}, cf :: Function)
	if ! issorted(ks, cf)
		throw ("SortDict constructor: keys must be sorted by function $cf")
	elseif length(ks) != length(vs)
		throw ("SortDict constructor: key vector and value vector must have same length")
	end
	tree = build(ks, vs)
	return SortDict(tree, cf)
end


function ref{K, V}(sd :: SortDict{K, V}, key :: K)
	ref(sd.tree, key, sd.cf)
end 

function ref{K, V} (sd :: SortDict{K, V}, ind :: Range1{K}) 
	#println(first(ind), " ", last(ind))
	range(sd.tree, first(ind), last(ind), sd.cf)
end 

function ref{K, V} (sd :: SortDict{K, V}, ind :: Range{K}) 
	println(ind)
	#range(sd.tree, first(ind), last(ind), sd.cf)
end 


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
	f, c, out, sd.tree = del_extreme(sd.tree, side + 1)
	out
end


function del{K, V} (sd :: SortDict{K, V}, key :: K)
	f, c, out, sd.tree = del(sd.tree, key, sd.cf)
	out
end

has{K, V} (sd :: SortDict{K, V}, key :: K) = has(sd.tree, key, sd.cf)

get{K, V} (sd :: SortDict{K, V}, key :: K) = get(sd.tree, key, sd.cf)

rank{K, V} (sd :: SortDict{K, V}, key :: K) = rank(sd.tree, key, sd.cf)

select{K, V} (sd :: SortDict{K, V}, ind :: Int) = select(sd.tree, ind)

# keyselect (range) 3 variants: upto k, between k1, k2, from k, but these can be accessed with refs
#
before{K, V} (sd :: SortDict{K, V}, key :: K) = before(sd.tree, key, sd.cf)

after{K, V} (sd :: SortDict{K, V}, key :: K) = after(sd.tree, key, sd.cf)

# keys
#
# values
#
# nodeIterator standard iterator?
#
# keyIter
#
# valueIter
#

function union {K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V})
	if sd1.cf != sd2.cf 
		throw ("AVL union: no union with non-identical compare functions")
	end
	SortDict(union(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
end
 
function intersect {K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V}) 
	if sd1.cf != sd2.cf 
		throw ("AVL union: intersect with non-identical compare functions")
	end
	SortDict(intersect(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
end
 
# difference {K, V} (sd :: SortDict, ?) 
#################################################################################################

end


# TEST CODE
import AVL.*
function run_tests()
	sd = SortDict(Int, Float64)

	# very basic sanity
	assert(length(sd) == 0, "SortDict length broken")
	sd[1] = 1.1
	assert((sd[1]) == 1.1, "SortDict ref broken")
	assert(length(sd) == 1, "SortDict length broken")
	assert(get(sd, 1) == (1, 1.1), "SortDict get broken")
	assert(has(sd, 1), "SortDict get broken")
	del_all(sd)
	assert(length(sd) == 0, "SortDict length broken")
	sd = SortDict(['a', 'd', 'e'], [1:3]) 
	assert(valid(sd), "SortDict constructor broken")
	sd2 = copy(sd)
	assert(sd == sd2)
	sd2['d'] = 9
	assert(sd['d'] != sd2['d'], "SortDict copy broken")
	sd = SortDict([-10 : 10], [-10 : 10] +1)
	assert(first(sd) == (-10, -9))
	assert(last(sd) == (10, 11))

	a = sort(rand(150))
	sd = SortDict(a, a+1) 
	b = Array(Any, 0)
	while ! isempty(sd)
		x = (del(sd, sd.tree.key))
		push(b, x[1])
		assert(valid(sd), "SortDict del broken")
	end
	b = sort(b)
	assert(a == b, "SortDict del broken")
end
run_tests()





