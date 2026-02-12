add_llvm_component_library(LLVMWORUYUAsmParser
  WORUYUAsmParser.cpp

  LINK_COMPONENTS
  MC
  MCParser
  WORUYUDesc
  WORUYUInfo
  Support

  ADD_TO_COMPONENT
  WORUYU
  )
