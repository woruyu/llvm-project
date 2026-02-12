//===-- WORUYUFrameLowering.h - Define frame lowering for WORUYU -----*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WORUYU_WORUYUASMPRINTER_H
#define LLVM_LIB_TARGET_WORUYU_WORUYUASMPRINTER_H

#include "WORUYUTargetMachine.h"
#include "llvm/CodeGen/AsmPrinter.h"

namespace llvm {

class WORUYUAsmPrinter : public AsmPrinter {
public:
  explicit WORUYUAsmPrinter(TargetMachine &TM,
                         std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer), ID), TM(TM) {}

  StringRef getPassName() const override { return "WORUYU Assembly Printer"; }
  bool doInitialization(Module &M) override;
  bool doFinalization(Module &M) override;
  void printOperand(const MachineInstr *MI, int OpNum, raw_ostream &O);
  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       const char *ExtraCode, raw_ostream &O) override;
  bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNum,
                             const char *ExtraCode, raw_ostream &O) override;

  void emitInstruction(const MachineInstr *MI) override;
  MCSymbol *getJTPublicSymbol(unsigned JTI);
  void emitJumpTableInfo() override;

  static char ID;

private:
  TargetMachine &TM;
  bool SawTrapCall = false;
};

} // namespace llvm

#endif /* LLVM_LIB_TARGET_WORUYU_WORUYUASMPRINTER_H */
