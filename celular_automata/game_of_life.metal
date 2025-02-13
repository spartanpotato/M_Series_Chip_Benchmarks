#include <metal_stdlib>
using namespace metal;

kernel void game_of_life(
    device const uint8_t *input [[buffer(0)]],
    device uint8_t *output [[buffer(1)]],
    device const uint2 *gridSize [[buffer(2)]],
    device const int *stencilRadius [[buffer(3)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint width = gridSize->x;
    uint height = gridSize->y;
    int radius = *stencilRadius;

    if (gid.x >= width || gid.y >= height) {
        return;
    }

    // Load the current cell
    uint index = gid.y * width + gid.x;
    uint8_t currentState = input[index];

    // Initialize liveNeighbors, but REMOVE the unnecessary conditional
    int liveNeighbors = -currentState;

    // Use UNROLLED LOOPS to increase memory throughput
    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            int nx = (gid.x + dx + width) % width;
            int ny = (gid.y + dy + height) % height;
            liveNeighbors += input[ny * width + nx];
        }
    }

    // **Branch-Free Computation**
    output[index] = (liveNeighbors == 3) || (currentState && liveNeighbors == 2);
}
