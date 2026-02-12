#include "CGBuiltin.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/IR/IntrinsicsWORUYU.h"

using namespace clang;
using namespace CodeGen;
using namespace llvm;

Value *CodeGenFunction::EmitWORUYUBuiltinExpr(unsigned BuiltinID,
                                           const CallExpr *E) {
  switch (BuiltinID) {
  default:
    llvm_unreachable("Unexpected WORUYU builtin");
  }
}
