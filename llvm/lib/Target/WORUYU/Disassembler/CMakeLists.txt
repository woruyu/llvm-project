add_llvm_component_library(LLVMWORUYUDisassembler
  WORUYUDisassembler.cpp

  LINK_COMPONENTS
  MCDisassembler
  MC
  WORUYUInfo
  Support

  ADD_TO_COMPONENT
  WORUYU
)

