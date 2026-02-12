//===-- WORUYUInstrFormats.td - WORUYU Instruction Formats -------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

class WORUYUOpClass<bits<3> val> {
  bits<3> Value = val;
}

def WORUYU_LD    : WORUYUOpClass<0x0>;
def WORUYU_LDX   : WORUYUOpClass<0x1>;
def WORUYU_ST    : WORUYUOpClass<0x2>;
def WORUYU_STX   : WORUYUOpClass<0x3>;
def WORUYU_ALU   : WORUYUOpClass<0x4>;
def WORUYU_JMP   : WORUYUOpClass<0x5>;
def WORUYU_JMP32 : WORUYUOpClass<0x6>;
def WORUYU_ALU64 : WORUYUOpClass<0x7>;

class WORUYUSrcType<bits<1> val> {
  bits<1> Value = val;
}

def WORUYU_K : WORUYUSrcType<0x0>;
def WORUYU_X : WORUYUSrcType<0x1>;

class WORUYUArithOp<bits<4> val> {
  bits<4> Value = val;
}

def WORUYU_ADD  : WORUYUArithOp<0x0>;
def WORUYU_SUB  : WORUYUArithOp<0x1>;
def WORUYU_MUL  : WORUYUArithOp<0x2>;
def WORUYU_DIV  : WORUYUArithOp<0x3>;
def WORUYU_OR   : WORUYUArithOp<0x4>;
def WORUYU_AND  : WORUYUArithOp<0x5>;
def WORUYU_LSH  : WORUYUArithOp<0x6>;
def WORUYU_RSH  : WORUYUArithOp<0x7>;
def WORUYU_NEG  : WORUYUArithOp<0x8>;
def WORUYU_MOD  : WORUYUArithOp<0x9>;
def WORUYU_XOR  : WORUYUArithOp<0xa>;
def WORUYU_MOV  : WORUYUArithOp<0xb>;
def WORUYU_ARSH : WORUYUArithOp<0xc>;
def WORUYU_END  : WORUYUArithOp<0xd>;

def WORUYU_XCHG    : WORUYUArithOp<0xe>;
def WORUYU_CMPXCHG : WORUYUArithOp<0xf>;

class WORUYUAtomicOp<bits<5> val> {
  bits<5> Value = val;
}

def WORUYU_LOAD_ACQ : WORUYUAtomicOp<0x10>;
def WORUYU_STORE_REL : WORUYUAtomicOp<0x11>;

class WORUYUEndDir<bits<1> val> {
  bits<1> Value = val;
}

def WORUYU_TO_LE : WORUYUSrcType<0x0>;
def WORUYU_TO_BE : WORUYUSrcType<0x1>;

class WORUYUJumpOp<bits<4> val> {
  bits<4> Value = val;
}

def WORUYU_JA   : WORUYUJumpOp<0x0>;
def WORUYU_JEQ  : WORUYUJumpOp<0x1>;
def WORUYU_JGT  : WORUYUJumpOp<0x2>;
def WORUYU_JGE  : WORUYUJumpOp<0x3>;
def WORUYU_JSET : WORUYUJumpOp<0x4>;
def WORUYU_JNE  : WORUYUJumpOp<0x5>;
def WORUYU_JSGT : WORUYUJumpOp<0x6>;
def WORUYU_JSGE : WORUYUJumpOp<0x7>;
def WORUYU_CALL : WORUYUJumpOp<0x8>;
def WORUYU_EXIT : WORUYUJumpOp<0x9>;
def WORUYU_JLT  : WORUYUJumpOp<0xa>;
def WORUYU_JLE  : WORUYUJumpOp<0xb>;
def WORUYU_JSLT : WORUYUJumpOp<0xc>;
def WORUYU_JSLE : WORUYUJumpOp<0xd>;
def WORUYU_JCOND : WORUYUJumpOp<0xe>;

class WORUYUWidthModifer<bits<2> val> {
  bits<2> Value = val;
}

def WORUYU_W  : WORUYUWidthModifer<0x0>;
def WORUYU_H  : WORUYUWidthModifer<0x1>;
def WORUYU_B  : WORUYUWidthModifer<0x2>;
def WORUYU_DW : WORUYUWidthModifer<0x3>;

class WORUYUModeModifer<bits<3> val> {
  bits<3> Value = val;
}

def WORUYU_IMM  : WORUYUModeModifer<0x0>;
def WORUYU_ABS  : WORUYUModeModifer<0x1>;
def WORUYU_IND  : WORUYUModeModifer<0x2>;
def WORUYU_MEM  : WORUYUModeModifer<0x3>;
def WORUYU_MEMSX  : WORUYUModeModifer<0x4>;
def WORUYU_ATOMIC : WORUYUModeModifer<0x6>;

class WORUYUAtomicFlag<bits<4> val> {
  bits<4> Value = val;
}

def WORUYU_FETCH : WORUYUAtomicFlag<0x1>;

class InstWORUYU<dag outs, dag ins, string asmstr, list<dag> pattern>
  : Instruction {
  field bits<64> Inst;
  let Size = 8;

  let Namespace = "WORUYU";
  let DecoderNamespace = "WORUYU";

  WORUYUOpClass WORUYUClass;
  let Inst{58-56} = WORUYUClass.Value;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

// Pseudo instructions
class Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstWORUYU<outs, ins, asmstr, pattern> {
  let Inst{63-0} = 0;
  let isPseudo = 1;
}
