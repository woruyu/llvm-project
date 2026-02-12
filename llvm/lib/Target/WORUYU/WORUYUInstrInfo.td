//===-- WORUYUInstrInfo.td - Target Description for WORUYU Target ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the WORUYU instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "WORUYUInstrFormats.td"

// Instruction Operands and Patterns

// These are target-independent nodes, but have target-specific formats.
def SDT_WORUYUCallSeqStart : SDCallSeqStart<[SDTCisVT<0, iPTR>,
                                          SDTCisVT<1, iPTR>]>;
def SDT_WORUYUCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, iPTR>, SDTCisVT<1, iPTR>]>;
def SDT_WORUYUCall         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_WORUYUSetFlag      : SDTypeProfile<0, 3, [SDTCisSameAs<0, 1>]>;
def SDT_WORUYUSelectCC     : SDTypeProfile<1, 5, [SDTCisSameAs<1, 2>,
                                               SDTCisSameAs<0, 4>,
                                               SDTCisSameAs<4, 5>]>;
def SDT_WORUYUBrCC         : SDTypeProfile<0, 4, [SDTCisSameAs<0, 1>,
                                               SDTCisVT<3, OtherVT>]>;
def SDT_WORUYUWrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                               SDTCisPtrTy<0>]>;
def SDT_WORUYUMEMCPY       : SDTypeProfile<0, 4, [SDTCisVT<0, i64>,
                                               SDTCisVT<1, i64>,
                                               SDTCisVT<2, i64>,
                                               SDTCisVT<3, i64>]>;

def WORUYUcall         : SDNode<"WORUYUISD::CALL", SDT_WORUYUCall,
                             [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                              SDNPVariadic]>;
def WORUYUretglue      : SDNode<"WORUYUISD::RET_GLUE", SDTNone,
                             [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;
def WORUYUcallseq_start: SDNode<"ISD::CALLSEQ_START", SDT_WORUYUCallSeqStart,
                             [SDNPHasChain, SDNPOutGlue]>;
def WORUYUcallseq_end  : SDNode<"ISD::CALLSEQ_END",   SDT_WORUYUCallSeqEnd,
                             [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def WORUYUbrcc         : SDNode<"WORUYUISD::BR_CC", SDT_WORUYUBrCC, [SDNPHasChain]>;

def WORUYUselectcc     : SDNode<"WORUYUISD::SELECT_CC", SDT_WORUYUSelectCC>;
def WORUYUWrapper      : SDNode<"WORUYUISD::Wrapper", SDT_WORUYUWrapper>;
def WORUYUmemcpy       : SDNode<"WORUYUISD::MEMCPY", SDT_WORUYUMEMCPY,
                             [SDNPHasChain, SDNPMayStore, SDNPMayLoad]>;
def WORUYUIsLittleEndian : Predicate<"Subtarget->isLittleEndian()">;
def WORUYUIsBigEndian    : Predicate<"!Subtarget->isLittleEndian()">;
def WORUYUHasALU32 : Predicate<"Subtarget->getHasAlu32()">;
def WORUYUNoALU32 : Predicate<"!Subtarget->getHasAlu32()">;
def WORUYUHasLdsx : Predicate<"Subtarget->hasLdsx()">;
def WORUYUHasMovsx : Predicate<"Subtarget->hasMovsx()">;
def WORUYUHasBswap : Predicate<"Subtarget->hasBswap()">;
def WORUYUHasSdivSmod : Predicate<"Subtarget->hasSdivSmod()">;
def WORUYUNoMovsx : Predicate<"!Subtarget->hasMovsx()">;
def WORUYUNoBswap : Predicate<"!Subtarget->hasBswap()">;
def WORUYUHasStoreImm : Predicate<"Subtarget->hasStoreImm()">;
def WORUYUHasLoadAcqStoreRel : Predicate<"Subtarget->hasLoadAcqStoreRel()">;
def WORUYUHasGotox : Predicate<"Subtarget->hasGotox()">;

class ImmediateAsmOperand<string name> : AsmOperandClass {
  let Name = name;
  let RenderMethod = "addImmOperands";
  let DiagnosticType = !strconcat("Invalid", name);
}

def SImm16AsmOperand : ImmediateAsmOperand<"SImm16">;

def brtarget : Operand<OtherVT> {
  let PrintMethod = "printBrTargetOperand";
  let ParserMatchClass = ImmediateAsmOperand<"BrTarget">;
}
def calltarget : Operand<i64>;

def u64imm   : Operand<i64> {
  let PrintMethod = "printImm64Operand";
}

def s16imm : Operand<i16> {
  let ParserMatchClass = SImm16AsmOperand;
}

def gpr_or_imm : Operand<i64>;

def i64immSExt32 : PatLeaf<(i64 imm),
                [{return isInt<32>(N->getSExtValue()); }]>;
def i32immSExt32 : PatLeaf<(i32 imm),
                [{return isInt<32>(N->getSExtValue()); }]>;
def i64immZExt32 : PatLeaf<(i64 imm),
                [{return isUInt<32>(N->getZExtValue()); }]>;

def imm_to_i64 : SDNodeXForm<timm, [{
  return CurDAG->getTargetConstant(N->getZExtValue(), SDLoc(N), MVT::i64);
}]>;

// Addressing modes.
def ADDRri : ComplexPattern<i64, 2, "SelectAddr", [], []>;
def FIri : ComplexPattern<i64, 2, "SelectFIAddr", [add, or], []>;

// Address operands
def MEMri : Operand<i64> {
  let PrintMethod = "printMemOperand";
  let EncoderMethod = "getMemoryOpValue";
  let DecoderMethod = "decodeMemoryOpValue";
  let MIOperandInfo = (ops GPR, s16imm);
}

// Conditional code predicates - used for pattern matching for jump instructions
def WORUYU_CC_EQ  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETEQ);}]>;
def WORUYU_CC_NE  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETNE);}]>;
def WORUYU_CC_GE  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETGE);}]>;
def WORUYU_CC_GT  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETGT);}]>;
def WORUYU_CC_GTU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETUGT);}]>;
def WORUYU_CC_GEU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETUGE);}]>;
def WORUYU_CC_LE  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETLE);}]>;
def WORUYU_CC_LT  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETLT);}]>;
def WORUYU_CC_LTU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETULT);}]>;
def WORUYU_CC_LEU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETULE);}]>;
def WORUYU_CC_EQ_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETEQ);}]>;
def WORUYU_CC_NE_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETNE);}]>;
def WORUYU_CC_GE_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETGE);}]>;
def WORUYU_CC_GT_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETGT);}]>;
def WORUYU_CC_GTU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETUGT);}]>;
def WORUYU_CC_GEU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETUGE);}]>;
def WORUYU_CC_LE_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETLE);}]>;
def WORUYU_CC_LT_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETLT);}]>;
def WORUYU_CC_LTU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETULT);}]>;
def WORUYU_CC_LEU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETULE);}]>;
def NoCond : PatLeaf<(vt)> {}

// For arithmetic and jump instructions the 8-bit 'code'
// field is divided into three parts:
//
//  +----------------+--------+--------------------+
//  |   4 bits       |  1 bit |   3 bits           |
//  | operation code | source | instruction class  |
//  +----------------+--------+--------------------+
//  (MSB)                                      (LSB)
class TYPE_ALU_JMP<bits<4> op, bits<1> srctype,
                   dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstWORUYU<outs, ins, asmstr, pattern> {

  let Inst{63-60} = op;
  let Inst{59} = srctype;
}

//For load and store instructions the 8-bit 'code' field is divided as:
//
//  +--------+--------+-------------------+
//  | 3 bits | 2 bits |   3 bits          |
//  |  mode  |  size  | instruction class |
//  +--------+--------+-------------------+
//  (MSB)                             (LSB)
class TYPE_LD_ST<bits<3> mode, bits<2> size,
                 dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstWORUYU<outs, ins, asmstr, pattern> {

  let Inst{63-61} = mode;
  let Inst{60-59} = size;
}

