//===- IntrinsicsWORUYU.td - Defines WORUYU intrinsics -------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the WORUYU-specific intrinsics.
//
//===----------------------------------------------------------------------===//

// Specialized loads from packet
let TargetPrefix = "woruyu" in {  // All intrinsics start with "llvm.woruyu."
  def int_woruyu_fake: ClangBuiltin<"__builtin_woruyu_fake">,
              Intrinsic<[llvm_i64_ty], [llvm_ptr_ty], [IntrReadMem]>;
}