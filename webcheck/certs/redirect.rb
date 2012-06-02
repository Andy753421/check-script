#!/usr/bin/ruby

def redirect(port)
	while true
		io = IO.popen("nc -l #{port}", "w+")
		line = io.gets
		if (line =~ /GET \/(.*) HTTP/)
			#puts "Location: http://plc.cs.rose-hulman.edu:#{port}/#{$~[1]}"
			io.puts "HTTP/1.0 301 Moved Permanently"
			io.puts "Location: https://plc.cs.rose-hulman.edu/#{$~[1]}"
		end
		io.close
	end
end
t1 = Thread.new { redirect(80) }
t2 = Thread.new { redirect(3000) }
t2.join
t1.join
