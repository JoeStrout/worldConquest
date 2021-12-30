if version.host < 1.1 then
	text.color = color.silver
	_printMark "Whoops!  World Conquest requires Mini Micro `1.1` or later.", color.white
	print
	print "Please download the latest version of Mini Micro from:"
	text.color = color.white
	print "https://miniscript.org/MiniMicro"
	print
	text.color = color.orange
	exit
end if
cd "WorldConquest"
load "title"; run
