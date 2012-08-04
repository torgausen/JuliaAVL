#
#	stuff that's helpful while debugging
#




# call this on a tree to display it's structure
# a number is followed by '-', "", or '+' indicates count and balance factors
# below is either a key or key, value pair, according to show_values bool parameter

function draw(node, show_values, show_counts, screen_cols)
	function draw_rec (n, x, y, space)
		function plot_text(str, x, y)
			local s = text[y]
			text[y] = strcat (s[1:x-1], str, s[x + length(str):])
		end
		if isempty(n) return end
		bal = ("=", ">", "<")[n.bal + 1]
		
		yp = y
		plot_text(string(bal), x, yp)
		yp += 1
		if show_counts
			plot_text(strcat(n.counter), x, yp)
			yp += 1
		end
		if show_values
			plot_text(string(n.key,":",n.value), x, yp)
		else
			plot_text(string(n.key), x, yp)
		end
		draw_rec(n.child[LEFT], x-space, y + 3, div(space, 2))
		draw_rec(n.child[RIGHT], x+space, y + 3, div(space, 2))
	end 

	if isempty(node)
		println ("Tree empty")
		return
	end
	
	text = Array(String, 0)
	s = repeat(" ", screen_cols)
	for i = 1:30
		push(text, s)
	end

	draw_rec(node, div(screen_cols, 2), 2, div(screen_cols, 4))

	while last(text) == s
		pop(text)
	end
	
	for line in text
		println(line)
	end
	println(repeat("-", screen_cols))
end
draw(node) = draw(node, false, false, 128)
draw(node, a :: Bool, b :: Bool) = draw(node, a, b, 128)


