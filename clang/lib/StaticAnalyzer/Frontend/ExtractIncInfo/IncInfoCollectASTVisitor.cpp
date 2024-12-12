#include "clang/StaticAnalyzer/Frontend/ExtractIncInfo/IncInfoCollectASTVisitor.h"

using namespace clang;
using namespace iic;

bool IncInfoCollectASTVisitor::isGlobalConstant(const Decl *D) {
    D = D->getCanonicalDecl();
    if (!D->getDeclContext()) {
        // Top level Decl Context
        return false;
    }
    if (D->getDeclContext()->isFunctionOrMethod()) {
        return false;
    }
    if (const auto *VD = dyn_cast_or_null<VarDecl>(D)) {
        if (VD->getType().isConstQualified()) {
            return true;
        }
        return false;
    }
    if (const auto *EC = dyn_cast_or_null<EnumConstantDecl>(D)) {
        return true;
    }
    // if (auto FD = dyn_cast_or_null<FieldDecl>(D)) {
    //     if (FD->getType().isConstQualified()) {
    //         return true;
    //     }
    //     return false;
    // }
    return false;
}

bool IncInfoCollectASTVisitor::VisitDecl(Decl *D) {
    // record all changed global constants def
    if (isGlobalConstant(D)) {
        if (DLM.isChangedDecl(D)) {
            // Should we just record canonical decl?
            InsertCanonicalDeclToSet(GlobalConstantSet, D);
            InsertCanonicalDeclToSet(TaintDecls, D);
        } else {
            // this global constant is not changed, but maybe propogate by changed global constant
            DRFinder.TraverseDecl(D);
            for (const auto *RefD: DRFinder.getFoundedRefDecls()) {
                if (CountCanonicalDeclInSet(GlobalConstantSet, RefD)) {
                    InsertCanonicalDeclToSet(GlobalConstantSet, D);
                    InsertCanonicalDeclToSet(TaintDecls, D);
                    break;
                }
            }
            DRFinder.clearRefDecls();
            // No need to traverse this decl node and its children
            // note: It seems that `return false` will stop the visitor.
            // return false;
        }
    }
    
    if (isa<RecordDecl>(D)) {
        return true;
        // TODO: Is it neccessary to consider type change?
        RecordDecl *RD = dyn_cast<RecordDecl>(D);
        if (DLM.isChangedDecl(RD)) {
            InsertCanonicalDeclToSet(TaintDecls, RD);
        } else if(const auto *CXXRD = llvm::dyn_cast_or_null<CXXRecordDecl>(RD)) {
            // Traverse all base records.
            for (const auto &base: CXXRD->bases()) {
                auto *BaseDecl = base.getType()->getAsCXXRecordDecl();
                if (CountCanonicalDeclInSet(TaintDecls, BaseDecl)) {
                    InsertCanonicalDeclToSet(TaintDecls, CXXRD);
                    break;
                }
            }
        }
    } else if (isa<FieldDecl>(D)) {
        return true;
        FieldDecl *FD = dyn_cast<FieldDecl>(D);
        // record changed field
        if (DLM.isChangedDecl(FD)) {
            InsertCanonicalDeclToSet(TaintDecls, FD);
        }
        // TODO: if this field is used in `CXXCtorInitializer`, the correspond `CXXCtor` should be reanalyze
        
    } else if (isa<FunctionDecl>(D))  {

    }
    return true;
}

bool IncInfoCollectASTVisitor::TraverseDecl(Decl *D) {
    if (!D) {
        // D maybe nullptr when VisitTemplateTemplateParmDecl.
        return true;
    }
    bool isFunctionDecl = isa<FunctionDecl>(D);
    if (isFunctionDecl) {
        auto *FD = dyn_cast<FunctionDecl>(D);
        if (!FD->isThisDeclarationADefinition()) {
            // Just handle function definition, functions don't have definition
            // maybe inlined only when ctu analysis.
            return true;
        }
        if (CountCanonicalDeclInSet(FunctionsNeedReanalyze, D) || DLM.isChangedDecl(D)) {
            // If this `Decl` has been confirmed need to be reanalyzed, we don't need to traverse it.
            InsertCanonicalDeclToSet(FunctionsNeedReanalyze, D);
            return true;
        }
        inFunctionOrMethodStack.push_back(D->getCanonicalDecl()); // enter function/method
    }
    bool Result = clang::RecursiveASTVisitor<IncInfoCollectASTVisitor>::TraverseDecl(D);
    if (isFunctionDecl) {
        inFunctionOrMethodStack.pop_back(); // exit function/method
    }
    return Result;
}

