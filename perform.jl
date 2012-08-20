
# attempt to capture performance of each version between 'improvements' of the code
# I decided to test assign, del, select, union and the standard iterator. 
# Other functions should have similar peformance characterisitcs.


load("SortDict.jl")
import SortDict.*

function f()
	println("---------------------------------------------------------------------------------------------------------------------")
	tic()
	for (n, m) in [ (10, 100_000), (100, 10_000), (1000, 1000), (10_000, 100), (100_000, 10) ]
		srand(1)
		a = shuffle([1:n])
		tic()
		build_time = assign_time = select_time = has_time = union_time = del_time = 0.0
		for j in 1 : m
			# build using constructor
			tic(); sd1 = SDict([1:n], [1:n]); build_time += toq()
			
			# build with assigns 
			sd2 = SDict(Int, Int)
			for i in 1:n
				k = a[i]
				tic();
				sd2[k] = k
				assign_time += toq()
			end
			
			# test select on one of the trees
			for i in 1:n
				tic();
				select(sd1, i)
				select_time += toq()
			end
			
			# test has on one of the trees
			for i in 1:n
				tic();
				has(sd2, i)
				has_time += toq()
			end
			
			# test union
			tic(); union(sd1, sd2); union_time += toq()
			
			# delete all
			for i in 1:n
				tic();
				del (sd2, i)
				del_time += toq()
			end
			
		end
		total = toq()
		overhead = total - assign_time - select_time - build_time - del_time - union_time
		println("assigning  $n items $m times	: $assign_time")
		println("build      $n items $m times	: $build_time")
		println("has        $n items $m times	: $has_time")
		println("selecting  $n items $m times	: $select_time")
		println("union of   $n items:$m times	: $union_time")
		println("delete     $n items $m times	: $del_time")
		println("total times			: $total")
		println("overhead			: $overhead")
		
	end
		print("total for running tests 	: "); print(toq())
end
f()

