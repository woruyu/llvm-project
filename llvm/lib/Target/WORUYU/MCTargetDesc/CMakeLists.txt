add_llvm_component_library(LLVMWORUYUDesc
  WORUYUMCTargetDesc.cpp
  WORUYUAsmBackend.cpp
  WORUYUInstPrinter.cpp
  WORUYUMCCodeEmitter.cpp
  WORUYUELFObjectWriter.cpp

  LINK_COMPONENTS
  MC
  WORUYUInfo
  Support
  TargetParser

  ADD_TO_COMPONENT
  WORUYU
  )
