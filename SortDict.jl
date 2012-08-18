
# TODO:
#
# work out system of exceptions
# learn and use macros to reduce code
# firstkv, lastkv argh
# more sanity tests, add performance tests
# add del_left(sd, n) or similar (drop several keys at once in log time
# refs with range and vector? problematic: semantic mix of keys and indexes
# ? isless(x, y)
# ? convert(type, x)
# ? reverse. possible but clumsy
# ? Memory-mapped I/O ?
# ? Parallel/Distributed trees?
# constructor that sorts?

#import AVL.*

module SORTDICT

import Base.*
export KEY, VALUE
export SortDict, copy, deeper_copy, isequal, keys, values, flatten
export isempty, length, numel, issorted
export show
export map, map!
export assign, has, get, get_kv, shift, del_first, del_first_kv, pop, del_last, del_last_kv, del, del_kv, del_all
export first, first_kv, last, last_kv, before, before_kv, after, after_kv, rank, select, select_kv
export isvalid
export union, intersect, difference, join!, split!, split_left!
export Goright, Goright_kv, Goleft, Goleft_kv

include("AVL.jl")
include("iter.jl")
include("order.jl")
include("util.jl")
include("set_ops.jl")
include("basics.jl")


SortDict{K, V}(ks :: Vector{K}, vs :: Vector{V}) = SortDict(ks, vs, isless)

SortDict(K :: Type, V :: Type) = SortDict{K, V} (nil(K, V), isless)

function SortDict{K, V} (ks :: Vector{K}, vs :: Vector{V}, cf :: Function)
	if ! issortedset(ks, cf)
		throw ("SortDict constructor: keys must form a sorted set")
	elseif length(ks) != length(vs)
		throw ("SortDict constructor: key vector and value vector must have same length")
	end
	tree = build(ks, vs)
	return SortDict(tree, cf)
end

function ks_vs(kvs :: Array{Tuple, 1})
	K = None
	V = None
	for (k, v) in kvs
		K = promote_type(K, typeof(k))
		V = promote_type(V, typeof(v))
	end
	len = length(kvs)
	ks = Array(K, len)
	vs = Array(V, len)
	i = 1
	for (k, v) in kvs
		ks[i] = k 
		vs[i] = v
		i += 1
	end
	(ks, vs)
end

SortDict (kvs :: Array{Tuple, 1}) = (((ks, vs) = ks_vs(kvs)); SortDict(ks, vs))
SortDict (kvs :: Array{Tuple, 1}, cf :: Function) = ((ks, vs) = KV(kvs); (SortDict(ks, vs), cf))

 
function SortDict (d :: Dict)
	SortDict(d, isless)
end

function SortDict (d :: Dict, cf :: Function)
	len = numel(d)
	kvs = Array(Tuple, len)
	i = 1
	for kv in d
		kvs[i] = kv
		i += 1
	end
	kvs = sort((a,b) -> (cf(a[1], b[1])), kvs)
	ks, vs = ks_vs(kvs)
	SortDict(ks, vs, cf)
end


eltype{K, V}(sd :: SortDict{K, V}) = (K, V)

isempty (sd :: SortDict) = isempty(sd.tree)

length{K, V}(sd :: SortDict{K, V}) = length(sd.tree)
numel{K, V}(sd :: SortDict{K, V}) = length(sd.tree)

#shallow copy
copy{K,V}(sd :: SortDict{K,V}) = SortDict(copy(sd.tree), sd.cf)

# deeper than shallow copy, but keys and values are just copies, not deep copies
deeper_copy{K, V}(sd :: SortDict{K,V}) = SortDict(deeper_copy(sd.tree), sd.cf)

# get tupple of two arrays: keys and values
flatten{K, V}(sd :: SortDict{K,V}) = flatten(sd.tree)

keys{K, V}(sd :: SortDict{K, V}) = flatten(sd)[KEY]

values{K, V}(sd :: SortDict{K, V}) = flatten(sd)[VALUE]

