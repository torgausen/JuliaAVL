

require ("AVLbase.jl")
require ("AVLutil.jl")
 
# union of two trees in linear time (n + m)
function union_linear{K, V} (n1 :: Avl{K, V}, n2 :: Avl{K, V}, cf :: Function)
	la = length(n1)
	lb = length(n2)
	lc = la + lb
	a, av = flatten(n1)
	b, bv = flatten(n2)
	c, cv = Array(K, lc), Array(V, lc) # A bit painful to allocate all these arrays...
	i = 1
	j = 1
	k = 0
	while i <= la && j <= lb 
		if a[i] < b[j] 
			k += 1
			c[k] = a[i]
			cv[k] = av[i]
			i += 1
		elseif b[j] < a[i]
			k += 1
			c[k] = b[j]
			cv[k] = bv[j]
			j += 1
		else
			k += 1
			c[k] = b[j]	# overwrite from second tree
			cv[k] = bv[j]
			i += 1
			j += 1
		end
	end
	while i <= la 
		k += 1
		c[k] = a[i]
		cv[k] = av[i]
		i += 1
	end
	while j <= lb 
		k += 1
		c[k] = b[j]
		cv[k] = bv[j]
		j += 1
	end
	build(c[1 : k], cv[1 : k])
end


function intersect_linear{K, V}(n1 :: Node{K, V}, n2 :: Node{K, V}, cf :: Function)
	a, av = flatten(n1)
	b, bv = flatten(n2)
	i = 1
	j = 1
	dst = 0
	while i <= length(a) && j <= length(b) 
		if a[i] < b[j] 
			i += 1
		elseif b[j] < a[i]
			j += 1
		else
			dst += 1
			a[dst] = a[i]
			av[dst] = av[i]
			i += 1
			j += 1
		end
	end
	build(a[1 : dst], av[1 : dst])
end

intersect_mlogn{K, V} (big :: Nil{K, V}, small :: Nil{K, V}, cf :: Function) = big
intersect_mlogn{K, V} (big :: Node{K, V}, small :: Nil{K, V}, cf :: Function) = small
intersect_mlogn{K, V} (big :: Nil{K, V}, small :: Node{K, V}, cf :: Function) = big
function intersect_mlogn{K, V} (big :: Node{K, V}, small :: Node{K, V}, cf :: Function)
	ks = K[]
	vs = V[]
	for (key, value) in Gorightkv_fast(small)
		if has(big, key, cf)
			push(ks, key)
			push(vs, value)
		end
	end
	build(ks, vs)
end
 
# destroys t1
# called if small t2 (m)
function diff_mlogn!{K, V} (t1 :: Node{K, V}, t2 :: Node{K, V}, cf :: Function)
	rec{K, V}(node :: Nil{K, V}) = return
	function rec{K, V}(node :: Node{K, V})
		println(node.key)
		f, c, rv, t1 = del_any(t1, node.key, nothing, cf)
		rec(node.child[LEFT])
		rec(node.child[RIGHT])
	end
	t2 = copy(t2)
	rec(t2)
	t1
end

# if small t1 (n)
function diff_nlogm{K, V} (t1 :: Node{K, V}, t2 :: Node{K, V}, cf :: Function) 
	ks, vs = flatten(t1)
	s = 1
	d = 0
	while s <= length(ks)
		if !has(t2, ks[s], cf)
			d += 1
			ks[d] = ks[s]
			vs[d] = vs[s]
		end
		s += 1
	end
	build(ks[1 : d], vs[1 : d])
end

diff_linear{K, V} (t1 :: Nil{K, V}, t2 :: Avl{K, V}, cf :: Function) = t1
diff_linear{K, V} (t1 :: Node{K, V}, t2 :: Nil{K, V}, cf :: Function) = t1
function diff_linear{K, V} (t1 :: Node{K, V}, t2 :: Node{K, V}, cf :: Function)
	a, av = flatten(t1)
	b, bv = flatten(t2)
	
	dst = 0
	src = 1
	cmp = 1
	< = cf
	
	while src <= length(a) && cmp <= length(b)
		if a[src] < b[cmp] 
			dst += 1
			a[dst] = a[src]
			av[dst] = av[src]
			src += 1
		elseif b[cmp] < a[src] 
			cmp += 1
		else
			src += 1
			cmp += 1
		end 
	end 
	while src <= length(a)
		dst += 1
		a[dst] = a[src]
		av[dst] = av[src]
		src += 1
	end 
	build(a[1 : dst], av[1 : dst])
end

