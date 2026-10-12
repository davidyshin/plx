using System;
using System.Runtime.InteropServices;
using System.Drawing;
using System.IO;
using System.Reflection;
internal static class InstallerArguments {
  [DllImport("shell32.dll",SetLastError=true)] private static extern IntPtr CommandLineToArgvW([MarshalAs(UnmanagedType.LPWStr)]string command,out int count);
  [DllImport("kernel32.dll")] private static extern IntPtr LocalFree(IntPtr memory);
  private static int Main() {
    foreach(string value in new[]{@"C:\Program Files (x86)\World of Warcraft\_classic_beta_",@"C:\folder with spaces\", "", "quoted\"name", @"C:\plain"}) {
      int count; IntPtr args=CommandLineToArgvW("test.exe "+Program.Quote(value),out count);
      try { if(count!=2||Marshal.PtrToStringUni(Marshal.ReadIntPtr(args,IntPtr.Size))!=value) throw new Exception("Argument round-trip failed"); }
      finally { LocalFree(args); }
    }
    using(var form=new SetupForm()) using(var image=new Bitmap(form.Width,form.Height)) {
      form.ShowInTaskbar=false; form.Opacity=0; form.Show(); System.Windows.Forms.Application.DoEvents();
      form.DrawToBitmap(image,new Rectangle(0,0,form.Width,form.Height)); form.Hide();
      image.Save(Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location),"installer-preview.png"));
    }
    string fixture=Path.Combine(Path.GetTempPath(),"plx-play-"+Guid.NewGuid().ToString("N"));
    Directory.CreateDirectory(fixture);
    try {
      File.WriteAllText(Path.Combine(fixture,"WowB.exe"),"fixture only");
      File.WriteAllText(Path.Combine(fixture,"Wow.exe"),"fixture only");
      var command=SetupForm.PlayCommand(fixture);
      if(Path.GetFileName(command.FileName)!="explorer.exe" || command.Arguments!=Program.Quote(Path.Combine(fixture,"WowB.exe")) || command.WorkingDirectory!=fixture)
        throw new Exception("Play must select the installed beta client through the desktop shell");
      using(var form=new SetupForm()) {
        form.InstallationSucceeded(fixture);
        var button=(System.Windows.Forms.Button)typeof(SetupForm).GetField("install",BindingFlags.Instance|BindingFlags.NonPublic).GetValue(form);
        if(button.Text!="Play WoW") throw new Exception("Successful install must offer Play WoW");
      }
      File.Delete(Path.Combine(fixture,"WowB.exe"));
      if(SetupForm.PlayCommand(fixture).Arguments!=Program.Quote(Path.Combine(fixture,"Wow.exe"))) throw new Exception("Retail executable fallback failed");
      File.Delete(Path.Combine(fixture,"Wow.exe"));
      bool rejected=false;
      try { SetupForm.PlayCommand(fixture); } catch(FileNotFoundException) { rejected=true; }
      if(!rejected) throw new Exception("Missing executable must fail before closing setup");
    } finally { Directory.Delete(fixture,true); }
    Console.WriteLine("Executable installer checks passed: argument quoting, form rendering and Play WoW transition without launching or elevating.");return 0;
  }
}
