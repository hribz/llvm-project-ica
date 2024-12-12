#include <optional>
#include <string>

#include "clang/AST/DeclBase.h"
#include "clang/AST/Decl.h"
#include "clang/Basic/SourceManager.h"
#include "llvm/Support/JSON.h"

namespace clang {
namespace iic {

class DiffLineManager {
public:
    DiffLineManager(const SourceManager &sm): DiffLines(std::nullopt), SM(sm) {}

    void Initialize(std::string &, std::string);

    bool isChangedLine(int , int );
    bool isChangedDecl(const Decl *D);

    std::optional<std::pair<int, int>> StartAndEndLineOfDecl(const Decl *);

    bool isNewFile() {
        return !DiffLines;
    }

    bool isNoChange() {
        return DiffLines && DiffLines->empty();
    }

    static void printJsonObject(const llvm::json::Object &);

    static void printJsonValue(const llvm::json::Value &);

    std::string MainFilePath;
private:
    // empty means no change, nullopt means new file.
    // We should consider no diff info as no change.
    std::optional<std::vector<std::pair<int, int>>> DiffLines; 
    const clang::SourceManager &SM;
};

} // namespace iic
} // namespace clang