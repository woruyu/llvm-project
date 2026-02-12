//===-- WORUYUSelectionDAGInfo.h - WORUYU SelectionDAG Info -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the WORUYU subclass for SelectionDAGTargetInfo.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WORUYU_WORUYUSELECTIONDAGINFO_H
#define LLVM_LIB_TARGET_WORUYU_WORUYUSELECTIONDAGINFO_H

#include "llvm/CodeGen/SelectionDAGTargetInfo.h"

#define GET_SDNODE_ENUM
#include "WORUYUGenSDNodeInfo.inc"

namespace llvm {

class WORUYUSelectionDAGInfo : public SelectionDAGGenTargetInfo {
public:
  WORUYUSelectionDAGInfo();

  SDValue EmitTargetCodeForMemcpy(SelectionDAG &DAG, const SDLoc &dl,
                                  SDValue Chain, SDValue Dst, SDValue Src,
                                  SDValue Size, Align Alignment,
                                  bool isVolatile, bool AlwaysInline,
                                  MachinePointerInfo DstPtrInfo,
                                  MachinePointerInfo SrcPtrInfo) const override;

  unsigned getCommonMaxStoresPerMemFunc() const { return 128; }
};

} // namespace llvm

#endif
