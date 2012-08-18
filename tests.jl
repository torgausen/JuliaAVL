# todo: tests for:
#
# copy, deeper_copy
# 
# map, map!
# has, get,  del
# first, last, before, after,

# union, intersect, difference, join!, split!
# Goright, Gorightkv, Goleft, Goleftkv


include ("SortDict.jl")

import SORTDICT.*

function simple_tests()	# very basic sanity tests

	sd = SortDict(Int, Float64)

	assert(length(sd) == 0, "SortDict length broken")
	sd[1] = 1.1
	assert(sd[1] == 1.1, "SortDict ref broken")
	assert(length(sd) == 1, "SortDict length broken")
	assert(get(sd, 1, 99.99) == 1.1, "SortDict get broken")
	assert(get(sd, 33, 99.99) == 99.99, "SortDict get broken")
	assert(has(sd, 1), "SortDict has broken")
	assert(!has(sd, 111), "SortDict has broken")
	del_all(sd)
	assert(length(sd) == 0, "SortDict length broken")
	
	a = [-10 : 10]
	b = [11 : 22] 
	sd1 = SortDict(a, 1/a)
	sd2 = SortDict(b, 1/b)
	sd = join!(sd1, sd2)
	assert(keys(sd) == [-10:22], "join broken")
	sd2 = split!(sd, -6)
	
	assert(keys(sd) == [-10:-7], "split!, broken")
	#assert(keys(sd2) == [-6:22], "split!, broken")
	
	sd = SortDict(['a', 'd', 'e'], [1:3]) 
	assert(isvalid(sd), "SortDict constructor broken")
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

	a = sort(rand(50))
	sd = SortDict(a, a+1)
	(ks, vs) = flatten(sd.tree); assert(isequal(sd, SortDict(ks, vs)), "build or flatten broken")
	b = Array(Any, 0)
	while ! isempty(sd)
		x = (del(sd, sd.tree.key))
		push(b, x[1])
		assert(isvalid(sd), "SortDict del broken")
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
	assert(isequal(union(a, b), SortDict([-3 : 11], [-3//1 : 11//1])), "SortDict union broken")
	assert(isequal(union(a, b), SortDict([-3 : 11], [-3//1 : 11//1])), "SortDict union broken")
	
	del_all(a)
	assert(isequal(union(a, b), b), "SortDict union broken")
	assert(isequal(union(c, a), c), "SortDict union broken")
	assert(isequal(intersect(a, b), a), "SortDict intersect broken")
	assert(isequal(intersect(c, a), a), "SortDict intersect broken")
	assert(isequal(difference(c, a), c), "SortDict difference broken")
	assert(isequal(difference(a, b), a), "SortDict difference broken")
	
	
	a = [1:20]; b = [1,4,6,8,9,10,12,14,15,16,18,20]; c = [2,3,5,7,11,13,17,19]
	sda = SortDict(a,a); sdb = SortDict(b,b); sdc = SortDict(c,c)
	assert (isequal(difference(sda, sdb), sdc), "SortDict difference broken")
	
	sd = SortDict([1,2,3,4], [1.0, 2.0, 3.0, 4.0])
	assert(sum(sd) == 10.0, "general iterator broken")
	
	println("Passed basic sanity tests. But remember, that doesn't mean a thing.")
end
simple_tests()

function test_assign_rand_order(n)
	srand(1)
	for i in 1:n
		m = i-1
		sd = SortDict(Int, Float64)
		assert (isvalid(sd), "tree invalid after construction")
		a = [1:m]
		shuffle!(a)
		for x in a 
			sd[x] = 1/x
			assert (isvalid(sd), "tree invalid after insert")
		end
		ks = keys(sd)
		assert (isequal(sort!(a), ks), "not equal")
	end
	return ("Assign items in random order", "OK")
end


function test_del_rand_order(n)
	srand(1)
	for i in 1:n
		m = i-1
		a = [1:m]
		sd = SortDict(a,a)
		assert (isvalid(sd), "tree invalid after construction")
		shuffle!(a)
		b = Any[]
		for x in a 
			push(b, del(sd, x)[KEY])
			assert (isvalid(sd), "tree invalid after delete")
		end
		sort!(a)
		sort!(b)
		assert (isequal(a, b), "not equal")
		assert (isempty(sd), "not empty after delete all")
	end
	return ("Delete all items in random order", "OK")
end

function test_del_first(n)
	srand(1)
	for i in 1:n
		a = [1:i-1]
		sd = SortDict(a,a)
		b = Any[]
		for x in a 
			push(b, del_first(sd)[KEY])
			assert (isvalid(sd), "tree invalid after del_first")
		end
		assert (isequal(a, b), "result not sorted")
	end
	return ("Delete all items from left", "OK")
end

function test_del_last(n)
	srand(1)
	for i in 1:n
		a = [1:i-1]
		sd = SortDict(a,a)
		b = Any[]
		for x in a 
			enqueue(b, del_last(sd)[KEY])
			assert (isvalid(sd), "tree invalid after del_last")
		end
		assert (isequal(a, b), "result not sorted")
	end
	return ("Delete all items from right", "OK")
end

function test_split_and_join(n)
	sd = SortDict([1:n], [1:n])
	for i in 0:n+1
		sd2 = split!(sd, i)
		assert(isvalid(sd) && isvalid(sd2), "split! broken")
		join!(sd, sd2)
		assert(isvalid(sd), "join! broken")
	end
	return ("Split and join tree AT all keys in a tree", "OK")
end

function test_split_and_join_between(n)
	sd = SortDict([1:n]+0.0, [1:n])
	for i in -0.5:n+0.5
		sd2 = split!(sd, i)
		assert(isvalid(sd) && isvalid(sd2), "split! broken")
		join!(sd, sd2)
		assert(isvalid(sd), "join! broken")
	end
	return ("Split and join tree BETWEEN all keys in a tree", "OK")
end

function test_rank_and_select(n)
	srand(1)
	ks = [1 : n] + rand(n) * 0.8 + 0.1
	sd = SortDict(ks, ks)
	for x in ks
		assert(rank(sd, x) == ifloor(x), "rank broken")
		assert(select(sd, ifloor(x))[KEY] == x, "select broken")
	end
	return ("Select and rank of all keys in a tree", "OK")
end 

function test_basic_lookup(n)
	ks = [1 : n]
	sd = SortDict(ks,ks)
	for x in ks 
		assert(x == sd[x], "single element ref broken") 
		assert(x == get(sd, x, 9999), "get broken") 
		assert((x, x) == getkv(sd, x, 9999), "getkv broken") 
		assert(has(sd, x), "has broken") 
	end
	return ("Checking ref, get, getkv, has", "OK")
end	       



function test_set_ops(n) 

	euler_prime(n) = n^2 + n + 41	# for n in 1:100, 86 of these are prime
	euler = Int[] 
	primes = Int[]
	compo = Int[]
	for x in 1:1000
		y = euler_prime(x)
		push(euler, y)
		if isprime(y) 
			push(primes, y)
		else
			push(compo, y)
		end
	end
	
	sd_euler = SortDict(euler, euler)
	sd_primes = SortDict(primes,primes)
	sd_compo = SortDict(compo, compo)
	
	assert(isequal(sd_euler, union (sd_primes, sd_compo) ), "union broken")
	assert(isempty(intersect(sd_primes, sd_compo)), "intersect broken")
	assert(isequal(sd_compo, difference(sd_euler, sd_primes)), "difference broken")
	assert(isequal(sd_primes, difference(sd_euler, sd_compo)), "difference broken")
	
	return ("Testing set operations","OK")
		
end









function run_tests()
	N = 10 # don't try big numbers, usually whole trees are validated after each operation
	function call(fn :: Function) 
		x = apply(fn, N)
		println(rpad(x[1], 50), x[2] )
	end
	
	println((rpad("\nTesting...", 50)), "")
	call(test_assign_rand_order)
	call(test_del_rand_order)
	call(test_del_first)
	call(test_del_last)
	call(test_split_and_join)
	call(test_split_and_join_between)
	call(test_rank_and_select)
	call(test_basic_lookup)
	call(test_set_ops)
	     
end

run_tests()