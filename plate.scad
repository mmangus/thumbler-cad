$fa = 1;
$fs = 0.4;

// can be 0 for final rendering
DRAW_TOLERANCE = 0.05;

// number of columns in the gridlike central region
n_standard_columns = 5;
// height expressed as number of switches
column_heights = [4, 5, 5, 5, 5];
// shim is top offset (mm), + is lower, - is higher
column_shims = [0, -5, -8, -12, -12];

// approx. kailh dimensions (mm)
switch_dims= [
    14,
    14, 
    4.6
];
// extension of pin/bump from bottom of switch body (mm)
switch_pin_z = 4;

// spacing between two keys is 2 * key_margin
key_margin = [2.5, 2.5, 0];  // 2 for cap, 0.5 for gap
// bracket fits a key with margin on both sides of it
bracket_dims = [
    switch_dims.x + 2 * key_margin.x,
    switch_dims.y + 2 * key_margin.y,
    switch_dims.z + 2 * key_margin.z
];

module switch() {
    // more accurately, a switch bounding box w/o pins
    cube(switch_dims);
}


module standard_column(position, n_switches) {
    column_dims = [
        bracket_dims.x * n_switches,
        bracket_dims.y,
        switch_dims.z - 2 * DRAW_TOLERANCE + key_margin.z
    ];
    translate(position) {
        difference() {
            cube(column_dims);
            // subtract room for the switches
            for (i = [0:n_switches - 1]) {
                translate([
                    (
                        i * bracket_dims.x 
                        + key_margin.x
                    ),
                    key_margin.y,
                    -DRAW_TOLERANCE
                ]) {
                    switch();
                }
            }
        }
    }
}


module qwer_section() {
    for (i = [0:n_standard_columns - 1]) {
        standard_column(
            [
                column_shims[i],
                i * bracket_dims.y,
                0
            ],
            column_heights[i]
        );
    }
}


module outer_section() {
    /* the outer section has a complicated mixture of switch
        positions, so this is a bit ugly / hard to cleanly
        parameterize... maybe one option is to have an array
        of key widths for each col and an "empty" marker to 
        accommodate the adjoining spots like...
            inner = [1U, 1U, 2U, 2U, 1U], 
            outer = [1U, empty, empty, 1U]
        ? not really sure what the best practice is, and ^ that
        would still require setting the shims to make the rows
        align between those cols
    */ 
    inner_shim = -8;
    inner_height = 5; 
    // inner_shim and outer_shim need to align the rows
    // TODO how to explicitly constrain them to do so?
    outer_shim = 11;
    outer_height = 4;
    difference() {
        union () {
            // inner part
            translate([
                inner_shim,
                n_standard_columns * bracket_dims.y,
                0
            ]) {
                cube([
                    bracket_dims.x * inner_height,
                    bracket_dims.y,
                    (
                        switch_dims.z 
                        - 2 * DRAW_TOLERANCE 
                        + key_margin.z
                    )
                ]);
            }
            // outer part
            translate([
                outer_shim,
                (n_standard_columns + 1) * bracket_dims.y,
                0
            ]) {
                cube([
                    bracket_dims.x * outer_height,
                    bracket_dims.y,
                    (
                        switch_dims.z 
                        - 2 * DRAW_TOLERANCE 
                        + key_margin.z
                    )
                ]);
            }
        }
        union () {
            // single-width inner keys
            for (i=[0:inner_height - 1]) {
                translate([
                    (
                        inner_shim 
                        + key_margin.x 
                        + bracket_dims.x * i
                    ),
                    (
                        n_standard_columns
                        * bracket_dims.y 
                        + key_margin.y
                    ),
                    -DRAW_TOLERANCE
                ]) {
                    // FIXME scad "in" check?
                    if (i != 2 && i != 3) switch();
                }
            }
            // single-width outer keys
            for (i=[0:outer_height - 1]) {
                translate([
                    (
                        outer_shim 
                        + key_margin.x 
                        + bracket_dims.x * i
                    ),
                    (
                        (n_standard_columns + 1)
                        * bracket_dims.y 
                        + key_margin.y
                    ),
                    -DRAW_TOLERANCE
                ]) {
                    // FIXME scad "in" check?
                    if (i != 1 && i != 2) switch();
                }
            }
            // double-width keys
            for (i=[1:2]) {
                translate([
                   /* see above: outer and inner need to 
                        combine to give you an aligned row
                    */
                    (
                        outer_shim 
                        + key_margin.x 
                        + bracket_dims.x * i
                    ),
                    // FIXME ugly
                    (
                        (n_standard_columns + 0.5)
                        * bracket_dims.y
                        + key_margin.y 
                    ),
                    -DRAW_TOLERANCE
                ]) {
                    switch();
                }
            }
        }
    }
}

/* probably cleaner to pass thru params here instead of using
*    so many globals, altho not sure how that works w/ the
*    customizer?
*/
module half() {
    qwer_section();
    outer_section();
}


module keyboard(rot=false) {
    // i kinda picked the wrong orientation :(
    rotate([0, 0, rot ? -90 : 0]) {
        translate([0, 5, 0]) { 
            half();
        }
        translate([0, -5, 0]) {
            mirror([0, 1, 0]) {
                half();
            }
        }
    }
}

keyboard();
