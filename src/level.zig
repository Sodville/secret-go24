const std = @import("std");
const grass = @import("grass.zig");
const tmx = @import("tmx.zig");
const vn = @import("vine.zig");
const rl = @import("raylib");

pub const Level = struct {
    collisions: []rl.Rectangle = &.{},
    gm: *grass.GrassManager,
    vm: *vn.VineManager,
    map: tmx.Map,

    // temporary
    // until revised with a better structure for assets
    tileset: rl.Texture,

    pub fn init(map_path: []const u8, gm: *grass.GrassManager, vm: *vn.VineManager) !Level {
        var prng = std.rand.DefaultPrng.init(180102);
        const rand = prng.random();

        var map = try tmx.load_map(map_path);
        var collisions = map.get_objects_by_group_name("collisions").?;

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var rect_collisions = std.ArrayList(rl.Rectangle).init(allocator);

        while (collisions.next()) |object| {
            try rect_collisions.append(object.to_rect());
        }

        var map_grass = map.get_objects_by_group_name("grass").?;
        while (map_grass.next()) |object| {
            const denom = rand.intRangeAtMost(u32, 2, 4);
            for (0..object.width orelse 0) |x| {
                if (x % denom == 0) {
                    const x_u32: u32 = @intCast(x);
                    gm.add_grass(grass.Grass.init(object.x + x_u32, object.y, 0));
                }
            }
        }

        var vines = map.get_objects_by_group_name("vines").?;
        while (vines.next()) |vine_object| {
            var vine = vn.Vine.init(
                @floatFromInt(vine_object.x),
                @floatFromInt(vine_object.y),
                10,
                9,
            );
            if (vine_object.polylines == null) {
                continue;
            }

            for (vine_object.polylines.?) |lines| {
                for (lines.points, 0..) |point, index| {
                    const real_index = 3 * index;
                    if (real_index >= vine.num_points) break;

                    vine.points[real_index].position = rl.Vector2.init(@as(f32, @floatFromInt(vine_object.x)) + point.x, @as(f32, @floatFromInt(vine_object.y)) + point.y);
                    vine.points[real_index].anchored = true;
                }
            }
            vm.add_vine(vine);
        }

        return .{
            .collisions = try rect_collisions.toOwnedSlice(),
            .gm = gm,
            .vm = vm,
            .map = map,
            .tileset = rl.loadImage("assets/temp_tileset.png").toTexture(),
        };
    }

    pub fn draw(self: *Level) void {
        const tilesize = 16;
        for (self.map.layers) |layer| {
            for (layer.data, 0..) |tile, index| {
                const x = index % layer.width;
                const y = index / layer.width;

                const tileset_width = @as(u32, @intCast(self.tileset.width)) / tilesize;
                const src_x: f32 = @floatFromInt(tile % tileset_width);
                const src_y: f32 = @floatFromInt(tile / tileset_width);
                rl.drawTexturePro(
                    self.tileset,
                    rl.Rectangle.init((src_x - 1) * tilesize, src_y * tilesize, tilesize, tilesize),
                    rl.Rectangle.init(@floatFromInt(x * tilesize), @floatFromInt(y * tilesize), tilesize, tilesize),
                    rl.Vector2.init(0, 0),
                    0,
                    rl.Color.white,
                );
            }
        }
    }
};