// jump instructions
class JMP_RR<WORUYUJumpOp Opc, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_X.Value,
                   (outs),
                   (ins GPR:$dst, GPR:$src, brtarget:$BrDst),
                   "if $dst "#OpcodeStr#" $src goto $BrDst",
                   [(WORUYUbrcc i64:$dst, i64:$src, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<4> src;
  bits<16> BrDst;

  let Inst{55-52} = src;
  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let WORUYUClass = WORUYU_JMP;
}

class JMP_RI<WORUYUJumpOp Opc, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_K.Value,
                   (outs),
                   (ins GPR:$dst, i64imm:$imm, brtarget:$BrDst),
                   "if $dst "#OpcodeStr#" $imm goto $BrDst",
                   [(WORUYUbrcc i64:$dst, i64immSExt32:$imm, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<16> BrDst;
  bits<32> imm;

  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let Inst{31-0} = imm;
  let WORUYUClass = WORUYU_JMP;
}

class JMP_IND<WORUYUJumpOp Opc, string OpcodeStr, list<dag> Pattern>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_X.Value,
                   (outs),
                   (ins GPR:$dst),
                   !strconcat(OpcodeStr, " $dst"),
                   Pattern> {
  bits<4> dst;

  let Inst{51-48} = dst;
  let WORUYUClass = WORUYU_JMP;
}

class JMP_JCOND<WORUYUJumpOp Opc, string OpcodeStr, list<dag> Pattern>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_K.Value,
                   (outs),
                   (ins brtarget:$BrDst),
                   !strconcat(OpcodeStr, " $BrDst"),
                   Pattern> {
  bits<16> BrDst;

  let Inst{47-32} = BrDst;
  let WORUYUClass = WORUYU_JMP;
}

class JMP_RR_32<WORUYUJumpOp Opc, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_X.Value,
                   (outs),
                   (ins GPR32:$dst, GPR32:$src, brtarget:$BrDst),
                   "if $dst "#OpcodeStr#" $src goto $BrDst",
                   [(WORUYUbrcc i32:$dst, i32:$src, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<4> src;
  bits<16> BrDst;

  let Inst{55-52} = src;
  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let WORUYUClass = WORUYU_JMP32;
}

class JMP_RI_32<WORUYUJumpOp Opc, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_K.Value,
                   (outs),
                   (ins GPR32:$dst, i32imm:$imm, brtarget:$BrDst),
                   "if $dst "#OpcodeStr#" $imm goto $BrDst",
                   [(WORUYUbrcc i32:$dst, i32immSExt32:$imm, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<16> BrDst;
  bits<32> imm;

  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let Inst{31-0} = imm;
  let WORUYUClass = WORUYU_JMP32;
}

multiclass J<WORUYUJumpOp Opc, string OpcodeStr, PatLeaf Cond, PatLeaf Cond32> {
  def _rr : JMP_RR<Opc, OpcodeStr, Cond>;
  def _ri : JMP_RI<Opc, OpcodeStr, Cond>;
  def _rr_32 : JMP_RR_32<Opc, OpcodeStr, Cond32>;
  def _ri_32 : JMP_RI_32<Opc, OpcodeStr, Cond32>;
}

let isBranch = 1, isTerminator = 1, hasDelaySlot=0 in {
// cmp+goto instructions
defm JEQ  : J<WORUYU_JEQ, "==",  WORUYU_CC_EQ, WORUYU_CC_EQ_32>;
defm JUGT : J<WORUYU_JGT, ">", WORUYU_CC_GTU, WORUYU_CC_GTU_32>;
defm JUGE : J<WORUYU_JGE, ">=", WORUYU_CC_GEU, WORUYU_CC_GEU_32>;
defm JNE  : J<WORUYU_JNE, "!=",  WORUYU_CC_NE, WORUYU_CC_NE_32>;
defm JSGT : J<WORUYU_JSGT, "s>", WORUYU_CC_GT, WORUYU_CC_GT_32>;
defm JSGE : J<WORUYU_JSGE, "s>=", WORUYU_CC_GE, WORUYU_CC_GE_32>;
defm JULT : J<WORUYU_JLT, "<", WORUYU_CC_LTU, WORUYU_CC_LTU_32>;
defm JULE : J<WORUYU_JLE, "<=", WORUYU_CC_LEU, WORUYU_CC_LEU_32>;
defm JSLT : J<WORUYU_JSLT, "s<", WORUYU_CC_LT, WORUYU_CC_LT_32>;
defm JSLE : J<WORUYU_JSLE, "s<=", WORUYU_CC_LE, WORUYU_CC_LE_32>;
defm JSET : J<WORUYU_JSET, "&", NoCond, NoCond>;
def JCOND : JMP_JCOND<WORUYU_JCOND, "may_goto", []>;

let Predicates = [WORUYUHasGotox] in {
  let isIndirectBranch = 1, isBarrier = 1 in {
    def JX : JMP_IND<WORUYU_JA, "gotox", [(brind i64:$dst)]>;
  }
}
}

// ALU instructions
class ALU_RI<WORUYUOpClass Class, WORUYUArithOp Opc, int off,
             dag outs, dag ins, string asmstr, list<dag> pattern>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_K.Value, outs, ins, asmstr, pattern> {
  bits<4> dst;
  bits<32> imm;

  let Inst{51-48} = dst;
  let Inst{47-32} = off;
  let Inst{31-0} = imm;
  let WORUYUClass = Class;
}

class ALU_RR<WORUYUOpClass Class, WORUYUArithOp Opc, int off,
             dag outs, dag ins, string asmstr, list<dag> pattern>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_X.Value, outs, ins, asmstr, pattern> {
  bits<4> dst;
  bits<4> src;

  let Inst{55-52} = src;
  let Inst{51-48} = dst;
  let Inst{47-32} = off;
  let WORUYUClass = Class;
}

multiclass ALU<WORUYUArithOp Opc, int off, string OpcodeStr, SDNode OpNode> {
  def _rr : ALU_RR<WORUYU_ALU64, Opc, off,
                   (outs GPR:$dst),
                   (ins GPR:$src2, GPR:$src),
                   "$dst "#OpcodeStr#" $src",
                   [(set GPR:$dst, (OpNode i64:$src2, i64:$src))]>;
  def _ri : ALU_RI<WORUYU_ALU64, Opc, off,
                   (outs GPR:$dst),
                   (ins GPR:$src2, i64imm:$imm),
                   "$dst "#OpcodeStr#" $imm",
                   [(set GPR:$dst, (OpNode GPR:$src2, i64immSExt32:$imm))]>;
  def _rr_32 : ALU_RR<WORUYU_ALU, Opc, off,
                   (outs GPR32:$dst),
                   (ins GPR32:$src2, GPR32:$src),
                   "$dst "#OpcodeStr#" $src",
                   [(set GPR32:$dst, (OpNode i32:$src2, i32:$src))]>;
  def _ri_32 : ALU_RI<WORUYU_ALU, Opc, off,
                   (outs GPR32:$dst),
                   (ins GPR32:$src2, i32imm:$imm),
                   "$dst "#OpcodeStr#" $imm",
                   [(set GPR32:$dst, (OpNode GPR32:$src2, i32immSExt32:$imm))]>;
}

let Constraints = "$dst = $src2" in {
let isAsCheapAsAMove = 1 in {
  defm ADD : ALU<WORUYU_ADD, 0, "+=", add>;
  defm SUB : ALU<WORUYU_SUB, 0, "-=", sub>;
  defm OR  : ALU<WORUYU_OR, 0, "|=", or>;
  defm AND : ALU<WORUYU_AND, 0, "&=", and>;
  defm SLL : ALU<WORUYU_LSH, 0, "<<=", shl>;
  defm SRL : ALU<WORUYU_RSH, 0, ">>=", srl>;
  defm XOR : ALU<WORUYU_XOR, 0, "^=", xor>;
  defm SRA : ALU<WORUYU_ARSH, 0, "s>>=", sra>;
}
  defm MUL : ALU<WORUYU_MUL, 0, "*=", mul>;
  defm DIV : ALU<WORUYU_DIV, 0, "/=", udiv>;
  defm MOD : ALU<WORUYU_MOD, 0, "%=", urem>;

  let Predicates = [WORUYUHasSdivSmod] in {
    defm SDIV : ALU<WORUYU_DIV, 1, "s/=", sdiv>;
    defm SMOD : ALU<WORUYU_MOD, 1, "s%=", srem>;
  }
}

class NEG_RR<WORUYUOpClass Class, WORUYUArithOp Opc,
             dag outs, dag ins, string asmstr, list<dag> pattern>
    : TYPE_ALU_JMP<Opc.Value, 0, outs, ins, asmstr, pattern> {
  bits<4> dst;

  let Inst{51-48} = dst;
  let WORUYUClass = Class;
}

let Constraints = "$dst = $src", isAsCheapAsAMove = 1 in {
  def NEG_64: NEG_RR<WORUYU_ALU64, WORUYU_NEG, (outs GPR:$dst), (ins GPR:$src),
                     "$dst = -$src",
                     [(set GPR:$dst, (ineg i64:$src))]>;
  def NEG_32: NEG_RR<WORUYU_ALU, WORUYU_NEG, (outs GPR32:$dst), (ins GPR32:$src),
                     "$dst = -$src",
                     [(set GPR32:$dst, (ineg i32:$src))]>;
}

class LD_IMM64<bits<4> Pseudo, string OpcodeStr>
    : TYPE_LD_ST<WORUYU_IMM.Value, WORUYU_DW.Value,
                 (outs GPR:$dst),
                 (ins u64imm:$imm),
                 "$dst "#OpcodeStr#" ${imm} ll",
                 [(set GPR:$dst, (i64 imm:$imm))]> {

  bits<4> dst;
  bits<64> imm;

  let Inst{51-48} = dst;
  let Inst{55-52} = Pseudo;
  let Inst{47-32} = 0;
  let Inst{31-0} = imm{31-0};
  let WORUYUClass = WORUYU_LD;
}

let isReMaterializable = 1, isAsCheapAsAMove = 1 in {
def LD_imm64 : LD_IMM64<0, "=">;
def MOV_rr : ALU_RR<WORUYU_ALU64, WORUYU_MOV, 0,
                    (outs GPR:$dst),
                    (ins GPR:$src),
                    "$dst = $src",
                    []>;
def MOV_ri : ALU_RI<WORUYU_ALU64, WORUYU_MOV, 0,
                    (outs GPR:$dst),
                    (ins i64imm:$imm),
                    "$dst = $imm",
                    [(set GPR:$dst, (i64 i64immSExt32:$imm))]>;
def MOV_rr_32 : ALU_RR<WORUYU_ALU, WORUYU_MOV, 0,
                    (outs GPR32:$dst),
                    (ins GPR32:$src),
                    "$dst = $src",
                    []>;
def MOV_ri_32 : ALU_RI<WORUYU_ALU, WORUYU_MOV, 0,
                    (outs GPR32:$dst),
                    (ins i32imm:$imm),
                    "$dst = $imm",
                    [(set GPR32:$dst, (i32 i32immSExt32:$imm))]>;

let Predicates = [WORUYUHasMovsx] in {
  def MOVSX_rr_8 : ALU_RR<WORUYU_ALU64, WORUYU_MOV, 8,
                      (outs GPR:$dst), (ins GPR:$src),
                      "$dst = (s8)$src",
                      [(set GPR:$dst, (sext_inreg GPR:$src, i8))]>;
  def MOVSX_rr_16 : ALU_RR<WORUYU_ALU64, WORUYU_MOV, 16,
                      (outs GPR:$dst), (ins GPR:$src),
                      "$dst = (s16)$src",
                      [(set GPR:$dst, (sext_inreg GPR:$src, i16))]>;
  def MOVSX_rr_32 : ALU_RR<WORUYU_ALU64, WORUYU_MOV, 32,
                      (outs GPR:$dst), (ins GPR:$src),
                      "$dst = (s32)$src",
                      [(set GPR:$dst, (sext_inreg GPR:$src, i32))]>;
  def MOVSX_rr_32_8 : ALU_RR<WORUYU_ALU, WORUYU_MOV, 8,
                      (outs GPR32:$dst), (ins GPR32:$src),
                      "$dst = (s8)$src",
                      [(set GPR32:$dst, (sext_inreg GPR32:$src, i8))]>;
  def MOVSX_rr_32_16 : ALU_RR<WORUYU_ALU, WORUYU_MOV, 16,
                      (outs GPR32:$dst), (ins GPR32:$src),
                      "$dst = (s16)$src",
                      [(set GPR32:$dst, (sext_inreg GPR32:$src, i16))]>;
}
}

def ADDR_SPACE_CAST
    : ALU_RR<WORUYU_ALU64, WORUYU_MOV, 64,
             (outs GPR:$dst),
             (ins GPR:$src, i64imm:$dst_as, i64imm:$src_as),
             "$dst = addr_space_cast($src, $dst_as, $src_as)",
             []> {
  bits<64> dst_as;
  bits<64> src_as;

  let Inst{47-32} = 1;
  let Inst{31-16} = dst_as{15-0};
  let Inst{15-0} = src_as{15-0};
}

def SrcAddrSpace : SDNodeXForm<addrspacecast, [{
  return CurDAG->getTargetConstant(
    cast<AddrSpaceCastSDNode>(N)->getSrcAddressSpace(),
    SDLoc(N), MVT::i64);
}]>;

def DstAddrSpace : SDNodeXForm<addrspacecast, [{
  return CurDAG->getTargetConstant(
    cast<AddrSpaceCastSDNode>(N)->getDestAddressSpace(),
    SDLoc(N), MVT::i64);
}]>;

def : Pat<(addrspacecast:$this GPR:$src),
          (ADDR_SPACE_CAST $src, (DstAddrSpace $this), (SrcAddrSpace $this))>;

def FI_ri
    : TYPE_LD_ST<WORUYU_IMM.Value, WORUYU_DW.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr),
                 "lea\t$dst, $addr",
                 [(set i64:$dst, FIri:$addr)]> {
  // This is a tentative instruction, and will be replaced
  // with MOV_rr and ADD_ri in PEI phase
  let Inst{51-48} = 0;
  let Inst{55-52} = 2;
  let Inst{47-32} = 0;
  let Inst{31-0} = 0;
  let WORUYUClass = WORUYU_LD;
  bit isPseudo = true;
}

def LD_pseudo
    : TYPE_LD_ST<WORUYU_IMM.Value, WORUYU_DW.Value,
                 (outs GPR:$dst),
                 (ins i64imm:$pseudo, u64imm:$imm),
                 "ld_pseudo\t$dst, $pseudo, $imm",
                 []> {

  bits<4> dst;
  bits<64> imm;
  bits<4> pseudo;

  let Inst{51-48} = dst;
  let Inst{55-52} = pseudo;
  let Inst{47-32} = 0;
  let Inst{31-0} = imm{31-0};
  let WORUYUClass = WORUYU_LD;
}

// STORE instructions
class STORE<WORUYUWidthModifer SizeOp, string OpcodeStr, list<dag> Pattern>
    : TYPE_LD_ST<WORUYU_MEM.Value, SizeOp.Value,
                 (outs),
                 (ins GPR:$src, MEMri:$addr),
                 "*("#OpcodeStr#" *)($addr) = $src",
                 Pattern> {
  bits<4> src;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = src;
  let Inst{47-32} = addr{15-0}; // offset
  let WORUYUClass = WORUYU_STX;
}

class STOREi64<WORUYUWidthModifer Opc, string OpcodeStr, PatFrag OpNode>
    : STORE<Opc, OpcodeStr, [(OpNode GPR:$src, ADDRri:$addr)]>;

let Predicates = [WORUYUNoALU32] in {
  def STW : STOREi64<WORUYU_W, "u32", truncstorei32>;
  def STH : STOREi64<WORUYU_H, "u16", truncstorei16>;
  def STB : STOREi64<WORUYU_B, "u8", truncstorei8>;
}
def STD : STOREi64<WORUYU_DW, "u64", store>;

class STORE_imm<WORUYUWidthModifer SizeOp,
                string OpcodeStr, dag Pattern>
    : TYPE_LD_ST<WORUYU_MEM.Value, SizeOp.Value,
                 (outs),
                 (ins i64imm:$imm, MEMri:$addr),
                 "*("#OpcodeStr#" *)($addr) = $imm",
                 [Pattern]> {
  bits<20> addr;
  bits<32> imm;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{47-32} = addr{15-0};  // offset
  let Inst{31-0} = imm;
  let WORUYUClass = WORUYU_ST;
}

let Predicates = [WORUYUHasStoreImm] in {
  // Opcode (WORUYU_ST | WORUYU_MEM | WORUYU_DW) implies sign extension for
  // value stored to memory:
  // - it is fine to generate such write when immediate is -1
  // - it is incorrect to generate such write when immediate is
  //   +0xffff_ffff.
  //
  // In the latter case two instructions would be generated instead of
  // one WORUYU_ST:
  //   rA = 0xffffffff ll     ; LD_imm64
  //   *(u64 *)(rB + 0) = rA  ; STX
  //
  // For WORUYU_{B,H,W} the size of value stored matches size of the immediate.
  def STD_imm : STORE_imm<WORUYU_DW, "u64", (store         (i64 i64immSExt32:$imm), ADDRri:$addr)>;
  def STW_imm : STORE_imm<WORUYU_W,  "u32", (truncstorei32 (i64 i64immZExt32:$imm), ADDRri:$addr)>;
  def STH_imm : STORE_imm<WORUYU_H,  "u16", (truncstorei16 (i64 i64immZExt32:$imm), ADDRri:$addr)>;
  def STB_imm : STORE_imm<WORUYU_B,  "u8",  (truncstorei8  (i64 i64immZExt32:$imm), ADDRri:$addr)>;
}

let Predicates = [WORUYUHasALU32, WORUYUHasStoreImm] in {
  def : Pat<(store (i32 imm:$src), ADDRri:$dst),
            (STW_imm (imm_to_i64 $src), ADDRri:$dst)>;
  def : Pat<(truncstorei16 (i32 imm:$src), ADDRri:$dst),
            (STH_imm (imm_to_i64 imm:$src), ADDRri:$dst)>;
  def : Pat<(truncstorei8 (i32 imm:$src), ADDRri:$dst),
            (STB_imm (imm_to_i64 imm:$src), ADDRri:$dst)>;
}

class STORE_RELEASE<WORUYUWidthModifer SizeOp, string OpcodeStr, RegisterClass RegTp>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs),
                 (ins RegTp:$src, MEMri:$addr),
                 "store_release(("#OpcodeStr#" *)($addr), $src)",
                 []> {
  bits<4> src;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = src;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{8-4} = WORUYU_STORE_REL.Value;
  let WORUYUClass = WORUYU_STX;
}

class STORE_RELEASEi64<WORUYUWidthModifer Opc, string OpcodeStr>
    : STORE_RELEASE<Opc, OpcodeStr, GPR>;

class relaxed_store<PatFrag base>
  : PatFrag<(ops node:$val, node:$ptr), (base node:$val, node:$ptr)> {
  let IsAtomic = 1;
  let IsAtomicOrderingReleaseOrStronger = 0;
}

class releasing_store<PatFrag base>
  : PatFrag<(ops node:$val, node:$ptr), (base node:$val, node:$ptr)> {
  let IsAtomic = 1;
  let IsAtomicOrderingRelease = 1;
}

let Predicates = [WORUYUHasLoadAcqStoreRel] in {
  def STDREL : STORE_RELEASEi64<WORUYU_DW, "u64">;

  foreach P = [[relaxed_store<atomic_store_64>, STD],
               [releasing_store<atomic_store_64>, STDREL],
              ] in {
    def : Pat<(P[0] GPR:$val, ADDRri:$addr), (P[1] GPR:$val, ADDRri:$addr)>;
  }
}

// LOAD instructions
class LOAD<WORUYUWidthModifer SizeOp, WORUYUModeModifer ModOp, string OpcodeStr, list<dag> Pattern>
    : TYPE_LD_ST<ModOp.Value, SizeOp.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr),
                 "$dst = *("#OpcodeStr#" *)($addr)",
                 Pattern> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = dst;
  let Inst{55-52} = addr{19-16};
  let Inst{47-32} = addr{15-0};
  let WORUYUClass = WORUYU_LDX;
}

