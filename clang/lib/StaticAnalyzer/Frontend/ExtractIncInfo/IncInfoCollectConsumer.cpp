#include "clang/StaticAnalyzer/Frontend/ExtractIncInfo/IncInfoCollectConsumer.h"
#include "clang/AST/ASTContext.h"

using namespace clang;
using namespace iic;

IncInfoCollectConsumer::IncInfoCollectConsumer(ASTContext *Ctx,
                                               Preprocessor &PP, CallGraph &CG,
                                               std::string &diffPath,
                                               const IncOptions &incOpt)
    : PP(PP), DLM(Ctx->getSourceManager()), IncOpt(incOpt), CG(CG),
      IncVisitor(Ctx, DLM, CG, FunctionsNeedReanalyze, IncOpt) {
  const SourceManager &SM = Ctx->getSourceManager();
  FileID MainFileID = SM.getMainFileID();
  const FileEntry *FE = SM.getFileEntryForID(MainFileID);
  MainFilePath = FE->tryGetRealPathName();
  DLM.Initialize(diffPath, MainFilePath.str());
  // Don't print location information.
  // auto PrintPolicy = Context->getPrintingPolicy();
  // PrintPolicy.FullyQualifiedName = true;
  // PrintPolicy.TerseOutput = true;
  // PrintPolicy.PrintInjectedClassNameWithArguments = true;
  // Context->setPrintingPolicy(PrintPolicy);
}

void IncInfoCollectConsumer::HandleTranslationUnit(clang::ASTContext &Context) {
  // Don't run the actions if an error has occurred with parsing the file.
  DiagnosticsEngine &Diags = PP.getDiagnostics();
  if (Diags.hasErrorOccurred() || Diags.hasFatalErrorOccurred())
    return;

  if (DLM.isNoChange()) {
    // If there is no change in this file, just use old call graph.
    // DO NOTHING.
    llvm::errs() << DLM.MainFilePath << " has no change, do nothing.\n";
    return;
  }

  DumpCallGraph();
  if (DLM.isNewFile()) {
    // If this is a new file, we just output its callgraph.
    llvm::errs() << DLM.MainFilePath
                 << " is new, do not analyze changed functions.\n";
    return;
  }

  llvm::ReversePostOrderTraversal<clang::CallGraph *> RPOT(&CG);
  for (CallGraphNode *N : RPOT) {
    if (N == CG.getRoot())
      continue;
    Decl *D = N->getDecl();
    auto loc = DLM.StartAndEndLineOfDecl(D);
    if (!loc)
      continue;
    auto StartLoc = loc->first;
    auto EndLoc = loc->second;
    // CG only record canonical decls, so it's neccessary to
    // judge if there are changes in Function Definition scope.
    if (DLM.isChangedLine(StartLoc, EndLoc)) {
      FunctionsNeedReanalyze.insert(D);
    }
  }
  IncVisitor.TraverseDecl(Context.getTranslationUnitDecl());
  IncVisitor.DumpGlobalConstantSet();
  IncVisitor.DumpTaintDecls();
  DumpFunctionsNeedReanalyze();
}

void IncInfoCollectConsumer::getUSRName(const Decl *D, std::string &Str) {
  // Don't use this function if don't need USR representation
  // to avoid redundant string copy.
  D = D->getCanonicalDecl();
  SmallString<128> usr;
  index::generateUSRForDecl(D, usr);
  Str = std::to_string(usr.size());
  Str += ":";
  Str += usr.c_str();
}

void IncInfoCollectConsumer::DumpCallGraph() {
  std::ostream *OS = &std::cout;
  // `outFile`'s life time should persist until dump finished.
  // And don't create file if don't need to dump to file.
  std::shared_ptr<std::ofstream> outFile;
  if (IncOpt.DumpToFile) {
    std::string CGFile = MainFilePath.str() + ".cg";
    outFile = std::make_shared<std::ofstream>(CGFile);
    if (!outFile->is_open()) {
      llvm::errs() << "Error: Could not open file " << CGFile
                   << " for writing.\n";
      return;
    }
    OS = outFile.get();
  } else {
    *OS << "--- Call Graph ---\n";
  }

  llvm::ReversePostOrderTraversal<clang::CallGraph *> RPOT(&CG);
  for (CallGraphNode *N : RPOT) {
    if (N == CG.getRoot())
      continue;
    Decl *D = N->getDecl();
    if (IncOpt.DumpUSR) {
      std::string ret;
      getUSRName(D, ret);
      *OS << ret;
    } else {
      *OS << AnalysisDeclContext::getFunctionName(D->getCanonicalDecl());
    }
    if (IncOpt.PrintLoc) {
      auto loc = DLM.StartAndEndLineOfDecl(D);
      if (!loc)
        continue;
      auto StartLoc = loc->first;
      auto EndLoc = loc->second;
      *OS << " -> " << StartLoc << ", " << EndLoc;
    }
    *OS << "\n[\n";
    SetOfConstDecls CalleeSet;
    for (CallGraphNode::CallRecord &CR : N->callees()) {
      Decl *Callee = CR.Callee->getDecl();
      if (CalleeSet.contains(Callee))
        continue;
      CalleeSet.insert(Callee);
      if (IncOpt.DumpUSR) {
        std::string ret;
        getUSRName(Callee, ret);
        *OS << ret;
      } else {
        *OS << AnalysisDeclContext::getFunctionName(Callee->getCanonicalDecl());
      }
      if (IncOpt.PrintLoc) {
        auto loc = DLM.StartAndEndLineOfDecl(Callee);
        if (!loc)
          continue;
        auto StartLoc = loc->first;
        auto EndLoc = loc->second;
        *OS << " -> " << StartLoc << "-" << EndLoc;
      }
      *OS << "\n";
    }
    *OS << "]\n";
  }
  (*OS).flush();
  if (IncOpt.DumpToFile)
    outFile->close();
}

void IncInfoCollectConsumer::DumpFunctionsNeedReanalyze() {
  // Although there maybe no function changed, we still create .cf file.
  std::ostream *OS = &std::cout;
  std::shared_ptr<std::ofstream> outFile;
  if (IncOpt.DumpToFile) {
    std::string ReanalyzeFunctionsFile = MainFilePath.str() + ".cf";
    outFile = std::make_shared<std::ofstream>(ReanalyzeFunctionsFile);
    if (!outFile->is_open()) {
      llvm::errs() << "Error: Could not open file " << ReanalyzeFunctionsFile
                   << " for writing.\n";
      return;
    }
    OS = outFile.get();
  } else {
    *OS << "--- Functions Need to Reanalyze ---\n";
  }

  for (auto &D : FunctionsNeedReanalyze) {
    if (IncOpt.DumpUSR) {
      std::string ret;
      getUSRName(D, ret);
      *OS << ret;
    } else {
      *OS << AnalysisDeclContext::getFunctionName(D->getCanonicalDecl());
    }
    if (IncOpt.PrintLoc) {
      auto loc = DLM.StartAndEndLineOfDecl(D);
      if (!loc)
        continue;
      auto StartLoc = loc->first;
      auto EndLoc = loc->second;
      *OS << " -> " << StartLoc << "-" << EndLoc;
    }
    *OS << "\n";
  }
  (*OS).flush();
  if (IncOpt.DumpToFile)
    outFile->close();
}
