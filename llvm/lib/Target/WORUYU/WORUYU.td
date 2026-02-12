//===-- WORUYU.td - Describe the WORUYU Target Machine -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

include "WORUYURegisterInfo.td"
include "WORUYUCallingConv.td"
include "WORUYUInstrInfo.td"


defm : RemapAllTargetPseudoPointerOperands<GPR>;

def WORUYUInstrInfo : InstrInfo;

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def DummyFeature : SubtargetFeature<"dummy", "isDummyMode",
                                    "true", "unused feature">;

def ALU32 : SubtargetFeature<"alu32", "HasAlu32", "true",
                             "Enable ALU32 instructions">;

def DwarfRIS: SubtargetFeature<"dwarfris", "UseDwarfRIS", "true",
                               "Disable MCAsmInfo DwarfUsesRelocationsAcrossSections">;

def MisalignedMemAccess : SubtargetFeature<"allows-misaligned-mem-access",
                                           "AllowsMisalignedMemAccess", "true",
                                           "Allows misaligned memory access">;

def : Proc<"generic", []>;
def : Proc<"v1", []>;
def : Proc<"v2", []>;
def : Proc<"v3", [ALU32]>;
def : Proc<"v4", [ALU32]>;
def : Proc<"probe", []>;

def WORUYUInstPrinter : AsmWriter {
  string AsmWriterClassName  = "InstPrinter";
  bit isMCAsmWriter = 1;
}

def WORUYUAsmParser : AsmParser {
  bit HasMnemonicFirst = 0;
}

def WORUYUAsmParserVariant : AsmParserVariant {
  int Variant = 0;
  string Name = "WORUYU";
  string BreakCharacters = ".";
  string TokenizingCharacters = "#()[]=:.<>!+*%/";
}

def WORUYU : Target {
  let InstructionSet = WORUYUInstrInfo;
  let AssemblyWriters = [WORUYUInstPrinter];
  let AssemblyParsers = [WORUYUAsmParser];
  let AssemblyParserVariants = [WORUYUAsmParserVariant];
}