class LOADi64<WORUYUWidthModifer SizeOp, WORUYUModeModifer ModOp, string OpcodeStr, PatFrag OpNode>
    : LOAD<SizeOp, ModOp, OpcodeStr, [(set i64:$dst, (OpNode ADDRri:$addr))]>;

let isCodeGenOnly = 1 in {
  class CORE_LD<RegisterClass RegClass, string Sz>
                : TYPE_LD_ST<WORUYU_MEM.Value, WORUYU_W.Value,
                             (outs RegClass:$dst),
                             (ins u64imm:$opcode, GPR:$src, u64imm:$offset),
                             "$dst = core_ld"#Sz#"($opcode, $src, $offset)",
                             []>;
  def CORE_LD64 : CORE_LD<GPR, "64">;
  def CORE_LD32 : CORE_LD<GPR32, "32">;
  def CORE_ST   : TYPE_LD_ST<WORUYU_MEM.Value, WORUYU_W.Value,
                             (outs),
                             (ins gpr_or_imm:$src, u64imm:$opcode, GPR:$ptr, u64imm:$offset),
                             "core_st($src, $opcode, $ptr, $offset)",
                             []>;
  let Constraints = "$dst = $src" in {
    def CORE_SHIFT : ALU_RR<WORUYU_ALU64, WORUYU_LSH, 0,
                             (outs GPR:$dst),
                             (ins u64imm:$opcode, GPR:$src, u64imm:$offset),
                             "$dst = core_shift($opcode, $src, $offset)",
                             []>;
  }
}

