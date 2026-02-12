//===-- WORUYUTargetMachine.cpp - Define TargetMachine for WORUYU ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the info about WORUYU target spec.
//
//===----------------------------------------------------------------------===//

#include "WORUYUTargetMachine.h"
#include "WORUYU.h"
#include "WORUYUTargetLoweringObjectFile.h"
#include "WORUYUTargetTransformInfo.h"
#include "MCTargetDesc/WORUYUMCAsmInfo.h"
#include "TargetInfo/WORUYUTargetInfo.h"
#include "llvm/CodeGen/GlobalISel/IRTranslator.h"
#include "llvm/CodeGen/GlobalISel/Legalizer.h"
#include "llvm/CodeGen/GlobalISel/RegBankSelect.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/PassManager.h"
#include "llvm/InitializePasses.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Scalar/SimplifyCFG.h"
#include "llvm/Transforms/Utils/SimplifyCFGOptions.h"
#include <optional>
using namespace llvm;

static cl::
opt<bool> DisableMIPeephole("disable-WORUYU-peephole", cl::Hidden,
                            cl::desc("Disable machine peepholes for WORUYU"));

static cl::opt<bool>
    DisableCheckUnreachable("WORUYU-disable-trap-unreachable", cl::Hidden,
                            cl::desc("Disable Trap Unreachable for WORUYU"));

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeWORUYUTarget() {
  // Register the target.
  RegisterTargetMachine<WORUYUTargetMachine> X(getTheWORUYUleTarget());
  RegisterTargetMachine<WORUYUTargetMachine> Y(getTheWORUYUbeTarget());
  RegisterTargetMachine<WORUYUTargetMachine> Z(getTheWORUYUTarget());

  PassRegistry &PR = *PassRegistry::getPassRegistry();
  initializeWORUYUAsmPrinterPass(PR);
  initializeWORUYUDAGToDAGISelLegacyPass(PR);
}

static Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
  return RM.value_or(Reloc::PIC_);
}

WORUYUTargetMachine::WORUYUTargetMachine(const Target &T, const Triple &TT,
                                   StringRef CPU, StringRef FS,
                                   const TargetOptions &Options,
                                   std::optional<Reloc::Model> RM,
                                   std::optional<CodeModel::Model> CM,
                                   CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(T, TT.computeDataLayout(), TT, CPU, FS, Options,
                               getEffectiveRelocModel(RM),
                               getEffectiveCodeModel(CM, CodeModel::Small), OL),
      TLOF(std::make_unique<WORUYUTargetLoweringObjectFileELF>()),
      Subtarget(TT, std::string(CPU), std::string(FS), *this) {
  if (!DisableCheckUnreachable) {
    this->Options.TrapUnreachable = true;
    this->Options.NoTrapAfterNoreturn = true;
  }

  initAsmInfo();

  WORUYUMCAsmInfo *MAI =
      static_cast<WORUYUMCAsmInfo *>(const_cast<MCAsmInfo *>(AsmInfo.get()));
  MAI->setDwarfUsesRelocationsAcrossSections(!Subtarget.getUseDwarfRIS());
}

namespace {
// WORUYU Code Generator Pass Configuration Options.
class WORUYUPassConfig : public TargetPassConfig {
public:
  WORUYUPassConfig(WORUYUTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  WORUYUTargetMachine &getWORUYUTargetMachine() const {
    return getTM<WORUYUTargetMachine>();
  }

  void addIRPasses() override;
  bool addInstSelector() override;
  void addMachineSSAOptimization() override;

};
}

TargetPassConfig *WORUYUTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new WORUYUPassConfig(*this, PM);
}

void WORUYUPassConfig::addIRPasses() {
  TargetPassConfig::addIRPasses();
}

TargetTransformInfo
WORUYUTargetMachine::getTargetTransformInfo(const Function &F) const {
  return TargetTransformInfo(std::make_unique<WORUYUTTIImpl>(this, F));
}

// Install an instruction selector pass using
// the ISelDag to gen WORUYU code.
bool WORUYUPassConfig::addInstSelector() {
  addPass(createWORUYUISelDag(getWORUYUTargetMachine()));

  return false;
}

void WORUYUPassConfig::addMachineSSAOptimization() {
  TargetPassConfig::addMachineSSAOptimization();
}
