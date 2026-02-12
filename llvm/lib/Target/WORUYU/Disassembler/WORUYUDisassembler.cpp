//===- WORUYUDisassembler.cpp - Disassembler for WORUYU ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is part of the WORUYU Disassembler.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/WORUYUMCTargetDesc.h"
#include "TargetInfo/WORUYUTargetInfo.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDecoder.h"
#include "llvm/MC/MCDecoderOps.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/TargetParser/SubtargetFeature.h"
#include <cstdint>

using namespace llvm;
using namespace llvm::MCD;

#define DEBUG_TYPE "WORUYU-disassembler"

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {

/// A disassembler class for WORUYU.
class WORUYUDisassembler : public MCDisassembler {
public:
  enum WORUYU_CLASS {
    WORUYU_LD = 0x0,
    WORUYU_LDX = 0x1,
    WORUYU_ST = 0x2,
    WORUYU_STX = 0x3,
    WORUYU_ALU = 0x4,
    WORUYU_JMP = 0x5,
    WORUYU_JMP32 = 0x6,
    WORUYU_ALU64 = 0x7
  };

  enum WORUYU_SIZE {
    WORUYU_W = 0x0,
    WORUYU_H = 0x1,
    WORUYU_B = 0x2,
    WORUYU_DW = 0x3
  };

  enum WORUYU_MODE {
    WORUYU_IMM = 0x0,
    WORUYU_ABS = 0x1,
    WORUYU_IND = 0x2,
    WORUYU_MEM = 0x3,
    WORUYU_MEMSX = 0x4,
    WORUYU_ATOMIC = 0x6
  };

  WORUYUDisassembler(const MCSubtargetInfo &STI, MCContext &Ctx)
      : MCDisassembler(STI, Ctx) {}
  ~WORUYUDisassembler() override = default;

  DecodeStatus getInstruction(MCInst &Instr, uint64_t &Size,
                              ArrayRef<uint8_t> Bytes, uint64_t Address,
                              raw_ostream &CStream) const override;

  uint8_t getInstClass(uint64_t Inst) const { return (Inst >> 56) & 0x7; };
  uint8_t getInstSize(uint64_t Inst) const { return (Inst >> 59) & 0x3; };
  uint8_t getInstMode(uint64_t Inst) const { return (Inst >> 61) & 0x7; };
};

} // end anonymous namespace

