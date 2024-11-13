const rl = @import("raylib");
const tmx = @import("tmx.zig");

pub const Player = struct {
    position: rl.Vector2,

    pub fn init() Player {
        return .{
            .position = rl.Vector2.init(0, 0),
        };
    }

    pub fn Draw(self: Player) void {
        rl.drawRectangle(
            @intFromFloat(self.position.x),
            @intFromFloat(self.position.y),
            16,
            16,
            rl.Color.green,
        );
    }

    pub fn get_collision_rect(self: Player) rl.Rectangle {
        return rl.Rectangle.init(self.position.x, self.position.y, 16, 16);
    }

    pub fn Update(self: *Player, collision_group: *tmx.ObjectIterator) void {
        const SPEED: f32 = 2.5;
        self.position.y += SPEED;

        while (collision_group.next()) |object| {
            const object_rect = object.to_rect();
            if (object_rect.checkCollision(self.get_collision_rect())) {
                self.position.y = object_rect.y - 16;
            }
        }

        collision_group.reset();
        if (rl.isKeyDown(rl.KeyboardKey.key_d)) {
            self.position.x += SPEED;
            while (collision_group.next()) |object| {
                const object_rect = object.to_rect();
                if (object_rect.checkCollision(self.get_collision_rect())) {
                    self.position.x = object_rect.x - 16;
                }
            }
        }

        collision_group.reset();
        if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
            self.position.x -= SPEED;
            while (collision_group.next()) |object| {
                const object_rect = object.to_rect();
                if (object_rect.checkCollision(self.get_collision_rect())) {
                    self.position.x = object_rect.x + object_rect.width;
                }
            }
        }

        collision_group.reset();
        if (rl.isKeyPressed(rl.KeyboardKey.key_w)) {
            self.position.y -= SPEED * 5;
            while (collision_group.next()) |object| {
                const object_rect = object.to_rect();
                if (object_rect.checkCollision(self.get_collision_rect())) {
                    self.position.y = object_rect.y + object_rect.height + 16;
                }
            }
        }
    }
};
