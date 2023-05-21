
din-rail-clip-mount.stl:

%.stl : %.scad
	openscad -o $@ $^

clean:
	rm -f din-rail-clip-mount.stl
