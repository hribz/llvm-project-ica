#include "clang/StaticAnalyzer/Frontend/ExtractIncInfo//DiffLineManager.h"

#include <cstddef>
#include <fstream>
#include <iostream>
#include <iterator>
#include <optional>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Analysis/AnalysisDeclContext.h"
#include "clang/Analysis/CallGraph.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Index/USRGeneration.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/raw_ostream.h"

namespace clang {
namespace iic {

using SetOfConstDecls = llvm::DenseSet<const Decl *>;

class IncOptions {
public:
  bool PrintLoc = false;
  bool ClassLevelTypeChange = true;
  bool FieldLevelTypeChange = false;

  bool DumpToFile = true;
  bool DumpUSR = false;
  bool CTU = false;
};

class DeclRefFinder : public RecursiveASTVisitor<DeclRefFinder> {
public:
  bool VisitDeclRefExpr(DeclRefExpr *DRE) {
    FoundedDecls.push_back(DRE->getFoundDecl());
    return true;
  }

  bool VisitMemberExpr(MemberExpr *E) {
    auto *member = E->getMemberDecl();
    FoundedDecls.push_back(member);
    return true;
  }

  bool VisitCXXConstructExpr(CXXConstructExpr *E) {
    // Global constant will not propogate through CXXConstructExpr
    return false;
  }

  std::vector<const Decl *> getFoundedRefDecls() const { return FoundedDecls; }

  void clearRefDecls() { FoundedDecls.clear(); }

private:
  std::vector<const Decl *> FoundedDecls;
};

class IncInfoCollectASTVisitor
    : public RecursiveASTVisitor<IncInfoCollectASTVisitor> {
public:
  explicit IncInfoCollectASTVisitor(
      ASTContext *Context, DiffLineManager &dlm, CallGraph &CG,
      std::unordered_set<const Decl *> &FuncsNeedRA, const IncOptions &incOpt)
      : Context(Context), FunctionsNeedReanalyze(FuncsNeedRA), DLM(dlm), CG(CG),
        IncOpt(incOpt) {}

  bool isGlobalConstant(const Decl *D);

  // Def
  bool VisitDecl(Decl *D);

  bool TraverseDecl(Decl *D);

  bool ProcessDeclRefExpr(Expr *const E, NamedDecl *const ND);

  // Use
  bool VisitDeclRefExpr(DeclRefExpr *DR);
  // Use
  bool VisitMemberExpr(MemberExpr *ME);

  void InsertCanonicalDeclToSet(std::unordered_set<const Decl *> &set,
                                const Decl *D) {
    set.insert(D->getCanonicalDecl());
  }

  int CountCanonicalDeclInSet(std::unordered_set<const Decl *> &set,
                              const Decl *D) {
    return set.count(D->getCanonicalDecl());
  }

  void DumpGlobalConstantSet();

  void DumpTaintDecls();

private:
  ASTContext *Context;
  std::unordered_set<const Decl *> GlobalConstantSet;
  // Decls have changed, the function/method use these should reanalyze.
  // Don't record changed functions and methods, they are recorded in
  // FunctionsNeedReanalyze. Just consider indirect factors which make
  // functions/methods need to reanalyze. Such as GlobalConstant and
  // class/struct change.
  std::unordered_set<const Decl *> TaintDecls;
  std::unordered_set<const Decl *> &FunctionsNeedReanalyze;
  DiffLineManager &DLM;
  CallGraph &CG;
  DeclRefFinder DRFinder;
  std::vector<const Decl *> inFunctionOrMethodStack;
  const IncOptions &IncOpt;
};

} // namespace iic
} // namespace clang