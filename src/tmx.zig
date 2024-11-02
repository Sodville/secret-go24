const std = @import("std");
const xml = @import("xml.zig");

// this entire file can be refactored in the future to use more type reflection
// definatly possible to do some magic metaprogramming to build these types 'easier'
//
// might not be better or easier, but it will look cooler!

pub const Layer = struct {
    id: u8 = 0,
    name: []u8 = "",
    width: u8 = 0,
    height: u8 = 0,
    data: []u64 = &.{},

    tilewidth: u8 = 0,
    tileheight: u8 = 0,
    tiles: []Tile = undefined,

    fn prepare_tiles(self: *Layer, allocator: *const std.mem.Allocator, tile_width: u8, tile_height: u8) ![]Tile {
        var arr = std.ArrayList(Tile).init(allocator.*);
        defer arr.deinit();
        for (self.data, 0..self.data.len) |id, index| {
            const index_u32: u32 = @intCast(index);
            const y: u32 = @as(u32, index_u32 / self.width);
            const x: u32 = @as(u32, index_u32 % self.width);
            _ = try arr.append(.{
                .x = x * tile_width,
                .y = y * tile_height,
                .width = tile_width,
                .height = tile_height,
                .id = id,
            });
        }

        const slice = try arr.toOwnedSlice();
        return slice;
    }
};

pub const Object = struct {
    id: u8 = 0,
    x: u32 = 0,
    y: u32 = 0,
    height: ?u32 = 0,
    width: ?u32 = 0,
};

pub const ObjectGroup = struct {
    id: u8 = 0,
    name: []u8 = "",
    objects: []Object = &.{},
};

pub const ObjectIterator = struct {
    items: []Object,
    group: *ObjectGroup,
    i: usize,

    pub fn next(self: *ObjectIterator) ?*Object {
        if (self.i < self.items.len) {
            self.i += 1;
            return &self.items[self.i - 1];
        }

        return null;
    }
};

pub const Map = struct {
    width: u8 = 0,
    height: u8 = 0,
    tilewidth: u8 = 0,
    tileheight: u8 = 0,
    layers: []Layer = &.{},
    object_groups: []ObjectGroup = &.{},

    allocator: *const std.mem.Allocator,

    pub fn get_objects_by_group_name(self: *const Map, group_name: []const u8) ?ObjectIterator {
        for (self.object_groups, 0..self.object_groups.len) |group, index| {
            if (std.mem.eql(u8, group.name, group_name)) {
                return .{
                    .items = group.objects,
                    .i = 0,
                    .group = &self.object_groups[index],
                };
            }
        }
        return null;
    }
};

pub const Tile = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    id: u64,
};

fn check_attr(tag: *xml.Element, name: []const u8) ?[]const u8 {
    return tag.getAttribute(name) orelse return null;
}

fn parse_attr_u8(tag: *xml.Element, name: []const u8) !u8 {
    return std.fmt.parseInt(u8, tag.getAttribute(name).?, 10);
}

fn remove_newlines(slice: []const u8) []const u8 {
    var buf: [64]u8 = undefined;
    var i: usize = 0;

    for (slice) |char| {
        if (char != '\n') {
            buf[i] = char;
            i += 1;
        }
    }
    return buf[0..i];
}

fn clean_slice(slice: []const u8) []const u8 {
    var buf: [64]u8 = undefined;
    var i: usize = 0;

    for (slice) |char| {
        if (char >= '0' and char <= '9') {
            buf[i] = char;
            i += 1;
        }
    }
    return buf[0..i];
}

pub fn load_map(path: []const u8) !Map {
    const allocator = std.heap.page_allocator;
    var map = Map{ .allocator = &allocator };

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const file_len = try file.getEndPos();

    var file_buff = try allocator.alloc(u8, file_len);
    _ = try file.readAll(file_buff);

    const doc = try xml.parse(allocator, file_buff[0..file_len]);
    defer doc.deinit();

    const map_tag = doc.root;

    map.width = try parse_attr_u8(map_tag, "width");
    map.height = try parse_attr_u8(map_tag, "height");

    map.tilewidth = try parse_attr_u8(map_tag, "tilewidth");
    map.tileheight = try parse_attr_u8(map_tag, "tileheight");

    var layer_tags = map_tag.findChildrenByTag("layer");

    var layers = std.ArrayList(Layer).init(allocator);
    defer layers.deinit();

    while (layer_tags.next()) |layer_tag| {
        var layer = Layer{};
        const name = layer_tag.getAttribute("name") orelse "";

        layer.id = try parse_attr_u8(layer_tag, "id");
        layer.height = try parse_attr_u8(layer_tag, "height");
        layer.width = try parse_attr_u8(layer_tag, "width");

        layer.name = try allocator.alloc(u8, name.len);
        @memcpy(layer.name, name);

        const data = layer_tag.getCharData("data") orelse "";

        var it = std.mem.split(u8, data, ",");
        var datas = std.ArrayList(u64).init(allocator);
        defer datas.deinit();
        while (it.next()) |val| {
            const clean = clean_slice(val);
            const s = try std.fmt.parseInt(u64, clean, 10);
            _ = try datas.append(s);
        }

        layer.data = try datas.toOwnedSlice();
        layer.tiles = try layer.prepare_tiles(&allocator, map.tilewidth, map.tileheight);

        _ = try layers.append(layer);
    }

    var object_groups_tags = map_tag.findChildrenByTag("objectgroup");

    var object_groups = std.ArrayList(ObjectGroup).init(allocator);
    defer object_groups.deinit();

    while (object_groups_tags.next()) |object_group_tag| {
        var object_group = ObjectGroup{};

        const name = object_group_tag.getAttribute("name") orelse "";
        object_group.id = try parse_attr_u8(object_group_tag, "id");

        object_group.name = try allocator.alloc(u8, name.len);
        @memcpy(object_group.name, name);

        var objects = std.ArrayList(Object).init(allocator);
        defer objects.deinit();

        var copy = object_group_tag.elements();
        while (copy.next()) |child| {
            var object = Object{};
            object.id = try parse_attr_u8(child, "id");

            const x = check_attr(child, "x");
            if (x != null) {
                object.x = try std.fmt.parseInt(u32, x.?, 10);
            }
            const y = check_attr(child, "y");
            if (y != null) {
                object.y = try std.fmt.parseInt(u32, y.?, 10);
            }

            const width = check_attr(child, "width");
            if (width != null) {
                object.width = @intFromFloat(try std.fmt.parseFloat(f32, width.?));
            }
            const height = check_attr(child, "height");
            if (height != null) {
                object.height = @intFromFloat(try std.fmt.parseFloat(f32, height.?));
            }

            _ = try objects.append(object);
        }

        object_group.objects = try objects.toOwnedSlice();
        _ = try object_groups.append(object_group);
    }

    map.layers = try layers.toOwnedSlice();
    map.object_groups = try object_groups.toOwnedSlice();
    return map;
}
