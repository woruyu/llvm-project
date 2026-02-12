//===-- WORUYUTargetInfo.cpp - WORUYU Target Implementation ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "TargetInfo/WORUYUTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

Target &llvm::getTheWORUYUleTarget() {
  static Target TheWORUYUleTarget;
  return TheWORUYUleTarget;
}
Target &llvm::getTheWORUYUbeTarget() {
  static Target TheWORUYUbeTarget;
  return TheWORUYUbeTarget;
}
Target &llvm::getTheWORUYUTarget() {
  static Target TheWORUYUTarget;
  return TheWORUYUTarget;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeWORUYUTargetInfo() {
  TargetRegistry::RegisterTarget(getTheWORUYUTarget(), "woruyu", "WORUYU (host endian)",
                                 "WORUYU", [](Triple::ArchType) { return false; },
                                 true);
  RegisterTarget<Triple::woruyuel, /*HasJIT=*/true> X(
      getTheWORUYUleTarget(), "woruyuel", "WORUYU (little endian)", "WORUYU");
  RegisterTarget<Triple::woruyueb, /*HasJIT=*/true> Y(getTheWORUYUbeTarget(), "woruyueb",
                                                   "WORUYU (big endian)", "WORUYU");
}
