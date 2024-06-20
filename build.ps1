nimble build --threads:on --d:release -y
cd assembler
nimble build --d:release -y
cd ..
$compress = @{
  Path = "./lychee.exe", "assembler/lasm.exe", "docs", "examples", "README.md", "lychee.png"
  CompressionLevel = "Fastest"
  DestinationPath = "lychee-build-win.zip"
}
Compress-Archive @compress