let Predicates = [WORUYUNoALU32] in {
  def LDW : LOADi64<WORUYU_W, WORUYU_MEM, "u32", zextloadi32>;
  def LDH : LOADi64<WORUYU_H, WORUYU_MEM, "u16", zextloadi16>;
  def LDB : LOADi64<WORUYU_B, WORUYU_MEM, "u8", zextloadi8>;
}

let Predicates = [WORUYUHasLdsx] in {
  def LDWSX : LOADi64<WORUYU_W, WORUYU_MEMSX, "s32", sextloadi32>;
  def LDHSX : LOADi64<WORUYU_H, WORUYU_MEMSX, "s16", sextloadi16>;
  def LDBSX : LOADi64<WORUYU_B, WORUYU_MEMSX, "s8",  sextloadi8>;
}

def LDD : LOADi64<WORUYU_DW, WORUYU_MEM, "u64", load>;

class LOAD_ACQUIRE<WORUYUWidthModifer SizeOp, string OpcodeStr, RegisterClass RegTp>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs RegTp:$dst),
                 (ins MEMri:$addr),
                 "$dst = load_acquire(("#OpcodeStr#" *)($addr))",
                 []> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = dst;
  let Inst{55-52} = addr{19-16}; // base reg
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{8-4} = WORUYU_LOAD_ACQ.Value;
  let WORUYUClass = WORUYU_STX;
}

class LOAD_ACQUIREi64<WORUYUWidthModifer SizeOp, string OpcodeStr>
    : LOAD_ACQUIRE<SizeOp, OpcodeStr, GPR>;

class relaxed_load<PatFrags base>
    : PatFrag<(ops node:$ptr), (base node:$ptr)> {
  let IsAtomic = 1;
  let IsAtomicOrderingAcquireOrStronger = 0;
}

class acquiring_load<PatFrags base>
    : PatFrag<(ops node:$ptr), (base node:$ptr)> {
  let IsAtomic = 1;
  let IsAtomicOrderingAcquire = 1;
}

