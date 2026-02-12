//===--- WORUYU.cpp - Implement WORUYU target feature support -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements WORUYU TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "WORUYU.h"
#include "clang/Basic/Builtins.h"
#include "clang/Basic/MacroBuilder.h"
#include "clang/Basic/TargetBuiltins.h"

using namespace clang;
using namespace clang::targets;

static constexpr int NumBuiltins =
    XCore::LastTSBuiltin - Builtin::FirstTSBuiltin;

static constexpr llvm::StringTable BuiltinStrings =
    CLANG_BUILTIN_STR_TABLE_START
#define BUILTIN CLANG_BUILTIN_STR_TABLE
#include "clang/Basic/BuiltinsWORUYU.def"
    ;

static constexpr auto BuiltinInfos = Builtin::MakeInfos<NumBuiltins>({
#define BUILTIN CLANG_BUILTIN_ENTRY
#define LIBBUILTIN CLANG_LIBBUILTIN_ENTRY
#include "clang/Basic/BuiltinsWORUYU.def"
});

void WORUYUTargetInfo::getTargetDefines(const LangOptions &Opts,
                                     MacroBuilder &Builder) const {
  Builder.defineMacro("__woruyu__");
  Builder.defineMacro("__WORUYU__");
}

static constexpr llvm::StringLiteral ValidNPUNames[] = {"generic"};

bool WORUYUTargetInfo::isValidCPUName(StringRef Name) const {
  return llvm::is_contained(ValidNPUNames, Name);
}

void WORUYUTargetInfo::fillValidCPUList(SmallVectorImpl<StringRef> &Values) const {
  Values.append(std::begin(ValidNPUNames), std::end(ValidNPUNames));
}

llvm::SmallVector<Builtin::InfosShard> WORUYUTargetInfo::getTargetBuiltins() const {
  return {{&BuiltinStrings, BuiltinInfos}};
}

bool WORUYUTargetInfo::handleTargetFeatures(std::vector<std::string> &Features,
                                         DiagnosticsEngine &Diags) {
  for (const auto &Feature : Features) {
    if (Feature == "+alu32") {
      HasAlu32 = true;
    }
  }

  return true;
}
