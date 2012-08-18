


type Goright{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

type Goright_fast{K, V}
	node :: Node{K, V}
end

type Goright_kv{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

type Goright_kv_fast{K, V}
	node :: Node{K, V}
end

type Goleft{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

type Goleft_fast{K, V}
	node :: Node{K, V}
end

type Goleft_kv{K, V}
	node :: Node{K, V}
	key :: K
	cf :: Function
end

type Goleft_kv_fast{K, V}
	node :: Node{K, V}
end


function start_right{K, V} (node :: Avl{K, V}) 
 	stack = Array(Node{K, V}, 0)
	while notempty(node)
		push(stack, node)
		node = node.child[LEFT]
	end
	return stack
end

function start_left{K, V} (node :: Avl{K, V}) 
 	stack = Array(Node{K, V}, 0)
	while notempty(node)
		push(stack, node)
		node = node.child[RIGHT]
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

function next_left{K, V} (node :: Avl{K, V}, stack :: Vector{Node{K, V}})
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

function next_right{K, V} (node :: Avl{K, V}, stack :: Vector{Node{K, V}})
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

Goright{K, V}	(sd :: SortDict{K, V}) 			= Goright_fast(sd.tree)
Goright_kv{K, V}	(sd :: SortDict{K, V}) 			= Goright_kv_fast(sd.tree)
Goleft{K, V}	(sd :: SortDict{K, V}) 			= Goleft_fast(sd.tree)
Goleft_kv{K, V}	(sd :: SortDict{K, V}) 			= Goleft_kv_fast(sd.tree)

Goright{K, V}	(sd :: SortDict{K, V}, key :: K) 	= Goright(sd.tree, key, sd.cf)
Goright_kv{K, V}	(sd :: SortDict{K, V}, key :: K) 	= Goright_kv(sd.tree, key, sd.cf)
Goleft{K, V}	(sd :: SortDict{K, V}, key :: K) 	= Goleft(sd.tree, key, sd.cf)
Goleft_kv{K, V}	(sd :: SortDict{K, V}, key :: K) 	= Goleft_kv(sd.tree, key, sd.cf)

# special case when using the SortDict itself as an iterator
start{K, V}	(iter :: SortDict{K, V}) 				= start_right(iter.tree)
next{K, V}	(iter :: SortDict{K, V}, stack :: Vector{Node{K, V}})	= ((elem, stack) = next_right(iter.tree, stack); (elem[VALUE], stack))
done{K, V}	(iter :: SortDict{K, V}, stack :: Vector{Node{K, V}})	= isempty(stack)

start{K, V} (iter :: Goleft{K, V}) 		= start_left(iter.node, iter.key, iter.cf)
start{K, V} (iter :: Goleft_kv{K, V}) 		= start_left(iter.node, iter.key, iter.cf)
start{K, V} (iter :: Goright{K, V})		= start_right(iter.node, iter.key, iter.cf)
start{K, V} (iter :: Goright_kv{K, V})		= start_right(iter.node, iter.key, iter.cf)

start{K, V} (iter :: Goleft_fast{K, V}) 	= start_left(iter.node)
start{K, V} (iter :: Goleft_kv_fast{K, V}) 	= start_left(iter.node)
start{K, V} (iter :: Goright_fast{K, V}) 	= start_right(iter.node)
start{K, V} (iter :: Goright_kv_fast{K, V})	= start_right(iter.node)

next{K, V} (iter :: Goleft{K, V}, 		stack :: Vector{Node{K, V}}) = ((elem, stack) = next_left (iter.node, stack); (elem[VALUE], stack))
next{K, V} (iter :: Goleft_fast{K, V}, 	stack :: Vector{Node{K, V}}) = ((elem, stack) = next_left (iter.node, stack); (elem[VALUE], stack))
next{K, V} (iter :: Goright{K, V}, 		stack :: Vector{Node{K, V}}) = ((elem, stack) = next_right(iter.node, stack); (elem[VALUE], stack))
next{K, V} (iter :: Goright_fast{K, V}, 	stack :: Vector{Node{K, V}}) = ((elem, stack) = next_right(iter.node, stack); (elem[VALUE], stack))

next{K, V} (iter :: Goleft_kv{K, V}, 		stack :: Vector{Node{K, V}}) = ((elem, stack) = next_left (iter.node, stack); (elem, stack))
next{K, V} (iter :: Goleft_kv_fast{K, V}, 	stack :: Vector{Node{K, V}}) = ((elem, stack) = next_left (iter.node, stack); (elem, stack))
next{K, V} (iter :: Goright_kv{K, V}, 		stack :: Vector{Node{K, V}}) = ((elem, stack) = next_right(iter.node, stack); (elem, stack))
next{K, V} (iter :: Goright_kv_fast{K, V}, 	stack :: Vector{Node{K, V}}) = ((elem, stack) = next_right(iter.node, stack); (elem, stack))

done{K, V} (iter :: Goleft{K, V}, 		stack :: Vector{Node{K, V}}) = isempty(stack)
done{K, V} (iter :: Goleft_fast{K, V}, 	stack :: Vector{Node{K, V}}) = isempty(stack)
done{K, V} (iter :: Goleft_kv{K, V}, 		stack :: Vector{Node{K, V}}) = isempty(stack)
done{K, V} (iter :: Goleft_kv_fast{K, V}, 	stack :: Vector{Node{K, V}}) = isempty(stack)
done{K, V} (iter :: Goright{K, V}, 		stack :: Vector{Node{K, V}}) = isempty(stack)
done{K, V} (iter :: Goright_fast{K, V},	stack :: Vector{Node{K, V}}) = isempty(stack)
done{K, V} (iter :: Goright_kv{K, V}, 		stack :: Vector{Node{K, V}}) = isempty(stack)
done{K, V} (iter :: Goright_kv_fast{K, V}, 	stack :: Vector{Node{K, V}}) = isempty(stack)