isequal{K,V}(sda :: SortDict{K, V}, sdb :: SortDict{K, V}) = (sda.cf == sdb.cf && isequal(sda.tree, sdb.tree, sda.cf))

del_all{K, V}(sd :: SortDict{K, V}) = (sd.tree = nil(K, V); sd)


# stolen from dict.jl ;)
function show{K, V}(io, sd::SortDict{K, V})
	if isempty(sd)
		print(io, "SortDict($K, $V)")
	else
	print(io, "{")
	fst = true
	for (k, v) in Goright_kv(sd.tree, first_kv(sd)[KEY], sd.cf)
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

function map!{K, V}(fn :: Function, sd :: SortDict{K, V})
	sd.tree = map!(fn, sd.tree)
	sd
end		

function map{K, V}(fn :: Function, sd :: SortDict{K, V})
	SortDict(map(fn, sd.tree), sd.cf)
end		

first{K, V} (sd :: SortDict{K, V}) = first(sd.tree)[VALUE]
 
first_kv{K, V} (sd :: SortDict{K, V}) = first(sd.tree)
 
last{K, V} (sd :: SortDict{K, V}) = last(sd.tree)[VALUE]

last_kv{K, V} (sd :: SortDict{K, V}) = last(sd.tree)

first_kv{K, V}(node :: Nil{K, V}, n :: Integer) = Array((K, V), 0)
function first_kv{K, V}(node :: Node{K, V}, n :: Integer)
	rtn = Array((K, V), n)
	i = 1
	for kv in node
		rtn[i] = kv
		i += 1
	end
	rtn
end

first{K, V}(node :: Nil{K, V}, n :: Integer) = Array(V, 0)
function first{K, V}(node :: Node{K, V}, n :: Integer)
	rtn = Array(V, n)
	i = 1
	for kv in node
		rtn[i] = kv[VALUE]
		i += 1
	end
	rtn
end

last_kv{K, V}(node :: Nil{K, V}, n :: Integer) = Array((K, V), 0)
function last_kv{K, V}(node :: Node{K, V}, n :: Integer)
	rtn = Array((K, V), n)
	i = node.length
	for kv in node
		rtn[i] = kv
		i -= 1
	end
	rtn
end

last{K, V}(node :: Nil{K, V}, n :: Integer) = Array(V, 0)
function last{K, V}(node :: Node{K, V}, n :: Integer)
	rtn = Array(V, n)
	i = node.length
	for kv in node
		rtn[i] = kv[VALUE]
		i -= 1
	end
	rtn
end



# Check three main properties of sortdict
function isvalid{K,V}(sd :: SortDict{K,V}) 
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

function del_first_kv{K, V} (sd :: SortDict{K, V})
	if length(sd.tree) == 0
		throw("Cannot shift empty SortDict")
	end
	f, c, out, sd.tree = del_first(sd.tree)
	out
end
del_first{K, V} (sd :: SortDict{K, V}) = del_first_kv[VALUE]
shift{K, V} (sd :: SortDict{K, V}) = del_first(sd)

function del_last_kv{K, V} (sd :: SortDict{K, V}) 
	if length(sd.tree) == 0
		throw("Cannot pop empty SortDict")
	end
	f, c, out, sd.tree = del_last(sd.tree)
	out
end
del_last{K, V} (sd :: SortDict{K, V}) = del_last_kv[VALUE]
pop{K, V}(sd :: SortDict{K, V}) = del_last(sd)

function del_kv{K, V} (sd :: SortDict{K, V}, key :: K)
	f, c, out, sd.tree = del(sd.tree, key, sd.cf)
	out
end
del{K, V} (sd :: SortDict{K, V}, key :: K) = del_kv(sd, key)[VALUE]

function del_kv{K, V} (sd :: SortDict{K, V}, key :: K, default)
	f, c, out, sd.tree = del(sd.tree, key, default, sd.cf)
	out
