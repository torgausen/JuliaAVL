

# basic tree functionality

has{K}(node :: Nil, key :: K, cf :: Function) = false
function has{K, V}(node :: Node{K, V}, key :: K, cf :: Function)
	if cf(key, node.key)
		has(node.child[LEFT], key, cf)
	elseif cf(node.key, key)
		has(node.child[RIGHT], key, cf)
	else
		return true
	end
end

get{K, V} (node :: Nil{K, V}, key :: K, default :: V, cf :: Function) = default
function get{K, V}(node :: Node{K, V}, key :: K, default :: V, cf :: Function)
	if cf(key, node.key)
		get(node.child[LEFT], key, default, cf)
	elseif cf(node.key, key)
		get(node.child[RIGHT], key, default, cf)
	else
		return node.value
	end
end

getkv{K, V} (node :: Nil{K, V}, key :: K, default :: V, cf :: Function) = default
function getkv{K, V}(node :: Node{K, V}, key :: K, default :: V, cf :: Function)
	if cf(key, node.key)
		getkv(node.child[LEFT], key, default, cf)
	elseif cf(node.key, key)
		getkv(node.child[RIGHT], key, default, cf)
	else
		return (node.key, node.value)
	end
end

ref{K,V}(node :: Nil{K, V}, key :: K, cf :: Function) = throw(KeyError(key))
function ref{K, V}(node :: Node{K, V}, key :: K, cf :: Function)
	if cf(key, node.key)
		ref(node.child[LEFT], key, cf)
	elseif cf(node.key, key)
		ref(node.child[RIGHT], key, cf)
	else
		return node.value
	end
end
