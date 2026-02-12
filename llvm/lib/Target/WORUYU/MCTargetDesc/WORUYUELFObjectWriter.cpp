//===-- WORUYUELFObjectWriter.cpp - WORUYU ELF Writer ---------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/WORUYUMCTargetDesc.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Support/ErrorHandling.h"
#include <cstdint>

using namespace llvm;

namespace {

class WORUYUELFObjectWriter : public MCELFObjectTargetWriter {
public:
  WORUYUELFObjectWriter(uint8_t OSABI);
  ~WORUYUELFObjectWriter() override = default;

protected:
  unsigned getRelocType(const MCFixup &, const MCValue &,
                        bool IsPCRel) const override;
};

} // end anonymous namespace

WORUYUELFObjectWriter::WORUYUELFObjectWriter(uint8_t OSABI)
    : MCELFObjectTargetWriter(/*Is64Bit*/ true, OSABI, ELF::EM_WORUYU,
                              /*HasRelocationAddend*/ false) {}

unsigned WORUYUELFObjectWriter::getRelocType(const MCFixup &Fixup,
                                          const MCValue &Target,
                                          bool IsPCRel) const {
  // determine the type of the relocation
  switch (Fixup.getKind()) {
  default:
    llvm_unreachable("invalid fixup kind!");
  case FK_SecRel_8:
    // LD_imm64 instruction.
    return ELF::R_WORUYU_64_64;
  case FK_Data_8:
    return ELF::R_WORUYU_64_ABS64;
  case FK_Data_4:
    if (Fixup.isPCRel()) // CALL instruction
      return ELF::R_WORUYU_64_32;
    if (const auto *A = Target.getAddSym()) {
      const MCSymbol &Sym = *A;

      if (Sym.isDefined()) {
        auto &Section = static_cast<const MCSectionELF &>(Sym.getSection());
        unsigned Flags = Section.getFlags();

        if (Sym.isTemporary()) {
          // .BTF.ext generates FK_Data_4 relocations for
          // insn offset by creating temporary labels.
          // The reloc symbol should be in text section.
          // Use a different relocation to instruct ExecutionEngine
          // RuntimeDyld not to do relocation for it, yet still to
          // allow lld to do proper adjustment when merging sections.
          if ((Flags & ELF::SHF_ALLOC) && (Flags & ELF::SHF_EXECINSTR))
            return ELF::R_WORUYU_64_NODYLD32;
        } else {
          // .BTF generates FK_Data_4 relocations for variable
          // offset in DataSec kind.
          // The reloc symbol should be in data section.
          if ((Flags & ELF::SHF_ALLOC) && (Flags & ELF::SHF_WRITE))
            return ELF::R_WORUYU_64_NODYLD32;
        }
      }
    }
    return ELF::R_WORUYU_64_ABS32;
  }
}

std::unique_ptr<MCObjectTargetWriter>
llvm::createWORUYUELFObjectWriter(uint8_t OSABI) {
  return std::make_unique<WORUYUELFObjectWriter>(OSABI);
}
