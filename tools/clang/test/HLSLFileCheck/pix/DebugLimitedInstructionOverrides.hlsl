// The PIX debug instrumentation pass takes optional arguments that limit the range of instruction numbers that will be instrumented.
// (This is to cope with extremely large shaders, the instrumentation of which will break, either by out-of-memory or by TDRing when run.)

// RUN: %dxc -EFlowControlPS -Tps_6_0 %s | %opt -S -dxil-annotate-with-virtual-regs -hlsl-dxil-debug-instrumentation,FirstInstruction=6,LastInstruction=9 | %FileCheck %s

// The only instrumented instructions should have instruction numbers in the range [6,9):
// CHECK: call void @dx.op.bufferStore.i32(i32 69, %dx.types.Handle %PIX_DebugUAV_Handle, {{.*}}, i32 undef, i32 6
// CHECK: call void @dx.op.bufferStore.i32(i32 69, %dx.types.Handle %PIX_DebugUAV_Handle, {{.*}}, i32 undef, i32 7
// CHECK: call void @dx.op.bufferStore.i32(i32 69, %dx.types.Handle %PIX_DebugUAV_Handle, {{.*}}, i32 undef, i32 8

// Two more stores to finish off the instrumentation for instruction #8:
// CHECK: call void @dx.op.bufferStore.f32
// CHECK: call void @dx.op.bufferStore.i32

// Then no more instrumentation at all:
// CHECK-NOT: call void @dx.op.bufferStore.i32(i32 69, %dx.types.Handle %PIX_DebugUAV_Handle

struct VS_OUTPUT_ENV {
  float4 Pos : SV_Position;
  float2 Tex : TEXCOORD0;
};

int i32;
float f32;

float4 Vectorize(float f) {
  float4 ret;

  if (f < 1024) // testbreakpoint0
    ret.x = f;
  else
    ret.x = f + 100;

  if (f < 512)
    ret.y = f;
  else
    ret.y = f + 10;

  if (f < 2048)
    ret.z = f;
  else
    ret.z = f + 1000;

  if (f < 4096)
    ret.w = f + f;
  else
    ret.w = f + 1;

  return ret;
}

float4 FlowControlPS(VS_OUTPUT_ENV input) : SV_Target {
  float4 ret = {0, 0, 0, 1}; // FirstExecutableLine
  switch (i32) {
  case 0:
    ret = float4(1, 0, 1, 1);
    break;
  case 32:
    ret = Vectorize(f32);
    break;
  }

  if (i32 > 10) {
    ret.r += 0.1f;
  } else {
    ret.g += 0.1f;
  }

  for (uint i = 0; i < 3; ++i) // testbreakpoint1
  {
    ret.b += f32 / 1024.f;
  }

  for (uint j = 0; j < i32 / 8; ++j) {
    ret.b += f32 / 1000.f;
  }

  return ret; // LastExecutableLine
}
