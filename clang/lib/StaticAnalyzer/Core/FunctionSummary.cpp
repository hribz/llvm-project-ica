//===- FunctionSummary.cpp - Stores summaries of functions. ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines a summary of a function gathered/used by static analysis.
//
//===----------------------------------------------------------------------===//

#include "clang/StaticAnalyzer/Core/PathSensitive/FunctionSummary.h"
#include "clang/AST/ASTContext.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Index/USRGeneration.h"
#include <string>

using namespace clang;
using namespace ento;

unsigned FunctionSummariesTy::getTotalNumBasicBlocks() {
  unsigned Total = 0;
  for (const auto &I : Map)
    Total += I.second.TotalBasicBlocks;
  return Total;
}

unsigned FunctionSummariesTy::getTotalNumVisitedBasicBlocks() {
  unsigned Total = 0;
  for (const auto &I : Map)
    Total += I.second.VisitedBasicBlocks.count();
  return Total;
}

static void generateUSRName(const Decl *D, std::string &ret) {
  SmallString<128> usr;
  index::generateUSRForDecl(D, usr);
  ret += std::to_string(usr.size());
  ret += ":";
  ret += usr.c_str();
}

void FunctionSummariesTy::dumpFunctionSummaries(StringRef filename) {
  std::string fs;
  // auto set_to_string = [](SetOfConstDecls soc) {
  //   std::string ret;
  //   for (auto it=soc.begin(); it!=soc.end(); it++) {
  //     // generateUSRName((*it)->getCanonicalDecl(), ret);
  //     ret += AnalysisDeclContext::getFunctionName((*it)->getCanonicalDecl());
  //     ret += "\n";
  //   }
  //   return ret;
  // };
  // for (auto it = Map.begin(); it != Map.end(); it++) {
  //   auto I = *it;
  //   if (I.second.TimesInlined == 0) {
  //     // skip this function if it has no callers
  //     continue;
  //   }
  //   // generateUSRName(I.first->getCanonicalDecl(), fs);
  //   fs += AnalysisDeclContext::getFunctionName(I.first->getCanonicalDecl());
  //   fs += "\n[\n";
  //   fs += set_to_string(I.second.Callers);
  //   fs += "]\n";
  // }

  int FD;
  std::error_code EC = llvm::sys::fs::openFileForWrite(
      filename, FD, llvm::sys::fs::CD_CreateAlways, llvm::sys::fs::OF_Text);

  // Writing over an existing file is not considered an error.
  if (EC == std::errc::file_exists) {
    // llvm::errs() << "file exists, overwriting" << "\n";
  } else if (EC) {
    llvm::errs() << "error writing into file" << "\n";
    return;
  } else {
    // llvm::errs() << "writing to the newly created file " << filename << "\n";
  }

  if (FD == -1) {
    llvm::errs() << "error opening file '" << filename << "' for writing FunctionSummaries!\n";
    return;
  }

  // llvm::raw_fd_ostream O(FD, /*shouldClose=*/ true);
  // O << fs;

  // // Output other information.
  // fs = "{\n";
  // for (auto it = Map.begin(); it != Map.end(); it++) {
  //   auto I = *it;
  //   fs += "\t\"";
  //   fs += AnalysisDeclContext::getFunctionName(I.first->getCanonicalDecl());
  //   fs += "\": {\n";
  //   fs += "\t\t\"TotalBasicBlocks\": " + std::to_string(I.second.TotalBasicBlocks) + ",\n";
  //   fs += "\t\t\"InlineChecked\": " + std::to_string(I.second.InlineChecked) + ",\n";
  //   fs += "\t\t\"MayInline\": " + std::to_string(I.second.MayInline) + ",\n";
  //   fs += "\t\t\"TimesInlined\": " + std::to_string(I.second.TimesInlined) + "\n";
  //   fs += "\t},\n";
  // }
  // fs += "}";

  // EC = llvm::sys::fs::openFileForWrite(
  //     filename+".sum", FD, llvm::sys::fs::CD_CreateAlways, llvm::sys::fs::OF_Text);

  // // Writing over an existing file is not considered an error.
  // if (EC == std::errc::file_exists) {
  //   // llvm::errs() << "file exists, overwriting" << "\n";
  // } else if (EC) {
  //   llvm::errs() << "error writing into file" << "\n";
  //   return;
  // } else {
  //   // llvm::errs() << "writing to the newly created file " << filename << "\n";
  // }

  // if (FD == -1) {
  //   llvm::errs() << "error opening file '" << filename << "' for writing FunctionSummaries!\n";
  //   return;
  // }

  // Output Function Summaries.
  for (auto it = Map.begin(); it != Map.end(); it++) {
    auto I = *it;
    fs += AnalysisDeclContext::getFunctionName(I.first->getCanonicalDecl());
    fs += "\n";
    fs += (std::to_string(I.second.TotalBasicBlocks) + "," + std::to_string(I.second.InlineChecked)) + ",";
    fs += (std::to_string(I.second.MayInline) + "," + std::to_string(I.second.TimesInlined));
    fs += "\n";
  }

  llvm::raw_fd_ostream O_(FD, /*shouldClose=*/ true);
  O_ << fs;
}