let Predicates = [WORUYUHasLoadAcqStoreRel] in {
  def LDDACQ : LOAD_ACQUIREi64<WORUYU_DW, "u64">;

  foreach P = [[relaxed_load<atomic_load_nonext_64>, LDD],
               [acquiring_load<atomic_load_nonext_64>, LDDACQ],
              ] in {
    def : Pat<(P[0] ADDRri:$addr), (P[1] ADDRri:$addr)>;
  }
}

class BRANCH<WORUYUJumpOp Opc, string OpcodeStr, list<dag> Pattern>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_K.Value,
                   (outs),
                   (ins brtarget:$BrDst),
                   !strconcat(OpcodeStr, " $BrDst"),
                   Pattern> {
  bits<16> BrDst;

  let Inst{47-32} = BrDst;
  let WORUYUClass = WORUYU_JMP;
}

class BRANCH_LONG<WORUYUJumpOp Opc, string OpcodeStr, list<dag> Pattern>
    : TYPE_ALU_JMP<Opc.Value, WORUYU_K.Value,
                   (outs),
                   (ins brtarget:$BrDst),
                   !strconcat(OpcodeStr, " $BrDst"),
                   Pattern> {
  bits<32> BrDst;

  let Inst{31-0} = BrDst;
  let WORUYUClass = WORUYU_JMP32;
}

class CALL<string OpcodeStr>
    : TYPE_ALU_JMP<WORUYU_CALL.Value, WORUYU_K.Value,
                   (outs),
                   (ins calltarget:$BrDst),
                   !strconcat(OpcodeStr, " $BrDst"),
                   []> {
  bits<32> BrDst;

  let Inst{31-0} = BrDst;
  let WORUYUClass = WORUYU_JMP;
}

class CALLX<string OpcodeStr>
    : TYPE_ALU_JMP<WORUYU_CALL.Value, WORUYU_X.Value,
                   (outs),
                   (ins GPR:$BrDst),
                   !strconcat(OpcodeStr, " $BrDst"),
                   []> {
  bits<4> BrDst;

  let Inst{51-48} = BrDst;
  let WORUYUClass = WORUYU_JMP;
}

// Jump always
let isBranch = 1, isTerminator = 1, hasDelaySlot=0, isBarrier = 1 in {
  def JMP : BRANCH<WORUYU_JA, "goto", [(br bb:$BrDst)]>;
  def JMPL : BRANCH_LONG<WORUYU_JA, "gotol", []>;
}

// Jump and link
let isCall=1, hasDelaySlot=0, Uses = [R11] in {
  def JAL  : CALL<"call">;
  def JALX  : CALLX<"callx">;
}

class NOP_I<string OpcodeStr>
    : TYPE_ALU_JMP<WORUYU_MOV.Value, WORUYU_X.Value,
                   (outs),
                   (ins i32imm:$imm),
                   !strconcat(OpcodeStr, "\t$imm"),
                   []> {
  // mov r0, r0 == nop
  let Inst{55-52} = 0;
  let Inst{51-48} = 0;
  let WORUYUClass = WORUYU_ALU64;
}

let hasSideEffects = 0, isCodeGenOnly = 1 in
  def NOP : NOP_I<"nop">;

class RET<string OpcodeStr>
    : TYPE_ALU_JMP<WORUYU_EXIT.Value, WORUYU_K.Value,
                   (outs),
                   (ins),
                   !strconcat(OpcodeStr, ""),
                   [(WORUYUretglue)]> {
  let Inst{31-0} = 0;
  let WORUYUClass = WORUYU_JMP;
}

let isReturn = 1, isTerminator = 1, hasDelaySlot=0, isBarrier = 1,
    isNotDuplicable = 1 in {
  def RET : RET<"exit">;
}

// ADJCALLSTACKDOWN/UP pseudo insns
let Defs = [R11], Uses = [R11], isCodeGenOnly = 1 in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                              "#ADJCALLSTACKDOWN $amt1 $amt2",
                              [(WORUYUcallseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                              "#ADJCALLSTACKUP $amt1 $amt2",
                              [(WORUYUcallseq_end timm:$amt1, timm:$amt2)]>;
}

let usesCustomInserter = 1, isCodeGenOnly = 1 in {
  def Select : Pseudo<(outs GPR:$dst),
                      (ins GPR:$lhs, GPR:$rhs, i64imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (WORUYUselectcc i64:$lhs, i64:$rhs, (i64 imm:$imm), i64:$src, i64:$src2))]>;
  def Select_Ri : Pseudo<(outs GPR:$dst),
                      (ins GPR:$lhs, i64imm:$rhs, i64imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (WORUYUselectcc i64:$lhs, (i64immSExt32:$rhs), (i64 imm:$imm), i64:$src, i64:$src2))]>;
  def Select_64_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR:$lhs, GPR:$rhs, i64imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (WORUYUselectcc i64:$lhs, i64:$rhs, (i64 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_Ri_64_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR:$lhs, i64imm:$rhs, i64imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (WORUYUselectcc i64:$lhs, (i64immSExt32:$rhs), (i64 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR32:$lhs, GPR32:$rhs, i32imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (WORUYUselectcc i32:$lhs, i32:$rhs, (i32 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_Ri_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR32:$lhs, i32imm:$rhs, i32imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (WORUYUselectcc i32:$lhs, (i32immSExt32:$rhs), (i32 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_32_64 : Pseudo<(outs GPR:$dst),
                      (ins GPR32:$lhs, GPR32:$rhs, i32imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (WORUYUselectcc i32:$lhs, i32:$rhs, (i32 imm:$imm), i64:$src, i64:$src2))]>;
  def Select_Ri_32_64 : Pseudo<(outs GPR:$dst),
                      (ins GPR32:$lhs, i32imm:$rhs, i32imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (WORUYUselectcc i32:$lhs, (i32immSExt32:$rhs), (i32 imm:$imm), i64:$src, i64:$src2))]>;
}

// load 64-bit global addr into register
def : Pat<(WORUYUWrapper tconstpool:$in), (LD_imm64 tconstpool:$in)>;
def : Pat<(WORUYUWrapper tjumptable:$in), (LD_imm64 tjumptable:$in)>;

// 0xffffFFFF doesn't fit into simm32, optimize common case
def : Pat<(i64 (and (i64 GPR:$src), 0xffffFFFF)),
          (SRL_ri (SLL_ri (i64 GPR:$src), 32), 32)>;

// Calls
def : Pat<(WORUYUcall tglobaladdr:$dst), (JAL tglobaladdr:$dst)>;
def : Pat<(WORUYUcall texternalsym:$dst), (JAL texternalsym:$dst)>;
def : Pat<(WORUYUcall imm:$dst), (JAL imm:$dst)>;
def : Pat<(WORUYUcall GPR:$dst), (JALX GPR:$dst)>;

// Loads
let Predicates = [WORUYUNoALU32] in {
  def : Pat<(i64 (extloadi8  ADDRri:$src)), (i64 (LDB ADDRri:$src))>;
  def : Pat<(i64 (extloadi16 ADDRri:$src)), (i64 (LDH ADDRri:$src))>;
  def : Pat<(i64 (extloadi32 ADDRri:$src)), (i64 (LDW ADDRri:$src))>;
}

// Atomic add, and, or, xor
class ATOMIC_NOFETCH<WORUYUWidthModifer SizeOp, string OpType, RegisterClass RegTp,
                     WORUYUArithOp Opc, string Opstr>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs RegTp:$dst),
                 (ins MEMri:$addr, RegTp:$val),
                 "lock *(" #OpType# " *)($addr) " #Opstr# "= $val",
                 []> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = Opc.Value;
  let WORUYUClass = WORUYU_STX;
}

let Constraints = "$dst = $val" in {
  let Predicates = [WORUYUHasALU32], DecoderNamespace = "WORUYUALU32" in {
    def XADDW32 : ATOMIC_NOFETCH<WORUYU_W, "u32", GPR32, WORUYU_ADD, "+">;
    def XANDW32 : ATOMIC_NOFETCH<WORUYU_W, "u32", GPR32, WORUYU_AND, "&">;
    def XORW32  : ATOMIC_NOFETCH<WORUYU_W, "u32", GPR32, WORUYU_OR, "|">;
    def XXORW32 : ATOMIC_NOFETCH<WORUYU_W, "u32", GPR32, WORUYU_XOR, "^">;
  }
  def XADDW  : ATOMIC_NOFETCH<WORUYU_W,  "u32", GPR, WORUYU_ADD, "+">;
  def XADDD  : ATOMIC_NOFETCH<WORUYU_DW, "u64", GPR, WORUYU_ADD, "+">;
  def XANDD  : ATOMIC_NOFETCH<WORUYU_DW, "u64", GPR, WORUYU_AND, "&">;
  def XORD   : ATOMIC_NOFETCH<WORUYU_DW, "u64", GPR, WORUYU_OR, "|">;
  def XXORD  : ATOMIC_NOFETCH<WORUYU_DW, "u64", GPR, WORUYU_XOR, "^">;
}

let Predicates = [WORUYUNoALU32] in {
  def : Pat<(atomic_load_add_i32 ADDRri:$addr, GPR:$val),
            (XADDW ADDRri:$addr, GPR:$val)>;
  def : Pat<(atomic_load_add_i64 ADDRri:$addr, GPR:$val),
            (XADDD ADDRri:$addr, GPR:$val)>;
}

// Atomic Fetch-and-<add, and, or, xor> operations
class XFALU64<WORUYUWidthModifer SizeOp, WORUYUArithOp Opc, string OpcodeStr, string OpcStr>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr, GPR:$val),
                 "$dst = atomic_fetch_"#OpcStr#"(("#OpcodeStr#" *)($addr), $val)",
                 []> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = Opc.Value;
  let Inst{3-0} = WORUYU_FETCH.Value;
  let WORUYUClass = WORUYU_STX;
}

class XFALU32<WORUYUWidthModifer SizeOp, WORUYUArithOp Opc, string OpcodeStr, string OpcStr>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs GPR32:$dst),
                 (ins MEMri:$addr, GPR32:$val),
                 "$dst = atomic_fetch_"#OpcStr#"(("#OpcodeStr#" *)($addr), $val)",
                 []> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = Opc.Value;
  let Inst{3-0} = WORUYU_FETCH.Value;
  let WORUYUClass = WORUYU_STX;
}

