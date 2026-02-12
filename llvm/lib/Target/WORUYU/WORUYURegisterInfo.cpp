//===-- WORUYURegisterInfo.cpp - WORUYU Register Information ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the WORUYU implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "WORUYURegisterInfo.h"
#include "WORUYUSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"

#define GET_REGINFO_TARGET_DESC
#include "WORUYUGenRegisterInfo.inc"
using namespace llvm;

static cl::opt<int>
    WORUYUStackSizeOption("WORUYU-stack-size",
                       cl::desc("Specify the WORUYU stack size limit"),
                       cl::init(512));

WORUYURegisterInfo::WORUYURegisterInfo()
    : WORUYUGenRegisterInfo(WORUYU::R0) {}

const MCPhysReg *
WORUYURegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_SaveList;
}

const uint32_t *
WORUYURegisterInfo::getCallPreservedMask(const MachineFunction &MF,
                                      CallingConv::ID CC) const {
  switch (CC) {
  default:
    return CSR_RegMask;
  case CallingConv::PreserveAll:
    return CSR_PreserveAll_RegMask;
  }
}

BitVector WORUYURegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  markSuperRegs(Reserved, WORUYU::W10); // [W|R]10 is read only frame pointer
  markSuperRegs(Reserved, WORUYU::W11); // [W|R]11 is pseudo stack pointer
  return Reserved;
}

static void WarnSize(int Offset, MachineFunction &MF, DebugLoc& DL,
                     MachineBasicBlock& MBB) {
  if (Offset <= -WORUYUStackSizeOption) {
    if (!DL)
      /* try harder to get some debug loc */
      for (auto &I : MBB)
        if (I.getDebugLoc()) {
          DL = I.getDebugLoc();
          break;
        }

    const Function &F = MF.getFunction();
    F.getContext().diagnose(DiagnosticInfoUnsupported(
        F,
        "Looks like the WORUYU stack limit is exceeded. "
        "Please move large on stack variables into WORUYU per-cpu array map. For "
        "non-kernel uses, the stack can be increased using -mllvm "
        "-WORUYU-stack-size.\n",
        DL));
  }
}

bool WORUYURegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                          int SPAdj, unsigned FIOperandNum,
                                          RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");

  unsigned i = 0;
  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  DebugLoc DL = MI.getDebugLoc();

  while (!MI.getOperand(i).isFI()) {
    ++i;
    assert(i < MI.getNumOperands() && "Instr doesn't have FrameIndex operand!");
  }

  Register FrameReg = getFrameRegister(MF);
  int FrameIndex = MI.getOperand(i).getIndex();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  if (MI.getOpcode() == WORUYU::MOV_rr) {
    int Offset = MF.getFrameInfo().getObjectOffset(FrameIndex);

    WarnSize(Offset, MF, DL, MBB);
    MI.getOperand(i).ChangeToRegister(FrameReg, false);
    Register reg = MI.getOperand(i - 1).getReg();
    BuildMI(MBB, ++II, DL, TII.get(WORUYU::ADD_ri), reg)
        .addReg(reg)
        .addImm(Offset);
    return false;
  }

  int Offset = MF.getFrameInfo().getObjectOffset(FrameIndex) +
               MI.getOperand(i + 1).getImm();

  if (!isInt<32>(Offset))
    llvm_unreachable("bug in frame offset");

  WarnSize(Offset, MF, DL, MBB);

  if (MI.getOpcode() == WORUYU::FI_ri) {
    // architecture does not really support FI_ri, replace it with
    //    MOV_rr <target_reg>, frame_reg
    //    ADD_ri <target_reg>, imm
    Register reg = MI.getOperand(i - 1).getReg();

    BuildMI(MBB, ++II, DL, TII.get(WORUYU::MOV_rr), reg)
        .addReg(FrameReg);
    BuildMI(MBB, II, DL, TII.get(WORUYU::ADD_ri), reg)
        .addReg(reg)
        .addImm(Offset);

    // Remove FI_ri instruction
    MI.eraseFromParent();
  } else {
    MI.getOperand(i).ChangeToRegister(FrameReg, false);
    MI.getOperand(i + 1).ChangeToImmediate(Offset);
  }
  return false;
}

Register WORUYURegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return WORUYU::R10;
}
