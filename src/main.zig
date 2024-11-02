const rl = @import("raylib");

fn update() void {}
fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();
}

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        update();
        draw();

        rl.clearBackground(rl.Color.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
    }
}