let Constraints = "$dst = $val" in {
  let Predicates = [WORUYUHasALU32], DecoderNamespace = "WORUYUALU32" in {
    def XFADDW32 : XFALU32<WORUYU_W, WORUYU_ADD, "u32", "add">;
    def XFANDW32 : XFALU32<WORUYU_W, WORUYU_AND, "u32", "and">;
    def XFORW32  : XFALU32<WORUYU_W, WORUYU_OR,  "u32", "or">;
    def XFXORW32 : XFALU32<WORUYU_W, WORUYU_XOR, "u32", "xor">;
  }

  let Predicates = [WORUYUHasALU32] in {
    def XFADDD : XFALU64<WORUYU_DW, WORUYU_ADD, "u64", "add">;
  }
  def XFANDD : XFALU64<WORUYU_DW, WORUYU_AND, "u64", "and">;
  def XFORD  : XFALU64<WORUYU_DW, WORUYU_OR,  "u64", "or">;
  def XFXORD : XFALU64<WORUYU_DW, WORUYU_XOR, "u64", "xor">;
}

let Predicates = [WORUYUHasALU32] in {
    foreach P = [// add
                 [atomic_load_add_i32_monotonic,  XADDW32],
                 [atomic_load_add_i32_acquire,   XFADDW32],
                 [atomic_load_add_i32_release,   XFADDW32],
                 [atomic_load_add_i32_acq_rel,   XFADDW32],
                 [atomic_load_add_i32_seq_cst,   XFADDW32],
                 // and
                 [atomic_load_and_i32_monotonic,  XANDW32],
                 [atomic_load_and_i32_acquire,   XFANDW32],
                 [atomic_load_and_i32_release,   XFANDW32],
                 [atomic_load_and_i32_acq_rel,   XFANDW32],
                 [atomic_load_and_i32_seq_cst,   XFANDW32],
                 // or
                 [atomic_load_or_i32_monotonic,   XORW32],
                 [atomic_load_or_i32_acquire,    XFORW32],
                 [atomic_load_or_i32_release,    XFORW32],
                 [atomic_load_or_i32_acq_rel,    XFORW32],
                 [atomic_load_or_i32_seq_cst,    XFORW32],
                 // xor
                 [atomic_load_xor_i32_monotonic,  XXORW32],
                 [atomic_load_xor_i32_acquire,   XFXORW32],
                 [atomic_load_xor_i32_release,   XFXORW32],
                 [atomic_load_xor_i32_acq_rel,   XFXORW32],
                 [atomic_load_xor_i32_seq_cst,   XFXORW32],
                ] in {
      def : Pat<(P[0] ADDRri:$addr, GPR32:$val), (P[1]  ADDRri:$addr, GPR32:$val)>;
    }

    // atomic_load_sub can be represented as a neg followed
    // by an atomic_load_add.
    foreach P = [[atomic_load_sub_i32_monotonic,  XADDW32],
                 [atomic_load_sub_i32_acquire,   XFADDW32],
                 [atomic_load_sub_i32_release,   XFADDW32],
                 [atomic_load_sub_i32_acq_rel,   XFADDW32],
                 [atomic_load_sub_i32_seq_cst,   XFADDW32],
                ] in {
      def : Pat<(P[0] ADDRri:$addr, GPR32:$val), (P[1]  ADDRri:$addr, (NEG_32 GPR32:$val))>;
    }

    foreach P = [// add
                 [atomic_load_add_i64_monotonic,  XADDD],
                 [atomic_load_add_i64_acquire,   XFADDD],
                 [atomic_load_add_i64_release,   XFADDD],
                 [atomic_load_add_i64_acq_rel,   XFADDD],
                 [atomic_load_add_i64_seq_cst,   XFADDD],
                ] in {
      def : Pat<(P[0] ADDRri:$addr, GPR:$val), (P[1]  ADDRri:$addr, GPR:$val)>;
    }
}

foreach P = [[atomic_load_sub_i64_monotonic,  XADDD],
             [atomic_load_sub_i64_acquire,   XFADDD],
             [atomic_load_sub_i64_release,   XFADDD],
             [atomic_load_sub_i64_acq_rel,   XFADDD],
             [atomic_load_sub_i64_seq_cst,   XFADDD],
            ] in {
  def : Pat<(P[0] ADDRri:$addr, GPR:$val), (P[1]  ADDRri:$addr, (NEG_64 GPR:$val))>;
}

// Borrow the idea from X86InstrFragments.td
class binop_no_use<SDPatternOperator operator>
      : PatFrag<(ops node:$A, node:$B),
                (operator node:$A, node:$B),
                [{ return SDValue(N, 0).use_empty(); }]>;

class binop_has_use<SDPatternOperator operator>
      : PatFrag<(ops node:$A, node:$B),
                (operator node:$A, node:$B),
                [{ return !SDValue(N, 0).use_empty(); }]>;

