const rl = @import("raylib");
const std = @import("std");
const tmx = @import("tmx.zig");

const screen_width = 800;
const screen_height = 450;
const render_width = 400;
const render_height = 225;

fn update() void {}
fn draw(render_target: rl.RenderTexture2D) void {
    const bg_color = rl.Color.init(0x30, 0x23, 0x3a, 0xff);

    // drawing within this texture to ensure consistent resolution
    // (render_width) x (render_height)
    // we will use this texture also as the texture we pass to the GPU
    rl.beginTextureMode(render_target);

    rl.drawText("Congrats! You created your first window!", 30, 170, 18, rl.Color.light_gray);

    rl.endTextureMode();

    rl.beginDrawing();
    rl.clearBackground(bg_color);

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

    rl.setTargetFPS(60);
    const target = rl.loadRenderTexture(render_width, render_height);
    while (!rl.windowShouldClose()) {
        update();
        draw(target);
    }

    rl.unloadTexture(target.texture);
}
