//=======-- WORUYUMCFixups.h - WORUYU-specific fixup entries ------*- C++ -*-=======//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WORUYU_MCTARGETDESC_SYSTEMZMCFIXUPS_H
#define LLVM_LIB_TARGET_WORUYU_MCTARGETDESC_SYSTEMZMCFIXUPS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace WORUYU {
enum FixupKind {
  // WORUYU specific relocations.
  FK_WORUYU_PCRel_4 = FirstTargetFixupKind,

  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
} // end namespace WORUYU
} // end namespace llvm

#endif
