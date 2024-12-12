add_clang_library(extractIncInfo 
  DiffLineManager.cpp 
  IncInfoCollectASTVisitor.cpp 
  IncInfoCollectConsumer.cpp

  LINK_LIBS
  clangAST
  clangAnalysis
  clangBasic
  clangLex

  DEPENDS
  ClangDriverOptions
)