//===-- WORUYUSubtarget.cpp - WORUYU Subtarget Information ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the WORUYU specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "WORUYUSubtarget.h"
#include "WORUYU.h"
#include "WORUYUTargetMachine.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/TargetParser/Host.h"

using namespace llvm;

#define DEBUG_TYPE "WORUYU-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "WORUYUGenSubtargetInfo.inc"

static cl::opt<bool> Disable_ldsx("disable-ldsx", cl::Hidden, cl::init(false),
  cl::desc("Disable ldsx insns"));
static cl::opt<bool> Disable_movsx("disable-movsx", cl::Hidden, cl::init(false),
  cl::desc("Disable movsx insns"));
static cl::opt<bool> Disable_bswap("disable-bswap", cl::Hidden, cl::init(false),
  cl::desc("Disable bswap insns"));
static cl::opt<bool> Disable_sdiv_smod("disable-sdiv-smod", cl::Hidden,
  cl::init(false), cl::desc("Disable sdiv/smod insns"));
static cl::opt<bool> Disable_gotol("disable-gotol", cl::Hidden, cl::init(false),
  cl::desc("Disable gotol insn"));
static cl::opt<bool>
    Disable_StoreImm("disable-storeimm", cl::Hidden, cl::init(false),
                     cl::desc("Disable WORUYU_ST (immediate store) insn"));
static cl::opt<bool> Disable_load_acq_store_rel(
    "disable-load-acq-store-rel", cl::Hidden, cl::init(false),
    cl::desc("Disable load-acquire and store-release insns"));
static cl::opt<bool> Disable_gotox("disable-gotox", cl::Hidden, cl::init(false),
                                   cl::desc("Disable gotox insn"));

void WORUYUSubtarget::anchor() {}

WORUYUSubtarget &WORUYUSubtarget::initializeSubtargetDependencies(StringRef CPU,
                                                            StringRef FS) {
  initializeEnvironment();
  initSubtargetFeatures(CPU, FS);
  ParseSubtargetFeatures(CPU, /*TuneCPU*/ CPU, FS);
  return *this;
}

void WORUYUSubtarget::initializeEnvironment() {
  HasJmpExt = false;
  HasJmp32 = false;
  HasAlu32 = false;
  UseDwarfRIS = false;
  HasLdsx = false;
  HasMovsx = false;
  HasBswap = false;
  HasSdivSmod = false;
  HasGotol = false;
  HasStoreImm = false;
  HasLoadAcqStoreRel = false;
  HasGotox = false;
  AllowsMisalignedMemAccess = false;
}

void WORUYUSubtarget::initSubtargetFeatures(StringRef CPU, StringRef FS) {
  if (CPU.empty())
    CPU = "v3";
  if (CPU == "probe")
    CPU = sys::detail::getHostCPUNameForWORUYU();
  if (CPU == "generic" || CPU == "v1")
    return;
  if (CPU == "v2") {
    HasJmpExt = true;
    return;
  }
  if (CPU == "v3") {
    HasJmpExt = true;
    HasJmp32 = true;
    HasAlu32 = true;
    return;
  }
  if (CPU == "v4") {
    HasJmpExt = true;
    HasJmp32 = true;
    HasAlu32 = true;
    HasLdsx = !Disable_ldsx;
    HasMovsx = !Disable_movsx;
    HasBswap = !Disable_bswap;
    HasSdivSmod = !Disable_sdiv_smod;
    HasGotol = !Disable_gotol;
    HasStoreImm = !Disable_StoreImm;
    HasLoadAcqStoreRel = !Disable_load_acq_store_rel;
    HasGotox = !Disable_gotox;
    return;
  }
}

WORUYUSubtarget::WORUYUSubtarget(const Triple &TT, const std::string &CPU,
                           const std::string &FS, const TargetMachine &TM)
    : WORUYUGenSubtargetInfo(TT, CPU, /*TuneCPU*/ CPU, FS),
      InstrInfo(initializeSubtargetDependencies(CPU, FS)), FrameLowering(*this),
      TLInfo(TM, *this) {
  IsLittleEndian = TT.isLittleEndian();
}
