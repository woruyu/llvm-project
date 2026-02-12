//===-- WORUYUFrameLowering.cpp - WORUYU Frame Information ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the WORUYU implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "WORUYUFrameLowering.h"
#include "WORUYUSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"

using namespace llvm;

bool WORUYUFrameLowering::hasFPImpl(const MachineFunction &MF) const {
  return true;
}

void WORUYUFrameLowering::emitPrologue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {}

void WORUYUFrameLowering::emitEpilogue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {}

void WORUYUFrameLowering::determineCalleeSaves(MachineFunction &MF,
                                            BitVector &SavedRegs,
                                            RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);
  SavedRegs.reset(WORUYU::R6);
  SavedRegs.reset(WORUYU::R7);
  SavedRegs.reset(WORUYU::R8);
  SavedRegs.reset(WORUYU::R9);
}
