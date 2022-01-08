// -*- mode: scad; c-basic-offset: 2; indent-tabs-mode: nil; -*-
e=0.01;

with_frame=true;             // The mounting frame
with_isolation=true;         // isolation layer in frame
with_spring_cover=false;     // covering the spring with cover (needs bridging)
with_whole_width_rest=true;  // rest on din-rail for whole length.

// Size of the hole-pattern for mounting.
screw_along  = 67;
screw_across = 44.5;
lug_len=10;            // Length of the lug used pull down to remove from rail

screw_bar=8;           // Width of the outer frame bar with screw holes
screw_dia=3.5;

din_wide=35;
din_dist=din_wide - 0.5; // Slightly smaller for more clamping action.
din_sheet=1;           // thickness of the din-rail metal

bottom_thick=3;       // Thickness of whole underside frame
isolation_thick=0.4;  // Thickness of isolation bottom.
spring_thick=2;

rest_shelf=5;         // The width of the area resting on the rail itself.
hold_wide=25;         // The width of the top 'hook' holding on the rail.
latch_wide=15;        // The width of the moveable clip at the bottom of rail.
slide_gap=0.25;       // In-place printed gap for clip to move.

plate_x = screw_across + screw_bar;
plate_y = hold_wide + 2;

module hook_polygon(do_slide=false) {
  w=1;
  h=do_slide ? 0.8 : 2;
  ledge=1;
  hd=sqrt(2) * h;
  // TODO: doing both hook types in one do_slide-configured array is not
  // very readable and should be broken up into two.
  polygon([[-2*w, -bottom_thick], [0, -bottom_thick], [0, din_sheet],
           [h, h + din_sheet], [h, h + ledge + din_sheet],
           if (do_slide) [-1, h + ledge + din_sheet+3],
           if (do_slide) [-2, h + ledge + din_sheet+3],
           if (do_slide) [-3, 0],
           if (!do_slide) [0, h + ledge + din_sheet],
           [-2*w, 0],
           ]);
}

module hook(len=15, do_slide=false) {
  translate([0, len/2, 0]) rotate([90, 0, 0])
    linear_extrude(height=len) hook_polygon(do_slide);
}

module spring_polygon(len=20, wide=15, thick=1) {
  p=3;  // periods
  n=50;
  actual_w=wide/2 - thick/2;
  points = [
    for (i = [0:n]) [ len*i/n, actual_w*cos(i * p * 360 / n) + thick/2],
    for (i = [0:n]) [ len*(n-i)/n, actual_w*cos((n-i) * p * 360 / n) - thick/2],
  ];

  translate([0, -actual_w, 0]) polygon(points);
}

module spring(len=20, wide=15, thick=1, height=1) {
  linear_extrude(height=height) spring_polygon(len, wide, thick);
}

module spring_symmetric(len=20, wide=15, delta=5, thick=1, height=1) {
  half_w=wide/2-delta/2;
  translate([0, -delta/2, -bottom_thick]) spring(len, half_w, thick, height);
  scale([1, -1, 1]) translate([0, -delta/2, -bottom_thick])
    spring(len, half_w, thick, height);
}

module bottom_plate() {
  w = screw_along;
  h = screw_across;

  difference() {
    translate([din_dist/2, 0, -bottom_thick/2]) {
      cube([plate_x, plate_y, bottom_thick], center=true);

      if (with_frame) {
        if (with_isolation) {
          translate([-h/2, -w/2, -bottom_thick/2]) cube([h, w, isolation_thick]);
        }

        if (with_whole_width_rest) {
          translate([-din_dist/2, -w/2, -bottom_thick/2])
            cube([rest_shelf, w, bottom_thick]);
          translate([-din_dist/2 + din_wide - rest_shelf, -w/2, -bottom_thick/2])
            cube([rest_shelf, w, bottom_thick]);
        }

        // frame around. hull() joined cylinders making nice rounded corners.
        hull() {
          translate([h/2, w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
          translate([-h/2, w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
        }
        hull() {
          translate([h/2, -w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
          translate([-h/2, -w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
        }
        hull() {
          translate([-h/2, w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
          translate([-h/2, -w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
        }
        hull() {
          translate([h/2, w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
          translate([h/2, -w/2, -bottom_thick/2]) cylinder(r=screw_bar/2, h=bottom_thick);
        }
      }
    }

    for (dx = [-1, 1]) {
      for (dy = [-1, 1]) {
        translate([din_dist/2+dx*h/2, dy*w/2, -bottom_thick-e]) cylinder(r=screw_dia/2, h=bottom_thick+2*e, $fn=12);
      }
    }
  }
}

module spring_latch() {
  hook(len=latch_wide, true);

  translate([rest_shelf, 0, 0]) spring_symmetric(len=din_dist - 2*rest_shelf,
                                                 thick=1.2, wide=latch_wide,
                                                 delta=5, height=spring_thick);
}

module dovetail(h=2, gap=slide_gap, len=20) {
  c=h/10;  // center
  out=h/1.5;
  hull() {
    translate([-h/2, -gap/2+e, 0]) cylinder(r=gap/2, h=len);
    translate([-c, -out, 0]) cylinder(r=gap/2, h=len);
  }
  hull() {
    translate([-c, -out, 0]) cylinder(r=gap/2, h=len);
    translate([+c, -out, 0]) cylinder(r=gap/2, h=len);
  }
  hull() {
    translate([+c, -out, 0]) cylinder(r=gap/2, h=len);
    translate([+h/2, -gap/2+e, 0]) cylinder(r=gap/2, h=len);
  }
}

module one_slide(len=2, slide_wide=(plate_y-latch_wide)/4) {
  translate([din_dist-rest_shelf, -latch_wide/2-slide_wide, -bottom_thick/2])
    rotate([0, -90, 0]) dovetail(h=bottom_thick, len=len);
}

module spring_punch(skin=with_spring_cover ? isolation_thick : 0) {
  color("yellow") translate([rest_shelf, -latch_wide/2, -bottom_thick-e-skin])
    cube([din_dist-2*rest_shelf, latch_wide, bottom_thick+2*e]);
}

module punch() {
  spring_punch();  // Space for the spring.
  hull() {
    one_slide(len=0.5);
    scale([1, -1, 1]) one_slide(len=0.5);
  }
  one_slide(len=60);
  scale([1, -1, 1]) one_slide(len=60);
}

module open_pull_lug(h=2) {
  r=2;
  wide=6.5;  // half-wide. Good enough for pocket knife blade.
  translate([e, 0, -bottom_thick])
    difference() {
    hull() {
      translate([-lug_len, -wide, 0]) cube([lug_len, 2*wide, h]);
      translate([-lug_len, -wide+r, 0]) cylinder(r=r, h=h, $fn=20);
      translate([-lug_len, +wide-r, 0]) cylinder(r=r, h=h, $fn=20);
    }
    translate([0, 0, -e]) hull() {
      translate([-lug_len+0.5, -wide+0.5+r, 0]) cylinder(r=1.8/2, h=h+2*e, $fn=20);
      translate([-lug_len+0.5, +wide-0.5-r, 0]) cylinder(r=1.8/2, h=h+2*e, $fn=20);
    }
  }
}


// Hooks
translate([din_dist, 0, 0]) scale([-1, 1, 1]) hook(len=hold_wide);  // hold hook
spring_latch();  // latching hook

// Place to mount PCB etc.
difference() {
  bottom_plate();
  punch();
}

// Make simple to open.
translate([-(plate_x - din_dist)/2, 0, 0]) open_pull_lug();
