const rl = @import("raylib");
const std = @import("std");
const tmx = @import("tmx.zig");
const lvl = @import("level.zig");
const grass = @import("grass.zig");
const vn = @import("vine.zig");

const screen_width = 800;
const screen_height = 450;
const render_width = 400;
const render_height = 225;

fn update() void {}
fn draw(render_target: rl.RenderTexture2D, level: *lvl.Level) void {
    const bg_color = rl.Color.init(0x30, 0x23, 0x3a, 0xff);

    // drawing within this texture to ensure consistent resolution
    // (render_width) x (render_height)
    // we will use this texture also as the texture we pass to the GPU
    rl.beginTextureMode(render_target);
    rl.clearBackground(bg_color);

    level.draw();

    // these manager should probably reside in the game struct.
    // and primarily be interacted with through it instead
    level.vm.draw();
    level.gm.draw();

    rl.endTextureMode();

    rl.beginDrawing();

    // we draw the texture and upscale it to the 'screen resolution'
    // NOTE: Render texture must be y-flipped due to default OpenGL coordinates (left-bottom).
    rl.drawTexturePro(
        render_target.texture,
        rl.Rectangle.init(0, 0, render_width, -render_height),
        rl.Rectangle.init(0, 0, screen_width, screen_height),
        rl.Vector2.init(0, 0),
        0,
        rl.Color.white,
    );
    rl.endDrawing();
}

pub fn main() !void {
    rl.initWindow(screen_width, screen_height, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();
    var gm = grass.GrassManager.init();
    var vm = vn.VineManager.init();
    var level = try lvl.Level.init("assets/untitled.tmx", &gm, &vm);

    rl.setTargetFPS(60);
    const target = rl.loadRenderTexture(render_width, render_height);
    var t: f32 = 0;
    while (!rl.windowShouldClose()) {
        update();
        gm.update(t);
        vm.update();
        draw(target, &level);

        t += 1;
    }

    rl.unloadTexture(target.texture);
}
