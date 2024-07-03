#!/bin/bash

cd $MCDC_HOME/llvm-project

# Patches that improve llvm-cov text output

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
