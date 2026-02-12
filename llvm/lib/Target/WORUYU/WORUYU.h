//===-- WORUYU.h - Top-level interface for WORUYU representation ------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WORUYU_WORUYU_H
#define LLVM_LIB_TARGET_WORUYU_WORUYU_H

#include "MCTargetDesc/WORUYUMCTargetDesc.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class WORUYURegisterBankInfo;
class WORUYUSubtarget;
class WORUYUTargetMachine;
class InstructionSelector;
class PassRegistry;

#define WORUYU_TRAP "__woruyu_trap"

FunctionPass *createWORUYUISelDag(WORUYUTargetMachine &TM);

InstructionSelector *createWORUYUInstructionSelector(const WORUYUTargetMachine &,
                                                  const WORUYUSubtarget &,
                                                  const WORUYURegisterBankInfo &);

void initializeWORUYUAsmPrinterPass(PassRegistry &);
void initializeWORUYUDAGToDAGISelLegacyPass(PassRegistry &);


} // namespace llvm

#endif
