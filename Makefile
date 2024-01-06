build:
	@zig build

build-debug:
	@zig build -Ddebug_msg=true

run:
	@zig build run -- test.md

run-debug:
	@zig build run -Ddebug_msg=true -- test.md

test:
	@zig test -femit-bin=zig-out/bin/test-binary src/main.zig