end
del{K, V} (sd :: SortDict{K, V}, key :: K, default) = del_kv(sd, key, default)[VALUE]

has{K, V} (sd :: SortDict{K, V}, key :: K) = has(sd.tree, key, sd.cf)
contains{K, V} (sd :: SortDict{K, V}, key :: K) = has(sd.tree, key, sd.cf)

get{K, V} (sd :: SortDict{K, V}, key :: K, default :: V) = get_kv(sd.tree, key, default, sd.cf)[VALUE]

get_kv{K, V} (sd :: SortDict{K, V}, key :: K, default :: V) = get_kv(sd.tree, key, default, sd.cf)

range_kv{K, V} (sd :: SortDict{K, V}, key1 :: K, key2 :: K) = range(sd.tree, key1, key2, sd.cf)

rank{K, V} (sd :: SortDict{K, V}, key :: K) = rank(sd.tree, key, sd.cf) + 1

select_kv{K, V} (sd :: SortDict{K, V}, ind :: Int) = select(sd.tree, ind - 1)

select{K, V} (sd :: SortDict{K, V}, ind :: Int) = select(sd.tree, ind - 1)[VALUE]

# keyselect (range) 3 variants: upto k, between k1, k2, from k, but these can be accessed with refs

before_kv{K, V} (sd :: SortDict{K, V}, key :: K) = before(sd.tree, key, sd.cf)
before{K, V} (sd :: SortDict{K, V}, key :: K) = before(sd.tree, key, sd.cf)[VALUE]

after_kv{K, V} (sd :: SortDict{K, V}, key :: K) = after(sd.tree, key, sd.cf)
before{K, V} (sd :: SortDict{K, V}, key :: K) = before(sd.tree, key, sd.cf)[VALUE]

function split!{K, V} (sd :: SortDict{K, V}, key :: K) 
	sd.tree, t2, mid = tsplit(sd.tree, key, sd.cf)
	if mid != nothing
		# what to do with that extra element? I'll just insert it in t2 for now
		f, c, t2 = assign(t2, mid[KEY], mid[VALUE], sd.cf)
	end
	return SortDict(t2, sd.cf)
end

function split_left!{K, V} (sd :: SortDict{K, V}, key :: K) 
	t2, sd.tree, mid = tsplit(sd.tree, key, sd.cf)
	if mid != nothing
		# what to do with that extra element? I'll just insert it in t2 for now
		f, c, t2 = assign(t2, mid[KEY], mid[VALUE], sd.cf)
	end
	return SortDict(t2, sd.cf)
end


# all of sd1's keys must be less than all of sd2's keys
# note: destructive to the tree with the 'highest' values (when using isless as compare function)
function join!{K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V}) 
	cf = sd1.cf
	if cf != sd2.cf
		throw ("join!: SortDicts must have the same compare functions")
	elseif isempty(sd1)
		sd1.tree = sd2.tree 
		del_all(sd2)
		return sd1
	elseif isempty(sd2)
		return sd1
	elseif cf(first_kv(sd2), last_kv(sd1))
		throw ("join!: SortDicts not ordered by compare function")
	end
	if !cf(last_kv(sd1), first_kv(sd2))
	     throw ("join!: keys must not overlap")
	end
	key = del_first_kv(sd2)
	sd1.tree = tjoin(sd1.tree, key, sd2.tree)
	del_all(sd2)
	return sd1
end

function union{K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V})
	if sd1.cf != sd2.cf 
		throw ("union: non-identical compare functions")
	end
	SortDict(union_linear(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
end



function intersect {K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V}) 
	if sd1.cf != sd2.cf 
		throw ("intersect: non-identical compare functions")
	end
	SortDict(intersect_linear(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
end


function difference {K, V} (sd1 :: SortDict{K, V}, sd2 :: SortDict{K, V}) 
	SortDict(diff_linear(sd1.tree, sd2.tree, sd1.cf), sd1.cf)
end


end # module