static MCDisassembler *createWORUYUDisassembler(const Target &T,
                                             const MCSubtargetInfo &STI,
                                             MCContext &Ctx) {
  return new WORUYUDisassembler(STI, Ctx);
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeWORUYUDisassembler() {
  // Register the disassembler.
  TargetRegistry::RegisterMCDisassembler(getTheWORUYUTarget(),
                                         createWORUYUDisassembler);
  TargetRegistry::RegisterMCDisassembler(getTheWORUYUleTarget(),
                                         createWORUYUDisassembler);
  TargetRegistry::RegisterMCDisassembler(getTheWORUYUbeTarget(),
                                         createWORUYUDisassembler);
}

static const unsigned GPRDecoderTable[] = {
    WORUYU::R0,  WORUYU::R1,  WORUYU::R2,  WORUYU::R3,  WORUYU::R4,  WORUYU::R5,
    WORUYU::R6,  WORUYU::R7,  WORUYU::R8,  WORUYU::R9,  WORUYU::R10, WORUYU::R11};

static DecodeStatus DecodeGPRRegisterClass(MCInst &Inst, unsigned RegNo,
                                           uint64_t /*Address*/,
                                           const MCDisassembler * /*Decoder*/) {
  if (RegNo > 11)
    return MCDisassembler::Fail;

  unsigned Reg = GPRDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static const unsigned GPR32DecoderTable[] = {
    WORUYU::W0,  WORUYU::W1,  WORUYU::W2,  WORUYU::W3,  WORUYU::W4,  WORUYU::W5,
    WORUYU::W6,  WORUYU::W7,  WORUYU::W8,  WORUYU::W9,  WORUYU::W10, WORUYU::W11};

static DecodeStatus
DecodeGPR32RegisterClass(MCInst &Inst, unsigned RegNo, uint64_t /*Address*/,
                         const MCDisassembler * /*Decoder*/) {
  if (RegNo > 11)
    return MCDisassembler::Fail;

  unsigned Reg = GPR32DecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus decodeMemoryOpValue(MCInst &Inst, unsigned Insn,
                                        uint64_t Address,
                                        const MCDisassembler *Decoder) {
  unsigned Register = (Insn >> 16) & 0xf;
  if (Register > 11)
    return MCDisassembler::Fail;

  Inst.addOperand(MCOperand::createReg(GPRDecoderTable[Register]));
  unsigned Offset = (Insn & 0xffff);
  Inst.addOperand(MCOperand::createImm(SignExtend32<16>(Offset)));

  return MCDisassembler::Success;
}

#include "WORUYUGenDisassemblerTables.inc"
static DecodeStatus readInstruction64(ArrayRef<uint8_t> Bytes, uint64_t Address,
                                      uint64_t &Size, uint64_t &Insn,
                                      bool IsLittleEndian) {
  uint64_t Lo, Hi;

  if (Bytes.size() < 8) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  Size = 8;
  if (IsLittleEndian) {
    Hi = (Bytes[0] << 24) | (Bytes[1] << 16) | (Bytes[2] << 0) | (Bytes[3] << 8);
    Lo = (Bytes[4] << 0) | (Bytes[5] << 8) | (Bytes[6] << 16) | (Bytes[7] << 24);
  } else {
    Hi = (Bytes[0] << 24) | ((Bytes[1] & 0x0F) << 20) | ((Bytes[1] & 0xF0) << 12) |
         (Bytes[2] << 8) | (Bytes[3] << 0);
    Lo = (Bytes[4] << 24) | (Bytes[5] << 16) | (Bytes[6] << 8) | (Bytes[7] << 0);
  }
  Insn = Make_64(Hi, Lo);

  return MCDisassembler::Success;
}

DecodeStatus WORUYUDisassembler::getInstruction(MCInst &Instr, uint64_t &Size,
                                             ArrayRef<uint8_t> Bytes,
                                             uint64_t Address,
                                             raw_ostream &CStream) const {
  bool IsLittleEndian = getContext().getAsmInfo()->isLittleEndian();
  uint64_t Insn, Hi;
  DecodeStatus Result;

  Result = readInstruction64(Bytes, Address, Size, Insn, IsLittleEndian);
  if (Result == MCDisassembler::Fail) return MCDisassembler::Fail;

  uint8_t InstClass = getInstClass(Insn);
  uint8_t InstMode = getInstMode(Insn);
  if ((InstClass == WORUYU_LDX || InstClass == WORUYU_STX) &&
      getInstSize(Insn) != WORUYU_DW &&
      (InstMode == WORUYU_MEM || InstMode == WORUYU_ATOMIC) &&
      STI.hasFeature(WORUYU::ALU32))
    Result = decodeInstruction(DecoderTableWORUYUALU3264, Instr, Insn, Address,
                               this, STI);
  else
    Result = decodeInstruction(DecoderTableWORUYU64, Instr, Insn, Address, this,
                               STI);

  if (Result == MCDisassembler::Fail) return MCDisassembler::Fail;

  switch (Instr.getOpcode()) {
  case WORUYU::LD_imm64:
  case WORUYU::LD_pseudo: {
    if (Bytes.size() < 16) {
      Size = 0;
      return MCDisassembler::Fail;
    }
    Size = 16;
    if (IsLittleEndian)
      Hi = (Bytes[12] << 0) | (Bytes[13] << 8) | (Bytes[14] << 16) | (Bytes[15] << 24);
    else
      Hi = (Bytes[12] << 24) | (Bytes[13] << 16) | (Bytes[14] << 8) | (Bytes[15] << 0);
    auto& Op = Instr.getOperand(1);
    Op.setImm(Make_64(Hi, Op.getImm()));
    break;
  }
  }

  return Result;
}

typedef DecodeStatus (*DecodeFunc)(MCInst &MI, unsigned insn, uint64_t Address,
                                   const MCDisassembler *Decoder);
