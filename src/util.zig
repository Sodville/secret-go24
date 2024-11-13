const std = @import("std");

const math = std.math;

pub fn ease_in_out_elastic(x: f32) f32 {
    const c5 = (2 * math.pi) / 4.5;

    return if (x == 0.0) 0.0 else if (x == 1.0) 1.0 else if (x < 0.5)
        -((math.pow(f32, 2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2)
    else
        ((math.pow(f32, 2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) / 2) + 1.0;
}
