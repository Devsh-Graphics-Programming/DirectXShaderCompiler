set(LLVM_LINK_COMPONENTS Support MSSupport) # HLSL Change

add_tablegen(clang-tblgen CLANG
  ClangASTNodesEmitter.cpp
  ClangAttrEmitter.cpp
  ClangCommentCommandInfoEmitter.cpp
  ClangCommentHTMLNamedCharacterReferenceEmitter.cpp
  ClangCommentHTMLTagsEmitter.cpp
  ClangDiagnosticsEmitter.cpp
  ClangSACheckersEmitter.cpp
  NeonEmitter.cpp
  TableGen.cpp
  )

if(EMSCRIPTEN)
  target_link_options(clang-tblgen PRIVATE "SHELL:-sNODERAWFS=1")
endif()
