//===-- WORUYUMCTargetDesc.cpp - WORUYU Target Descriptions ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides WORUYU specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/WORUYUMCTargetDesc.h"
#include "MCTargetDesc/WORUYUInstPrinter.h"
#include "MCTargetDesc/WORUYUMCAsmInfo.h"
#include "TargetInfo/WORUYUTargetInfo.h"
#include "llvm/MC/MCInstrAnalysis.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Host.h"

#define GET_INSTRINFO_MC_DESC
#define ENABLE_INSTR_PREDICATE_VERIFIER
#include "WORUYUGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "WORUYUGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "WORUYUGenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createWORUYUMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitWORUYUMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createWORUYUMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitWORUYUMCRegisterInfo(X, WORUYU::R11 /* RAReg doesn't exist */);
  return X;
}

static MCSubtargetInfo *createWORUYUMCSubtargetInfo(const Triple &TT,
                                                 StringRef CPU, StringRef FS) {
  return createWORUYUMCSubtargetInfoImpl(TT, CPU, /*TuneCPU*/ CPU, FS);
}

static MCStreamer *
createWORUYUMCStreamer(const Triple &T, MCContext &Ctx,
                    std::unique_ptr<MCAsmBackend> &&MAB,
                    std::unique_ptr<MCObjectWriter> &&OW,
                    std::unique_ptr<MCCodeEmitter> &&Emitter) {
  return createELFStreamer(Ctx, std::move(MAB), std::move(OW),
                           std::move(Emitter));
}

static MCInstPrinter *createWORUYUMCInstPrinter(const Triple &T,
                                             unsigned SyntaxVariant,
                                             const MCAsmInfo &MAI,
                                             const MCInstrInfo &MII,
                                             const MCRegisterInfo &MRI) {
  if (SyntaxVariant == 0)
    return new WORUYUInstPrinter(MAI, MII, MRI);
  return nullptr;
}

namespace {

class WORUYUMCInstrAnalysis : public MCInstrAnalysis {
public:
  explicit WORUYUMCInstrAnalysis(const MCInstrInfo *Info)
      : MCInstrAnalysis(Info) {}

  bool evaluateBranch(const MCInst &Inst, uint64_t Addr, uint64_t Size,
                      uint64_t &Target) const override {
    // The target is the 3rd operand of cond inst and the 1st of uncond inst.
    int32_t Imm;
    if (isConditionalBranch(Inst)) {
      if (Inst.getOpcode() == WORUYU::JCOND)
        Imm = (short)Inst.getOperand(0).getImm();
      else
        Imm = (short)Inst.getOperand(2).getImm();
    } else if (isUnconditionalBranch(Inst)) {
      if (Inst.getOpcode() == WORUYU::JMP)
        Imm = (short)Inst.getOperand(0).getImm();
      else
        Imm = (int)Inst.getOperand(0).getImm();
    } else
      return false;

    Target = Addr + Size + Imm * Size;
    return true;
  }
};

} // end anonymous namespace

static MCInstrAnalysis *createWORUYUInstrAnalysis(const MCInstrInfo *Info) {
  return new WORUYUMCInstrAnalysis(Info);
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeWORUYUTargetMC() {
  for (Target *T :
       {&getTheWORUYUleTarget(), &getTheWORUYUbeTarget(), &getTheWORUYUTarget()}) {
    // Register the MC asm info.
    RegisterMCAsmInfo<WORUYUMCAsmInfo> X(*T);

    // Register the MC instruction info.
    TargetRegistry::RegisterMCInstrInfo(*T, createWORUYUMCInstrInfo);

    // Register the MC register info.
    TargetRegistry::RegisterMCRegInfo(*T, createWORUYUMCRegisterInfo);

    // Register the MC subtarget info.
    TargetRegistry::RegisterMCSubtargetInfo(*T,
                                            createWORUYUMCSubtargetInfo);

    // Register the object streamer
    TargetRegistry::RegisterELFStreamer(*T, createWORUYUMCStreamer);

    // Register the MCInstPrinter.
    TargetRegistry::RegisterMCInstPrinter(*T, createWORUYUMCInstPrinter);

    // Register the MC instruction analyzer.
    TargetRegistry::RegisterMCInstrAnalysis(*T, createWORUYUInstrAnalysis);
  }

  // Register the MC code emitter
  TargetRegistry::RegisterMCCodeEmitter(getTheWORUYUleTarget(),
                                        createWORUYUMCCodeEmitter);
  TargetRegistry::RegisterMCCodeEmitter(getTheWORUYUbeTarget(),
                                        createWORUYUbeMCCodeEmitter);

  // Register the ASM Backend
  TargetRegistry::RegisterMCAsmBackend(getTheWORUYUleTarget(),
                                       createWORUYUAsmBackend);
  TargetRegistry::RegisterMCAsmBackend(getTheWORUYUbeTarget(),
                                       createWORUYUbeAsmBackend);

  if (sys::IsLittleEndianHost) {
    TargetRegistry::RegisterMCCodeEmitter(getTheWORUYUTarget(),
                                          createWORUYUMCCodeEmitter);
    TargetRegistry::RegisterMCAsmBackend(getTheWORUYUTarget(),
                                         createWORUYUAsmBackend);
  } else {
    TargetRegistry::RegisterMCCodeEmitter(getTheWORUYUTarget(),
                                          createWORUYUbeMCCodeEmitter);
    TargetRegistry::RegisterMCAsmBackend(getTheWORUYUTarget(),
                                         createWORUYUbeAsmBackend);
  }
}