// process all global constants use
bool IncInfoCollectASTVisitor::ProcessDeclRefExpr(Expr * const E, NamedDecl * const ND) {
    if (CountCanonicalDeclInSet(GlobalConstantSet, ND)) {
        
    }
    return true;
}

bool IncInfoCollectASTVisitor::VisitDeclRefExpr(DeclRefExpr *DR) {
    auto *ND = DR->getFoundDecl();
    if (!inFunctionOrMethodStack.empty() && CountCanonicalDeclInSet(TaintDecls, ND)) {
        // use changed decl, reanalyze this function
        InsertCanonicalDeclToSet(FunctionsNeedReanalyze, inFunctionOrMethodStack.back());
    }
    return ProcessDeclRefExpr(DR, ND);
}

bool IncInfoCollectASTVisitor::VisitMemberExpr(MemberExpr *ME) {
    auto *member = ME->getMemberDecl();
    if (!inFunctionOrMethodStack.empty() && CountCanonicalDeclInSet(TaintDecls, member)) {
        InsertCanonicalDeclToSet(FunctionsNeedReanalyze, inFunctionOrMethodStack.back());
    }
    // member could be VarDecl, EnumConstantDecl, CXXMethodDecl, FieldDecl, etc.
    if (isa<VarDecl, EnumConstantDecl>(member)) {
        ProcessDeclRefExpr(ME, member);
    } else {
        if (isa<CXXMethodDecl>(member)) {

        } else {
            const auto *field = cast<FieldDecl>(member);
        }
    }
    return true;
}

void IncInfoCollectASTVisitor::DumpGlobalConstantSet() {
    if (GlobalConstantSet.empty() || IncOpt.DumpToFile) {
        return;
    }
    llvm::outs() << "--- Decls in GlobalConstantSet ---\n";
    for (auto &D : GlobalConstantSet) {
        llvm::outs() << "  ";
        if (const NamedDecl *ND = llvm::dyn_cast_or_null<NamedDecl>(D)) {
            llvm::outs() << ND->getQualifiedNameAsString();
        } else {
            llvm::outs() << "Unnamed declaration";
        }
        llvm::outs() << ": " << "<" << D->getDeclKindName() << "> ";
        if (IncOpt.PrintLoc) {
            auto loc = DLM.StartAndEndLineOfDecl(D);
            if (loc)
                llvm::outs() << " -> " << loc->first << "-" << loc->second;
        }
        llvm::outs() << "\n";
    }
    llvm::outs().flush();
}

void IncInfoCollectASTVisitor::DumpTaintDecls() {
    if (TaintDecls.empty() || IncOpt.DumpToFile) {
        return;
    }
    llvm::outs() << "--- Taint Decls ---\n";
    for (auto &D : TaintDecls) {
        llvm::outs() << "  ";
        if (const NamedDecl *ND = llvm::dyn_cast_or_null<NamedDecl>(D)) {
            llvm::outs() << ND->getQualifiedNameAsString();
        } else {
            llvm::outs() << "Unnamed declaration";
        }
        llvm::outs() << ": " << "<" << D->getDeclKindName() << "> ";
        if (IncOpt.PrintLoc) {
            auto loc = DLM.StartAndEndLineOfDecl(D);
            if (loc)
                llvm::outs() << " -> " << loc->first << "-" << loc->second;
        }
        llvm::outs() << "\n";
    }
    llvm::outs().flush();
}