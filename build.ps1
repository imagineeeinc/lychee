nimble build --d:release
cd assembler
nimble build --d:release
cd ..
$compress = @{
  Path = "./lychee.exe", "assembler/lasm.exe", "docs", "examples", "README.md", "lychee.png"
  CompressionLevel = "Fastest"
  DestinationPath = "lychee-build.zip"
}
Compress-Archive @compress