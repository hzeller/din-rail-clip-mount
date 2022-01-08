
din-rail-clip-mount.stl:

%.stl : %.scad
	openscad -o $@ $^
