add_llvm_component_group(WORUYU)

set(LLVM_TARGET_DEFINITIONS WORUYU.td)

tablegen(LLVM WORUYUGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM WORUYUGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM WORUYUGenCallingConv.inc -gen-callingconv)
tablegen(LLVM WORUYUGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM WORUYUGenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM WORUYUGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM WORUYUGenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM WORUYUGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM WORUYUGenSDNodeInfo.inc -gen-sd-node-info)
tablegen(LLVM WORUYUGenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(WORUYUCommonTableGen)

add_llvm_target(WORUYUCodeGen
  WORUYUAsmPrinter.cpp
  WORUYUFrameLowering.cpp
  WORUYUInstrInfo.cpp
  WORUYUISelDAGToDAG.cpp
  WORUYUISelLowering.cpp
  WORUYUMCInstLower.cpp
  WORUYURegisterInfo.cpp
  WORUYUSelectionDAGInfo.cpp
  WORUYUSubtarget.cpp
  WORUYUTargetLoweringObjectFile.cpp
  WORUYUTargetMachine.cpp

  LINK_COMPONENTS
  Analysis
  AsmPrinter
  WORUYUDesc
  WORUYUInfo
  CodeGen
  CodeGenTypes
  Core
  GlobalISel
  IPO
  MC
  Passes
  Scalar
  SelectionDAG
  Support
  Target
  TargetParser
  TransformUtils

  ADD_TO_COMPONENT
  WORUYU
  )

add_subdirectory(AsmParser)
add_subdirectory(Disassembler)
add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
