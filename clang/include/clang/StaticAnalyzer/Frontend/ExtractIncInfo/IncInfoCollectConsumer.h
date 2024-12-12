#include "clang/StaticAnalyzer/Frontend/ExtractIncInfo/IncInfoCollectASTVisitor.h"

#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Analysis/AnalysisDeclContext.h"
#include "clang/Analysis/CallGraph.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Index/USRGeneration.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/raw_ostream.h"

namespace clang {

namespace iic {

class IncInfoCollectConsumer : public clang::ASTConsumer {
public:
  explicit IncInfoCollectConsumer(ASTContext *Ctx, Preprocessor &PP, CallGraph &CG, std::string &diffPath, const IncOptions &incOpt);

  bool HandleTopLevelDecl(DeclGroupRef DG) override;

  void HandleTopLevelDeclInObjCContainer(DeclGroupRef DG) override;

  void storeTopLevelDecls(DeclGroupRef DG);

  void HandleTranslationUnit(clang::ASTContext &Context) override;

  static void getUSRName(const Decl *D, std::string &Str);

  void DumpCallGraph();

  void DumpFunctionsNeedReanalyze();

  void propogateReanalyzeAttribute();

private:
  Preprocessor &PP;
  llvm::StringRef MainFilePath;
  DiffLineManager DLM;
  const IncOptions &IncOpt;
  CallGraph &CG;
  IncInfoCollectASTVisitor IncVisitor;
  std::deque<Decl *> LocalTUDecls;
  std::unordered_set<const Decl *> FunctionsNeedReanalyze;
};

} // namespace iic
} // namespace clang