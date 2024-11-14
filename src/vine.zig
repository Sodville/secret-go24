const rl = @import("raylib");
const std = @import("std");
const math = std.math;

pub const VineManager = struct {
    vines: [1000]Vine = undefined,
    len: u32,

    pub fn init() VineManager {
        return .{
            .len = 0,
        };
    }

    pub fn add_vine(self: *VineManager, vine: Vine) void {
        self.vines[self.len] = vine;
        self.len += 1;
    }

    pub fn update(self: *VineManager) void {
        for (0..self.len) |i| {
            var vine: *Vine = &self.vines[i];
            vine.update(1);
        }
    }
    pub fn draw(self: *VineManager) void {
        for (0..self.len) |i| {
            var vine: *Vine = &self.vines[i];
            vine.draw();
        }
    }
};

pub const Point = struct {
    position: rl.Vector2,
    previous_position: rl.Vector2,
    anchored: bool,
    force: rl.Vector2,

    pub fn init(x: f32, y: f32, anchored: bool) Point {
        const pos = rl.Vector2.init(x, y);
        return Point{
            .position = pos,
            .previous_position = pos,
            .anchored = anchored,
            .force = rl.Vector2.init(0, 0),
        };
    }

    pub fn update(self: *Point, delta_x: f32, delta_y: f32) void {
        if (self.anchored) return;
        self.previous_position = self.position;

        self.position.x += (self.position.x - self.previous_position.x) + delta_x + self.force.x;
        self.position.y += (self.position.y - self.previous_position.y) + delta_y + self.force.y;

        self.force = rl.Vector2.init(0, 0);
    }

    pub fn apply_force(self: *Point, force: rl.Vector2) void {
        if (self.anchored) return;
        self.force = force;
    }

    fn constrain(self: *Point, other: *Point, len: f32) void {
        const delta = rl.Vector2.subtract(other.position, self.position);
        const dist = rl.Vector2.distance(other.position, self.position);

        const floored_dist: f32 = math.round(dist);
        const abs_dist = floored_dist - len;
        if (abs_dist == 0) return;

        const diff = (dist - len) / dist;
        const adjustment_x = delta.x * (0.5 * diff);
        const adjustment_y = delta.y * (0.5 * diff);

        if (self.anchored) {
            other.position.x -= adjustment_x * 2;
            other.position.y -= adjustment_y * 2;
            return;
        } else if (other.anchored) {
            self.position.x += adjustment_x * 2;
            self.position.y += adjustment_y * 2;
            return;
        }

        self.position.x += adjustment_x;
        self.position.y += adjustment_y;

        other.position.x -= adjustment_x;
        other.position.y -= adjustment_y;
    }
};

pub const Vine = struct {
    points: [25]Point = undefined, // Maximum number of segments
    length: f32,
    segment_length: f32,
    gravity: f32,
    damping: f32,
    num_points: u32,

    pub fn init(start_x: f32, start_y: f32, segment_length: f32, num_segments: u32) Vine {
        const float_num_segments: f32 = @floatFromInt(num_segments);
        var vine = Vine{
            .length = segment_length * float_num_segments,
            .segment_length = segment_length,
            .gravity = 9.81,
            .damping = 0.98,
            .num_points = num_segments + 1,
        };

        // Initialize points
        for (0..vine.num_points) |i| {
            const f_i: f32 = @floatFromInt(i);
            vine.points[i] = Point.init(start_x, start_y + segment_length * f_i, i == 0);
        }
        return vine;
    }

    pub fn update(self: *Vine, _: f32) void {
        for (0..self.num_points) |i| {
            const p1 = &self.points[i];
            p1.update(0, self.gravity / 60);
        }
        for (0..self.num_points - 1) |i| {
            const p1 = &self.points[i];
            const p2 = &self.points[i + 1];
            p1.constrain(p2, self.segment_length);
        }
    }

    pub fn draw(self: *Vine) void {
        for (0..self.num_points - 1) |i| {
            rl.drawLineV(self.points[i].position, self.points[i + 1].position, rl.Color.green);
        }
    }

    pub fn apply_localized_force(self: *Vine, position: rl.Vector2, radius: f32) void {
        for (0..self.num_points) |i| {
            const p1 = &self.points[i];
            if (p1.position.distance(position) <= radius) {
                const force = p1.position.subtract(position);
                const scaled_force = force.scale(0.06);
                p1.apply_force(scaled_force);
            }
        }
    }
    pub fn apply_global_force(self: *Vine, position: rl.Vector2) void {
        for (0..self.num_points) |i| {
            const p1 = &self.points[i];
            const force = p1.position.subtract(position).normalize();
            const scaled_force = force.scale(1);
            p1.apply_force(scaled_force);
        }
    }
};
