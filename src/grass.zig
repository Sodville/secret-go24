const rl = @import("raylib");
const std = @import("std");

const util = @import("util.zig");
const math = std.math;

pub const Grass = struct {
    x: u32,
    y: u32,

    rotation: f32,
    base_rotation: f32,

    pub fn init(x: u32, y: u32, base_rotation: f32) Grass {
        return .{
            .x = x,
            .y = y,
            .base_rotation = base_rotation,
            .rotation = 0,
        };
    }

    pub fn update(self: *Grass, rotation: f32) void {
        self.rotation = self.base_rotation + rotation;
    }
};

pub const GrassManager = struct {
    grass: [10240]Grass = undefined,
    global_rotation: f32,

    len: u16,

    sprite_textures: rl.Texture,
    num_sprites: i32,

    pub fn init() GrassManager {
        const img = rl.loadImage("assets/sprites/grass/grass.png").toTexture();
        return .{
            .global_rotation = 0,
            .len = 0,
            .sprite_textures = img,
            .num_sprites = @divFloor(img.width, img.height),
        };
    }

    pub fn apply_force(self: *GrassManager, x: u32, y: u32) void {
        _ = self; // autofix
        _ = x; // autofix
        _ = y; // autofix
    }

    pub fn add_grass(self: *GrassManager, grass: Grass) void {
        self.grass[self.len] = grass;
        self.len += 1;
    }

    pub fn update(self: *GrassManager, t: f32) void {
        for (0..self.len) |i| {
            var grass: *Grass = &self.grass[i];
            const rot_offset: f32 = @floatFromInt(grass.x);
            const e = util.ease_in_out_elastic(math.sin((t - rot_offset) / 100));
            const rot = (e) * 55;
            grass.update(rot + math.sin((t - rot_offset) / 45) * 15);
        }
    }

    pub fn draw(self: *GrassManager) void {
        const individual_texture_width: f32 = @floatFromInt(self.sprite_textures.height);

        for (0..self.len) |i| {
            const grass: Grass = self.grass[i];
            const i_f32: f32 = @floatFromInt(i);
            self.sprite_textures.drawPro(
                rl.Rectangle.init(i_f32 * individual_texture_width, 0, individual_texture_width, individual_texture_width),
                rl.Rectangle.init(@floatFromInt(grass.x), @floatFromInt(grass.y), individual_texture_width, individual_texture_width),
                rl.Vector2.init(individual_texture_width / 2, individual_texture_width / 2),
                grass.rotation,
                rl.Color.white,
            );
        }
    }
};
