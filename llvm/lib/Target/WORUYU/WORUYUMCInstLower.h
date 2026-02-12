//===-- WORUYUMCInstLower.h - Lower MachineInstr to MCInst ---------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WORUYU_WORUYUMCINSTLOWER_H
#define LLVM_LIB_TARGET_WORUYU_WORUYUMCINSTLOWER_H

#include "llvm/Support/Compiler.h"

namespace llvm {
class WORUYUAsmPrinter;
class MCContext;
class MCInst;
class MCOperand;
class MCSymbol;
class MachineInstr;
class MachineOperand;

// WORUYUMCInstLower - This class is used to lower an MachineInstr into an MCInst.
class LLVM_LIBRARY_VISIBILITY WORUYUMCInstLower {
  MCContext &Ctx;

  WORUYUAsmPrinter &Printer;

public:
  WORUYUMCInstLower(MCContext &ctx, WORUYUAsmPrinter &printer)
      : Ctx(ctx), Printer(printer) {}
  void Lower(const MachineInstr *MI, MCInst &OutMI) const;

  MCOperand LowerSymbolOperand(const MachineOperand &MO, MCSymbol *Sym) const;

  MCSymbol *GetGlobalAddressSymbol(const MachineOperand &MO) const;
  MCSymbol *GetExternalSymbolSymbol(const MachineOperand &MO) const;
};
}

#endif