foreach op = [add, and, or, xor] in {
def atomic_load_ # op # _i64_monotonic_nu:
    binop_no_use <!cast<SDPatternOperator>("atomic_load_"#op# _i64_monotonic)>;
def atomic_load_ # op # _i64_monotonic_hu:
    binop_has_use<!cast<SDPatternOperator>("atomic_load_"#op# _i64_monotonic)>;
}

foreach P = [// and
             [atomic_load_and_i64_monotonic_nu, XANDD],
             [atomic_load_and_i64_monotonic_hu, XFANDD],
             [atomic_load_and_i64_acquire,   XFANDD],
             [atomic_load_and_i64_release,   XFANDD],
             [atomic_load_and_i64_acq_rel,   XFANDD],
             [atomic_load_and_i64_seq_cst,   XFANDD],
             // or
             [atomic_load_or_i64_monotonic_nu, XORD],
             [atomic_load_or_i64_monotonic_hu, XFORD],
             [atomic_load_or_i64_acquire,    XFORD],
             [atomic_load_or_i64_release,    XFORD],
             [atomic_load_or_i64_acq_rel,    XFORD],
             [atomic_load_or_i64_seq_cst,    XFORD],
             // xor
             [atomic_load_xor_i64_monotonic_nu, XXORD],
             [atomic_load_xor_i64_monotonic_hu, XFXORD],
             [atomic_load_xor_i64_acquire,   XFXORD],
             [atomic_load_xor_i64_release,   XFXORD],
             [atomic_load_xor_i64_acq_rel,   XFXORD],
             [atomic_load_xor_i64_seq_cst,   XFXORD],
            ] in {
  def : Pat<(P[0] ADDRri:$addr, GPR:$val), (P[1]  ADDRri:$addr, GPR:$val)>;
}

// Atomic Exchange
class XCHG<WORUYUWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr, GPR:$val),
                 "$dst = xchg_"#OpcodeStr#"($addr, $val)",
                 [(set GPR:$dst, (OpNode ADDRri:$addr,GPR:$val))]> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = WORUYU_XCHG.Value;
  let Inst{3-0} = WORUYU_FETCH.Value;
  let WORUYUClass = WORUYU_STX;
}

class XCHG32<WORUYUWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs GPR32:$dst),
                 (ins MEMri:$addr, GPR32:$val),
                 "$dst = xchg32_"#OpcodeStr#"($addr, $val)",
                 [(set GPR32:$dst, (OpNode ADDRri:$addr,GPR32:$val))]> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = WORUYU_XCHG.Value;
  let Inst{3-0} = WORUYU_FETCH.Value;
  let WORUYUClass = WORUYU_STX;
}

let Constraints = "$dst = $val" in {
  let Predicates = [WORUYUHasALU32], DecoderNamespace = "WORUYUALU32" in {
    def XCHGW32 : XCHG32<WORUYU_W, "32", atomic_swap_i32>;
  }

  def XCHGD : XCHG<WORUYU_DW, "64", atomic_swap_i64>;
}

// Compare-And-Exchange
class CMPXCHG<WORUYUWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs),
                 (ins MEMri:$addr, GPR:$new),
                 "r0 = cmpxchg_"#OpcodeStr#"($addr, r0, $new)",
                 [(set R0, (OpNode ADDRri:$addr, R0, GPR:$new))]> {
  bits<4> new;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = new;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = WORUYU_CMPXCHG.Value;
  let Inst{3-0} = WORUYU_FETCH.Value;
  let WORUYUClass = WORUYU_STX;
}

class CMPXCHG32<WORUYUWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<WORUYU_ATOMIC.Value, SizeOp.Value,
                 (outs),
                 (ins MEMri:$addr, GPR32:$new),
                 "w0 = cmpxchg32_"#OpcodeStr#"($addr, w0, $new)",
                 [(set W0, (OpNode ADDRri:$addr, W0, GPR32:$new))]> {
  bits<4> new;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = new;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = WORUYU_CMPXCHG.Value;
  let Inst{3-0} = WORUYU_FETCH.Value;
  let WORUYUClass = WORUYU_STX;
}

let Predicates = [WORUYUHasALU32], Defs = [W0], Uses = [W0],
    DecoderNamespace = "WORUYUALU32" in {
  def CMPXCHGW32 : CMPXCHG32<WORUYU_W, "32", atomic_cmp_swap_i32>;
}

let Defs = [R0], Uses = [R0] in {
  def CMPXCHGD : CMPXCHG<WORUYU_DW, "64", atomic_cmp_swap_i64>;
}

// bswap16, bswap32, bswap64
class BSWAP<WORUYUOpClass Class, bits<32> SizeOp, string OpcodeStr, WORUYUSrcType SrcType, list<dag> Pattern>
    : TYPE_ALU_JMP<WORUYU_END.Value, SrcType.Value,
                   (outs GPR:$dst),
                   (ins GPR:$src),
                   "$dst = "#OpcodeStr#" $src",
                   Pattern> {
  bits<4> dst;

  let Inst{51-48} = dst;
  let Inst{31-0} = SizeOp;
  let WORUYUClass = Class;
}


let Constraints = "$dst = $src" in {
  let Predicates = [WORUYUHasBswap] in {
    def BSWAP16 : BSWAP<WORUYU_ALU64, 16, "bswap16", WORUYU_TO_LE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 48)))]>;
    def BSWAP32 : BSWAP<WORUYU_ALU64, 32, "bswap32", WORUYU_TO_LE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 32)))]>;
    def BSWAP64 : BSWAP<WORUYU_ALU64, 64, "bswap64", WORUYU_TO_LE, [(set GPR:$dst, (bswap GPR:$src))]>;
  }

  let Predicates = [WORUYUNoBswap] in {
    let Predicates = [WORUYUIsLittleEndian] in {
        def BE16 : BSWAP<WORUYU_ALU, 16, "be16", WORUYU_TO_BE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 48)))]>;
        def BE32 : BSWAP<WORUYU_ALU, 32, "be32", WORUYU_TO_BE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 32)))]>;
        def BE64 : BSWAP<WORUYU_ALU, 64, "be64", WORUYU_TO_BE, [(set GPR:$dst, (bswap GPR:$src))]>;
    }
    let Predicates = [WORUYUIsBigEndian] in {
        def LE16 : BSWAP<WORUYU_ALU, 16, "le16", WORUYU_TO_LE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 48)))]>;
        def LE32 : BSWAP<WORUYU_ALU, 32, "le32", WORUYU_TO_LE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 32)))]>;
        def LE64 : BSWAP<WORUYU_ALU, 64, "le64", WORUYU_TO_LE, [(set GPR:$dst, (bswap GPR:$src))]>;
    }
  }
}

let Defs = [R0, R1, R2, R3, R4, R5], Uses = [R6], hasSideEffects = 1,
    hasExtraDefRegAllocReq = 1, hasExtraSrcRegAllocReq = 1, mayLoad = 1 in {
class LOAD_ABS<WORUYUWidthModifer SizeOp, string OpcodeStr>
    : TYPE_LD_ST<WORUYU_ABS.Value, SizeOp.Value,
                 (outs), (ins i64imm:$imm),
                 "r0 = *("#OpcodeStr#" *)skb[$imm]",
                 []> {
  bits<32> imm;

  let Inst{31-0} = imm;
  let WORUYUClass = WORUYU_LD;
}

class LOAD_IND<WORUYUWidthModifer SizeOp, string OpcodeStr>
    : TYPE_LD_ST<WORUYU_IND.Value, SizeOp.Value,
                 (outs), (ins GPR:$val),
                 "r0 = *("#OpcodeStr#" *)skb[$val]",
                 []> {
  bits<4> val;

  let Inst{55-52} = val;
  let WORUYUClass = WORUYU_LD;
}
}

def LD_ABS_B : LOAD_ABS<WORUYU_B, "u8">;
def LD_ABS_H : LOAD_ABS<WORUYU_H, "u16">;
def LD_ABS_W : LOAD_ABS<WORUYU_W, "u32">;

def LD_IND_B : LOAD_IND<WORUYU_B, "u8">;
def LD_IND_H : LOAD_IND<WORUYU_H, "u16">;
def LD_IND_W : LOAD_IND<WORUYU_W, "u32">;

let isCodeGenOnly = 1 in {
  def MOV_32_64 : ALU_RR<WORUYU_ALU, WORUYU_MOV, 0,
                         (outs GPR:$dst), (ins GPR32:$src),
                         "$dst = $src", []>;
}

let Predicates = [WORUYUNoMovsx] in {
  def : Pat<(i64 (sext GPR32:$src)),
            (SRA_ri (SLL_ri (MOV_32_64 GPR32:$src), 32), 32)>;
}

