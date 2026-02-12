//===-- WORUYUAsmPrinter.cpp - WORUYU LLVM assembly writer ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the WORUYU assembly language.
//
//===----------------------------------------------------------------------===//

#include "WORUYUAsmPrinter.h"
#include "WORUYU.h"
#include "WORUYUInstrInfo.h"
#include "WORUYUMCInstLower.h"
#include "MCTargetDesc/WORUYUInstPrinter.h"
#include "TargetInfo/WORUYUTargetInfo.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/TargetLowering.h"
#include "llvm/IR/Module.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCSymbolELF.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"

bool WORUYUAsmPrinter::doInitialization(Module &M) {
  AsmPrinter::doInitialization(M);
  return false;
}


bool WORUYUAsmPrinter::doFinalization(Module &M) {
  for (GlobalObject &GO : M.global_objects()) {
    if (!GO.hasExternalWeakLinkage())
      continue;

    if (!SawTrapCall && GO.getName() == WORUYU_TRAP) {
      GO.eraseFromParent();
      break;
    }
  }

  return AsmPrinter::doFinalization(M);
}

void WORUYUAsmPrinter::printOperand(const MachineInstr *MI, int OpNum,
                                 raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand(OpNum);

  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << WORUYUInstPrinter::getRegisterName(MO.getReg());
    break;

  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    break;

  case MachineOperand::MO_MachineBasicBlock:
    O << *MO.getMBB()->getSymbol();
    break;

  case MachineOperand::MO_GlobalAddress:
    O << *getSymbol(MO.getGlobal());
    break;

  case MachineOperand::MO_BlockAddress: {
    MCSymbol *BA = GetBlockAddressSymbol(MO.getBlockAddress());
    O << BA->getName();
    break;
  }

  case MachineOperand::MO_ExternalSymbol:
    O << *GetExternalSymbolSymbol(MO.getSymbolName());
    break;

  case MachineOperand::MO_JumpTableIndex:
  case MachineOperand::MO_ConstantPoolIndex:
  default:
    llvm_unreachable("<unknown operand type>");
  }
}

bool WORUYUAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                    const char *ExtraCode, raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return AsmPrinter::PrintAsmOperand(MI, OpNo, ExtraCode, O);

  printOperand(MI, OpNo, O);
  return false;
}

bool WORUYUAsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                          unsigned OpNum, const char *ExtraCode,
                                          raw_ostream &O) {
  assert(OpNum + 1 < MI->getNumOperands() && "Insufficient operands");
  const MachineOperand &BaseMO = MI->getOperand(OpNum);
  const MachineOperand &OffsetMO = MI->getOperand(OpNum + 1);
  assert(BaseMO.isReg() && "Unexpected base pointer for inline asm memory operand.");
  assert(OffsetMO.isImm() && "Unexpected offset for inline asm memory operand.");
  int Offset = OffsetMO.getImm();

  if (ExtraCode)
    return true; // Unknown modifier.

  if (Offset < 0)
    O << "(" << WORUYUInstPrinter::getRegisterName(BaseMO.getReg()) << " - " << -Offset << ")";
  else
    O << "(" << WORUYUInstPrinter::getRegisterName(BaseMO.getReg()) << " + " << Offset << ")";

  return false;
}

void WORUYUAsmPrinter::emitInstruction(const MachineInstr *MI) {
  if (MI->isCall()) {
    for (const MachineOperand &Op : MI->operands()) {
      if (Op.isGlobal()) {
        if (const GlobalValue *GV = Op.getGlobal())
          if (GV->getName() == WORUYU_TRAP)
            SawTrapCall = true;
      }
    }
  }

  WORUYU_MC::verifyInstructionPredicates(MI->getOpcode(),
                                      getSubtargetInfo().getFeatureBits());

  MCInst TmpInst;

  
  WORUYUMCInstLower MCInstLowering(OutContext, *this);
  MCInstLowering.Lower(MI, TmpInst);
  
  EmitToStreamer(*OutStreamer, TmpInst);
}

MCSymbol *WORUYUAsmPrinter::getJTPublicSymbol(unsigned JTI) {
  SmallString<60> Name;
  raw_svector_ostream(Name)
      << "WORUYU.JT." << MF->getFunctionNumber() << '.' << JTI;
  MCSymbol *S = OutContext.getOrCreateSymbol(Name);
  if (auto *ES = static_cast<MCSymbolELF *>(S)) {
    ES->setBinding(ELF::STB_GLOBAL);
    ES->setType(ELF::STT_OBJECT);
  }
  return S;
}

void WORUYUAsmPrinter::emitJumpTableInfo() {
  const MachineJumpTableInfo *MJTI = MF->getJumpTableInfo();
  if (!MJTI)
    return;

  const std::vector<MachineJumpTableEntry> &JT = MJTI->getJumpTables();
  if (JT.empty())
    return;

  const TargetLoweringObjectFile &TLOF = getObjFileLowering();
  const Function &F = MF->getFunction();

  MCSection *Sec = OutStreamer->getCurrentSectionOnly();
  MCSymbol *SecStart = Sec->getBeginSymbol();

  MCSection *JTS = TLOF.getSectionForJumpTable(F, TM);
  assert(MJTI->getEntryKind() == MachineJumpTableInfo::EK_BlockAddress);
  unsigned EntrySize = MJTI->getEntrySize(getDataLayout());
  OutStreamer->switchSection(JTS);
  for (unsigned JTI = 0; JTI < JT.size(); JTI++) {
    ArrayRef<MachineBasicBlock *> JTBBs = JT[JTI].MBBs;
    if (JTBBs.empty())
      continue;

    MCSymbol *JTStart = getJTPublicSymbol(JTI);
    OutStreamer->emitLabel(JTStart);
    for (const MachineBasicBlock *MBB : JTBBs) {
      const MCExpr *Diff = MCBinaryExpr::createSub(
          MCSymbolRefExpr::create(MBB->getSymbol(), OutContext),
          MCSymbolRefExpr::create(SecStart, OutContext), OutContext);
      OutStreamer->emitValue(Diff, EntrySize);
    }
    const MCExpr *JTSize =
        MCConstantExpr::create(JTBBs.size() * EntrySize, OutContext);
    OutStreamer->emitELFSize(JTStart, JTSize);
  }
}

char WORUYUAsmPrinter::ID = 0;

INITIALIZE_PASS(WORUYUAsmPrinter, "WORUYU-asm-printer", "WORUYU Assembly Printer", false,
                false)

// Force static initialization.
extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeWORUYUAsmPrinter() {
  RegisterAsmPrinter<WORUYUAsmPrinter> X(getTheWORUYUleTarget());
  RegisterAsmPrinter<WORUYUAsmPrinter> Y(getTheWORUYUbeTarget());
  RegisterAsmPrinter<WORUYUAsmPrinter> Z(getTheWORUYUTarget());
}
