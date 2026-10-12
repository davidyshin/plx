$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -eq 'Core') {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.IO; using System.Drawing; using System.Drawing.Drawing2D;
public static class PlxMedia {
  static void Save(Bitmap image, string path) {
    using(var writer = new BinaryWriter(File.Create(path))) {
      writer.Write(new byte[]{0,0,2,0,0,0,0,0,0,0,0,0});
      writer.Write((ushort)image.Width); writer.Write((ushort)image.Height); writer.Write((byte)32); writer.Write((byte)40);
      for(int y=0;y<image.Height;y++) for(int x=0;x<image.Width;x++) {
        Color c=image.GetPixel(x,y); writer.Write(c.B); writer.Write(c.G); writer.Write(c.R); writer.Write(c.A);
      }
    }
  }
  public static void Logo(string source,string output) {
    using(var original=Image.FromFile(source)) using(var bitmap=new Bitmap(256,256)) {
      using(var g=Graphics.FromImage(bitmap)) { g.InterpolationMode=InterpolationMode.HighQualityBicubic; g.DrawImage(original,0,0,256,256); }
      Save(bitmap,output);
    }
  }
  public static void Pin(string output) {
    using(var bitmap=new Bitmap(128,128)) {
      for(int y=0;y<128;y++) for(int x=0;x<128;x++) {
        double r=Math.Sqrt((x-63.5)*(x-63.5)+(y-63.5)*(y-63.5));
        int a=(int)(255*Math.Max(0,Math.Min(1,60-r)));
        int c=r<48?22:(r<55?245:5); bitmap.SetPixel(x,y,Color.FromArgb(a,c,c,c));
      }
      Save(bitmap,output);
    }
  }
}
'@
$media = Join-Path $PSScriptRoot 'addon\PlxTogether\Media'
New-Item -ItemType Directory -Path $media -Force | Out-Null
# Game texture format, scaled for UI use; retain the original artwork.
[PlxMedia]::Logo((Join-Path $PSScriptRoot '..\..\public\paddington-bear-logo.png'), "$media\paddington.tga")
[PlxMedia]::Pin("$media\route-pin.tga")
Write-Host 'Generated WoW-compatible logo and route-marker textures.'