let Predicates = [WORUYUHasMovsx] in {
  def : Pat<(i64 (sext GPR32:$src)),
            (MOVSX_rr_32 (MOV_32_64 GPR32:$src))>;
}

def : Pat<(i64 (zext GPR32:$src)), (MOV_32_64 GPR32:$src)>;

// For i64 -> i32 truncation, use the 32-bit subregister directly.
def : Pat<(i32 (trunc GPR:$src)),
          (i32 (EXTRACT_SUBREG GPR:$src, sub_32))>;

// For i32 -> i64 anyext, we don't care about the high bits.
def : Pat<(i64 (anyext GPR32:$src)),
          (INSERT_SUBREG (i64 (IMPLICIT_DEF)), GPR32:$src, sub_32)>;

class STORE32<WORUYUWidthModifer SizeOp, string OpcodeStr, list<dag> Pattern>
    : TYPE_LD_ST<WORUYU_MEM.Value, SizeOp.Value,
                 (outs),
                 (ins GPR32:$src, MEMri:$addr),
                 "*("#OpcodeStr#" *)($addr) = $src",
                 Pattern> {
  bits<4> src;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = src;
  let Inst{47-32} = addr{15-0}; // offset
  let WORUYUClass = WORUYU_STX;
}

class STOREi32<WORUYUWidthModifer Opc, string OpcodeStr, PatFrag OpNode>
    : STORE32<Opc, OpcodeStr, [(OpNode GPR32:$src, ADDRri:$addr)]>;

class STORE_RELEASEi32<WORUYUWidthModifer Opc, string OpcodeStr>
    : STORE_RELEASE<Opc, OpcodeStr, GPR32>;

let Predicates = [WORUYUHasALU32], DecoderNamespace = "WORUYUALU32" in {
  def STW32 : STOREi32<WORUYU_W, "u32", store>;
  def STH32 : STOREi32<WORUYU_H, "u16", truncstorei16>;
  def STB32 : STOREi32<WORUYU_B, "u8", truncstorei8>;

  let Predicates = [WORUYUHasLoadAcqStoreRel] in {
    def STWREL32 : STORE_RELEASEi32<WORUYU_W, "u32">;
    def STHREL32 : STORE_RELEASEi32<WORUYU_H, "u16">;
    def STBREL32 : STORE_RELEASEi32<WORUYU_B, "u8">;
  }
}

class LOAD32<WORUYUWidthModifer SizeOp, WORUYUModeModifer ModOp, string OpcodeStr, list<dag> Pattern>
    : TYPE_LD_ST<ModOp.Value, SizeOp.Value,
                (outs GPR32:$dst),
                (ins MEMri:$addr),
                "$dst = *("#OpcodeStr#" *)($addr)",
                Pattern> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = dst;
  let Inst{55-52} = addr{19-16};
  let Inst{47-32} = addr{15-0};
  let WORUYUClass = WORUYU_LDX;
}

class LOADi32<WORUYUWidthModifer SizeOp, WORUYUModeModifer ModOp, string OpcodeStr, PatFrag OpNode>
    : LOAD32<SizeOp, ModOp, OpcodeStr, [(set i32:$dst, (OpNode ADDRri:$addr))]>;

class LOAD_ACQUIREi32<WORUYUWidthModifer SizeOp, string OpcodeStr>
    : LOAD_ACQUIRE<SizeOp, OpcodeStr, GPR32>;

let Predicates = [WORUYUHasALU32], DecoderNamespace = "WORUYUALU32" in {
  def LDW32 : LOADi32<WORUYU_W, WORUYU_MEM, "u32", load>;
  def LDH32 : LOADi32<WORUYU_H, WORUYU_MEM, "u16", zextloadi16>;
  def LDB32 : LOADi32<WORUYU_B, WORUYU_MEM, "u8", zextloadi8>;

  let Predicates = [WORUYUHasLoadAcqStoreRel] in {
    def LDWACQ32 : LOAD_ACQUIREi32<WORUYU_W, "u32">;
    def LDHACQ32 : LOAD_ACQUIREi32<WORUYU_H, "u16">;
    def LDBACQ32 : LOAD_ACQUIREi32<WORUYU_B, "u8">;
  }
}

let Predicates = [WORUYUHasALU32] in {
  def : Pat<(truncstorei8 GPR:$src, ADDRri:$dst),
            (STB32 (EXTRACT_SUBREG GPR:$src, sub_32), ADDRri:$dst)>;
  def : Pat<(truncstorei16 GPR:$src, ADDRri:$dst),
            (STH32 (EXTRACT_SUBREG GPR:$src, sub_32), ADDRri:$dst)>;
  def : Pat<(truncstorei32 GPR:$src, ADDRri:$dst),
            (STW32 (EXTRACT_SUBREG GPR:$src, sub_32), ADDRri:$dst)>;
  def : Pat<(i32 (extloadi8 ADDRri:$src)), (i32 (LDB32 ADDRri:$src))>;
  def : Pat<(i32 (extloadi16 ADDRri:$src)), (i32 (LDH32 ADDRri:$src))>;

  let Predicates = [WORUYUHasLdsx] in {
    def : Pat<(i32 (sextloadi8 ADDRri:$src)), (EXTRACT_SUBREG (LDBSX ADDRri:$src), sub_32)>;
    def : Pat<(i32 (sextloadi16 ADDRri:$src)), (EXTRACT_SUBREG (LDHSX ADDRri:$src), sub_32)>;
  }

  def : Pat<(i64 (zextloadi8  ADDRri:$src)),
            (SUBREG_TO_REG (LDB32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (zextloadi16 ADDRri:$src)),
            (SUBREG_TO_REG (LDH32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (zextloadi32 ADDRri:$src)),
            (SUBREG_TO_REG (LDW32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (extloadi8  ADDRri:$src)),
            (SUBREG_TO_REG (LDB32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (extloadi16 ADDRri:$src)),
            (SUBREG_TO_REG (LDH32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (extloadi32 ADDRri:$src)),
            (SUBREG_TO_REG (LDW32 ADDRri:$src), sub_32)>;

  let Predicates = [WORUYUHasLoadAcqStoreRel] in {
    foreach P = [[relaxed_load<atomic_load_nonext_32>, LDW32],
                 [relaxed_load<atomic_load_azext_16>, LDH32],
                 [relaxed_load<atomic_load_azext_8>, LDB32],
                 [acquiring_load<atomic_load_nonext_32>, LDWACQ32],
                 [acquiring_load<atomic_load_azext_16>, LDHACQ32],
                 [acquiring_load<atomic_load_azext_8>, LDBACQ32],
                ] in {
      def : Pat<(P[0] ADDRri:$addr), (P[1] ADDRri:$addr)>;
    }
  }

  let Predicates = [WORUYUHasLoadAcqStoreRel] in {
    foreach P = [[relaxed_store<atomic_store_32>, STW32],
                 [relaxed_store<atomic_store_16>, STH32],
                 [relaxed_store<atomic_store_8>, STB32],
                 [releasing_store<atomic_store_32>, STWREL32],
                 [releasing_store<atomic_store_16>, STHREL32],
                 [releasing_store<atomic_store_8>, STBREL32],
                ] in {
      def : Pat<(P[0] GPR32:$val, ADDRri:$addr), (P[1] GPR32:$val, ADDRri:$addr)>;
    }
  }
}

let usesCustomInserter = 1, isCodeGenOnly = 1 in {
    def MEMCPY : Pseudo<
      (outs),
      (ins GPR:$dst, GPR:$src, i64imm:$len, i64imm:$align, variable_ops),
      "#memcpy dst: $dst, src: $src, len: $len, align: $align",
      [(WORUYUmemcpy GPR:$dst, GPR:$src, imm:$len, imm:$align)]>;
}

// For GlobalValue and BlockAddress.
let usesCustomInserter = 1, isCodeGenOnly = 1 in {
  def LDIMM64 : Pseudo<(outs GPR:$dst), (ins i64imm:$addr), "", []>;
}
