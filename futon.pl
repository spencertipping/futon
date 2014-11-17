#!/usr/bin/env perl
# Structural math for the futon project
# MIT license, and all units are in inches or degrees.

use Math::Trig;

# When upright, the futon seat should be reclined at about a 12-degree angle.
# The front edge should be 16" from the ground (that plus a 6" mattress under
# some compression is about 20-21"), and the front support is 5" from the edge.
#
# To make the math easier, I'm adjusting the angle a little bit so that the
# tangent is 1/5; this is about a 0.7-degree error and results in a slightly
# flatter seat.

my $ideal_seat_angle = 12;
my $seat_angle       = rad2deg atan 0.2;
printf "seat angle error is %f degrees\n", $ideal_seat_angle - $seat_angle;

# Next up is the minimum front beam length. The hinge for the back is 26" from
# the front edge: this gives 2.5" of frame thickness + 4-5" of compressed
# mattress for a total of about 20" seat depth. In practice the seat will be a
# little deeper because the mattress overhangs the front of the frame a little
# bit.
#
# The back should be about 115 degrees from the ground, supported against the
# main beam using a 15" tenoned leg. The tenon itself is 5", so the net height
# is 10" with 5" of thickness. When using the leg as a support, we anchor the
# rear beam against the tenon; this gives us a full 15" of leg length.

my $back_angle       = 115;
my $back_angle_delta = $back_angle - $seat_angle;
printf "back angle delta = %f\n", $back_angle_delta;

# The way to look at this is that the back forms an angle with the rear side of
# the main beam, and the law of sines tells us the lengths of the other two
# sides. We want to make these other sides as close to even as possible to
# minimize total cross-grain force.

my $back_leg_length      = 15;
my $effective_rear_angle = 180 - $back_angle_delta;
my $sin_multiplier       = $back_leg_length
                         / sin(deg2rad $effective_rear_angle);
my $other_angles         = $back_angle_delta / 2;
my $other_offsets        = $sin_multiplier * sin deg2rad $other_angles;

printf "other angles = %f\n",  $other_angles;
printf "other offsets = %f\n", $other_offsets;

# Although the beams are 5" thick, the supporting leg sinks into a notch in the
# main frame and the rear beam. Because of all of the corners, it's worth being
# a little clearer about what's going on. This picture uses the main beam as
# the frame of reference:
#
#                      5"
#                    |-----|
#
#        _          __\__   \                                 _
#       |          /   \/    \                                 |
#       |         /    /\     \                                |
#   10" |        /    /  \     \                               |
#       |       /    /    \     \     <- rear beam             | $other_offsets
#       |_     /   _/      \     \                             |
#       |      /  /         \     \                            |
#    5" |     /  /           \     \                           |
#       |_   /  /_____________\_____\______________________   _|           _
#   notch -> \_/               \     \                     |                |
#                               \  O  \                    |  <- main beam  | 5"
#             ___________________\_____\___________________|               _|
#
#                |------------|    |-----------------------|
#                $other_offsets               26"
#
# Despite the picture above, the leg has a square bottom and fits into a simple
# V-notch in the main beam. All measurements should be understood as being
# parallel to the beams they describe, not straight-vertical or horizontal as
# drawn.
#
# Anyway, there are two things we can do to simplify the corner-displacement
# problem. One is to sink half of the supporting leg into the main beam, which
# effectively lets us use the center line of the 15" supporting leg as our
# operative measurement. We can do the same thing on the rear frame beam; then
# $other_offsets ends up being a measurement from the frame intersection to the
# far ends of the notches.
#
# Force-wise, we have a 2in² (approx) support under 3:1 compression. Spruce has
# a cross-grain crush strength of 430PSI. Here's how we calculate the yield
# strength of the rear support:

my $failure_psi       = 430;
my $cross_section_si  = 2;
my $compression_ratio = 3;
my $failure_load_top  = $failure_psi * $cross_section_si / $compression_ratio;
my $failure_load_even = $failure_load_top * 2;

printf "failure load = %.4flb at top, %.4flb spread evenly\n",
       $failure_load_top, $failure_load_even;

