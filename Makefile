build:
	zig build

run:
	zig build run -- test.md

test:
	zig test -femit-bin=zig-out/bin/test-binary src/main.zig