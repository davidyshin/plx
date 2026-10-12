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
    Console.WriteLine("Executable installer checks passed: argument quoting and actual form rendering without installing or elevating.");return 0;
  }
}