# We need some room behind the notch to make sure the wood can resist the grain
# shearing caused by the supporting leg. Conservatively assuming equal force in
# each direction and no friction:

my $parallel_shear_failure_psi = 970;
my $board_thickness            = 1.375;         # conservative; actual is ~1.5
my $maximum_lbf                = $failure_psi * $cross_section_si;
my $si_at_shear_failure        = $parallel_shear_failure_psi / $maximum_lbf;
my $minimum_post_notch_length  = $si_at_shear_failure / $board_thickness;

printf "maximum force = %.4flbf, in² at shear failure = %.4f\n",
       $maximum_lbf, $si_at_shear_failure;

printf "minimum post-notch length: %.4fin\n", $minimum_post_notch_length;

# To compensate for wood imperfections and to be on the safe side, I'm going to
# use 3" instead of 0.82". At least we know this is unlikely to be the failure
# point.
#
# So ... getting back to the main beam length, we've got the offset from the
# beam intersection (this gets us to the far end of the notch) and the safety
# margin beyond this. To get this number, we first need to calculate the beam
# intersection offset:

my $beam_thickness           = 5;
my $beam_intersection        = $beam_thickness / 2
                             / sin deg2rad $effective_rear_angle;
my $post_notch_length        = 3;
my $main_beam_minimum_length = 26 + $beam_intersection
                             + $other_offsets + $post_notch_length;

printf "beam intersection = %.4fin\n",        $beam_intersection;
printf "main beam minimum length = %.4fin\n", $main_beam_minimum_length;
printf "main beam notch/hole distance = %.4fin\n",
       $beam_intersection + $other_offsets;

# At this point we have a fairly significant problem with the design. The rear
# beam folds down flat against the main beam, but we've said that it supports
# the leg such that the effective intersection is aligned with the point at
# which the notch hits zero depth. If you think about how this has to work,
# you'll realize that whatever internal support we're using must not only
# collide with the notch, but must be strictly deeper than the deepest point.
#
# Fortunately, there's a nice hack we can use to sidestep the issue entirely.
# If we turn the leg 90 degrees along its long axis, we can just create 1.375"
# notches in both the main and the rear beams and use no internal structure at
# all. This gives us a 1.375 * 1.375 contact point with the main beam, which is
# about 1.9in² (in practice a little larger); this is why I estimated the
# forces against a 2in² cross section earlier.

# Ok, with that out of the way we can now figure out how tall the main beam
# rear supports need to be. Because we're designing with a 5:1 angle, let's
# assume the rear support (which is itself angled) accepts the main beam in a
# 5x4" notch, and that it has a 5x1" wedge to cover the end grain of the main
# beam:
#             _______________________________________
#           /|
#          / |      main beam
#         /  |_______________________________________
#        /      /
#       /_     /    <- rear support
#         ^-._/        (the bottom is straight)
#
# Then we can model it as the main beam losing height from its front 16" edge
# (11" on the bottom side).

my $main_beam_drop = ($main_beam_minimum_length - 4) * sin deg2rad $seat_angle;
my $rear_support_height = 16 - $beam_thickness - $main_beam_drop;

printf "main beam height drop = %.4fin\n", $main_beam_drop;
printf "rear support height = %.4fin\n", $rear_support_height;

# Let's also figure out the exact dimensions of the rear support:
#
#        1"  4"
#       |--|-----|
#    _
#     | |\
# $x" | | \           _
#    _| |  \_.--^|   |
#       |        |   |  3.21"
#       |        |   |
#       |________|   |_
#
#       |--------|
#           5"
#
# There's actually some minor inaccuracy here because the diagonal along the 4"
# segment ends up being slightly longer than 4". Because of this, I'm going to
# round the 3.21" up to 3.22" (= 3 + 7/32).

my $rounded_rear_support_height = 3.22;
my $rear_support_wedge_height = $beam_thickness * cos deg2rad $seat_angle;
my $rear_support_total_height = $rounded_rear_support_height
                              + $rear_support_wedge_height;

printf "rear support wedge height = %.4fin, total = %.4fin\n",
       $rear_support_wedge_height, $rear_support_total_height;
