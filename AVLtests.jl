# require ("AVLbase.jl")
# require ("AVLutil.jl")
# require ("AVLorder.jl")

# require("AVLbase.jl")
# require("AVLset_ops.jl") 
# require("AVLorder.jl")
# require("AVLiter.jl")
# require("AVLutil.jl")
require ("AVL.jl")

#import AVL.*

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
	sd = join!(sd1, sd2)
	assert(keys(sd) == [-10:22], "join broken")
	sd1, sd2 = split!(sd, -6)
	
	assert(keys(sd1) == [-10:-7], "split!, broken")
	assert(keys(sd2) == [-6:22], "split!, broken")
	
	sd = SortDict(['a', 'd', 'e'], [1:3]) 
	assert(valid(sd), "SortDict constructor broken")
	sd2 = copy(sd)
	assert(isequal(sd, sd2), "SOMETHING is wrong!")
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
	map!(uppercase, sd1)
	assert(!isequal(sd1, sd2), "isequal broken")
	map!(uppercase, sd2)
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
	(ks,vs) = flatten(sd.tree); assert(isequal(sd.tree, build(ks, vs), sd.cf), "build or flatten broken")
	b = Array(Any, 0)
	while ! isempty(sd)
		x = (del(sd, sd.tree.key))
		push(b, x[1])
		assert(valid(sd), "SortDict del broken")
	end
	b = sort(b)
	assert(isequal(a, b), "SortDict del broken")

	a = SortDict([3 : 11], [3//1 : 11//1])
	b = SortDict([-3 : 7], [-3//1 : 7//1])
	c = SortDict([0 : 99], [0//1 : 99//1])
	assert(isequal(union(a, b), SortDict([-3 : 11], [-3//1 : 11//1])), "SortDict union broken")
	assert(isequal(union(a, c), SortDict([0 : 99], [0//1 : 99//1])), "SortDict union broken")
	assert(isequal(intersect(a, b), SortDict([3 : 7], [3//1 : 7//1])), "SortDict intersect broken")
	assert(isequal(intersect(a, c), SortDict([3 : 11], [3//1 : 11//1])), "SortDict intersect broken")

	a = [1:20]; b = [1,4,6,8,9,10,12,14,15,16,18,20]; c = [2,3,5,7,11,13,17,19]
	sda = SortDict(a,a); sdb = SortDict(b,b); sdc = SortDict(c,c)
	assert (isequal(difference(sda, sdb), sdc), "SortDict difference broken")
	
	sd = SortDict([1,2,3,4], [1.0, 2.0, 3.0, 4.0])
	assert(sum(sd) == 10.0, "general iterator broken")
	
	println("Passed basic sanity tests. But remember, that doesn't mean a thing.")
end
run_tests()