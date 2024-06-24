#!/bin/bash

cd $MCDC_HOME/llvm-project

# Patches that improve llvm-cov text output

cat > /tmp/llvm_cov_divider.patch << EOF
diff --git a/llvm/tools/llvm-cov/CoverageReport.cpp b/llvm/tools/llvm-cov/CoverageReport.cpp
index 49a35f2a9..00aea4039 100644
--- a/llvm/tools/llvm-cov/CoverageReport.cpp
+++ b/llvm/tools/llvm-cov/CoverageReport.cpp
@@ -102,8 +102,25 @@ void adjustColumnWidths(ArrayRef<StringRef> Files,

 /// Prints a horizontal divider long enough to cover the given column
 /// widths.
-void renderDivider(ArrayRef<size_t> ColumnWidths, raw_ostream &OS) {
-  size_t Length = std::accumulate(ColumnWidths.begin(), ColumnWidths.end(), 0);
+void renderDivider(raw_ostream &OS, const CoverageViewOptions &Options, bool isFileReport) {
+  size_t Length;
+  if (isFileReport) {
+    Length = std::accumulate(std::begin(FileReportColumns), std::end(FileReportColumns), 0);
+    if (!Options.ShowRegionSummary)
+      Length -= (FileReportColumns[1] + FileReportColumns[2] + FileReportColumns[3]);
+    if (!Options.ShowInstantiationSummary)
+      Length -= (FileReportColumns[7] + FileReportColumns[8] + FileReportColumns[9]);
+    if (!Options.ShowBranchSummary)
+      Length -= (FileReportColumns[13] + FileReportColumns[14] + FileReportColumns[15]);
+    if (!Options.ShowMCDCSummary)
+      Length -= (FileReportColumns[16] + FileReportColumns[17] + FileReportColumns[18]);
+  } else {
+    Length = std::accumulate(std::begin(FunctionReportColumns), std::end(FunctionReportColumns), 0);
+    if (!Options.ShowBranchSummary)
+      Length -= (FunctionReportColumns[7] + FunctionReportColumns[8] + FunctionReportColumns[9]);
+    if (!Options.ShowMCDCSummary)
+      Length -= (FunctionReportColumns[10] + FunctionReportColumns[11] + FunctionReportColumns[12]);
+  }
   for (size_t I = 0; I < Length; ++I)
     OS << '-';
 }
@@ -405,7 +422,7 @@ void CoverageReport::renderFunctionReports(ArrayRef<std::string> Files,
          << column("Miss", FunctionReportColumns[11], Column::RightAlignment)
          << column("Cover", FunctionReportColumns[12], Column::RightAlignment);
     OS << "\n";
-    renderDivider(FunctionReportColumns, OS);
+    renderDivider(OS, Options, false);
     OS << "\n";
     FunctionCoverageSummary Totals("TOTAL");
     for (const auto &F : Functions) {
@@ -418,7 +435,7 @@ void CoverageReport::renderFunctionReports(ArrayRef<std::string> Files,
       render(Function, DC, OS);
     }
     if (Totals.ExecutionCount) {
-      renderDivider(FunctionReportColumns, OS);
+      renderDivider(OS, Options, false);
       OS << "\n";
       render(Totals, DC, OS);
     }
@@ -544,7 +561,7 @@ void CoverageReport::renderFileReports(
                  Column::RightAlignment)
        << column("Cover", FileReportColumns[18], Column::RightAlignment);
   OS << "\n";
-  renderDivider(FileReportColumns, OS);
+  renderDivider(OS, Options, true);
   OS << "\n";

   std::vector<const FileCoverageSummary *> EmptyFiles;
@@ -563,7 +580,7 @@ void CoverageReport::renderFileReports(
       render(*FCS, OS);
   }

-  renderDivider(FileReportColumns, OS);
+  renderDivider(OS, Options, true);
   OS << "\n";
   render(Totals, OS);
 }

EOF
git apply /tmp/llvm_cov_divider.patch
cat > /tmp/llvm_cov_final_new_line.patch << EOF
diff --git a/llvm/tools/llvm-cov/SourceCoverageViewText.cpp b/llvm/tools/llvm-cov/SourceCoverageViewText.cpp
index cab60c2d9..2aa588e6d 100644
--- a/llvm/tools/llvm-cov/SourceCoverageViewText.cpp
+++ b/llvm/tools/llvm-cov/SourceCoverageViewText.cpp
@@ -43,7 +43,8 @@ Error CoveragePrinterText::createIndexFile(
   Report.renderFileReports(OSRef, SourceFiles, Filters);

   Opts.colored_ostream(OSRef, raw_ostream::CYAN) << "\n"
-                                                 << Opts.getLLVMVersionString();
+                                                 << Opts.getLLVMVersionString()
+                                                 << "\n";

   return Error::success();
 }
@@ -84,7 +85,8 @@ struct CoveragePrinterTextDirectory::Reporter : public DirectoryCoverageReport {

     Options.colored_ostream(OSRef, raw_ostream::CYAN)
         << "\n"
-        << Options.getLLVMVersionString();
+        << Options.getLLVMVersionString()
+        << "\n";

     return Error::success();
   }
EOF
git apply /tmp/llvm_cov_final_new_line.patch
cat > /tmp/llvm_cov_trim_abs_path.patch << EOF
diff --git a/llvm/tools/llvm-cov/CoverageReport.cpp b/llvm/tools/llvm-cov/CoverageReport.cpp
index 49a35f2a9..dc9f2f9c5 100644
--- a/llvm/tools/llvm-cov/CoverageReport.cpp
+++ b/llvm/tools/llvm-cov/CoverageReport.cpp
@@ -216,7 +216,7 @@ void CoverageReport::render(const FileCoverageSummary &File,
   if (IsDir)
     FileName += sys::path::get_separator();

-  OS << column(FileName, FileReportColumns[0], Column::NoTrim);
+  OS << column(FileName, FileReportColumns[0], Column::RightTrim);

   if (Options.ShowRegionSummary) {
     OS << format("%*u", FileReportColumns[1],
EOF
git apply /tmp/llvm_cov_trim_abs_path.patch

/usr/bin/time -v -o /tmp/time.log $MCDC_HOME/linux-mcdc/scripts/build-llvm.sh
