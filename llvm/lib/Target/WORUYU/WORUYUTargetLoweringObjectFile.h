//===============-  WORUYUTargetLoweringObjectFile.h  -*- C++ -*-================//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WORUYU_WORUYUTARGETLOWERINGOBJECTFILE
#define LLVM_LIB_TARGET_WORUYU_WORUYUTARGETLOWERINGOBJECTFILE

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

namespace llvm {
class WORUYUTargetLoweringObjectFileELF : public TargetLoweringObjectFileELF {

public:
  MCSection *
  getSectionForJumpTable(const Function &F, const TargetMachine &TM,
                         const MachineJumpTableEntry *JTE) const override;
};
} // namespace llvm

#endif // LLVM_LIB_TARGET_WORUYU_WORUYUTARGETLOWERINGOBJECTFILE
