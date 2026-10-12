using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Text;
using System.Windows.Forms;
[assembly: AssemblyTitle("PlxTogether Setup")]
[assembly: AssemblyVersion("0.6.0.0")]
internal static class Program {
    internal static string Quote(string value) {
        var result = new StringBuilder("\""); int slashes = 0;
        foreach (char c in value) {
            if (c == '\\') { slashes++; continue; }
            if (c == '"') { result.Append('\\', slashes * 2 + 1); result.Append(c); }
            else { result.Append('\\', slashes); result.Append(c); }
            slashes = 0;
        }
        result.Append('\\', slashes * 2); return result.Append('"').ToString();
    }
    [STAThread] private static void Main() {
        Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new SetupForm());
    }
}
internal sealed class SetupForm : Form {
    private readonly TextBox folder = new TextBox(), log = new TextBox();
    private readonly Button install = new Button(), browse = new Button();
    private readonly Label status = new Label();
    private readonly ProgressBar progress = new ProgressBar();
    private bool working;
    private string installedClient;
    internal static ProcessStartInfo PlayCommand(string client) {
        foreach(string name in new[]{"WowB.exe","Wow.exe","WowClassic.exe"}) {
            string executable=Path.Combine(client,name);
            if(File.Exists(executable)) {
                // Hand launch to the desktop shell instead of inheriting setup's elevation.
                return new ProcessStartInfo {
                    FileName=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),"explorer.exe"),
                    Arguments=Program.Quote(executable), WorkingDirectory=client, UseShellExecute=true
                };
            }
        }
        throw new FileNotFoundException("WoW executable not found. Check your client folder.");
    }
    internal void InstallationSucceeded(string client) {
        installedClient=client; install.Text="Play WoW";
        browse.Enabled=false; folder.Enabled=false;
    }
    private readonly Color gold = Color.FromArgb(239,203,135), muted = Color.FromArgb(170,184,175);
    private Label TextLabel(string text, int x, int y, int w, int h, float size, Color color) {
        var label = new Label {Text=text, Left=x, Top=y, Width=w, Height=h, ForeColor=color, Font=new Font("Segoe UI",size)};
        Controls.Add(label); return label;
    }
    private void StyleButton(Button button, string text, int x, int y, int w) {
        button.Text=text; button.SetBounds(x,y,w,38); button.FlatStyle=FlatStyle.Flat;
        button.FlatAppearance.BorderColor=Color.FromArgb(65,78,69); button.ForeColor=gold;
        button.BackColor=Color.FromArgb(30,38,32); button.Font=new Font("Segoe UI",10);
        Controls.Add(button);
    }
    internal SetupForm() {
        Text="PlxTogether Setup"; ClientSize=new Size(600,580); StartPosition=FormStartPosition.CenterScreen;
        FormBorderStyle=FormBorderStyle.FixedDialog; MaximizeBox=false; BackColor=Color.FromArgb(16,19,18);
        Font=new Font("Segoe UI",10); AutoScaleMode=AutoScaleMode.Dpi;
        using (var stream=Assembly.GetExecutingAssembly().GetManifestResourceStream("PlxTogether.Logo")) {
            if(stream!=null) using(var image=Image.FromStream(stream)) {
                var picture=new PictureBox {Image=new Bitmap(image),SizeMode=PictureBoxSizeMode.Zoom,Left=26,Top=20,Width=64,Height=64}; Controls.Add(picture);
                using(var iconBitmap=new Bitmap(image,new Size(32,32))) { Icon=(Icon)Icon.FromHandle(iconBitmap.GetHicon()).Clone(); }
            }
        }
        TextLabel("PlxTogether",104,26,440,35,22,gold);
        TextLabel("Quest as a party. Or follow your own route.",106,65,440,26,10,muted);
        TextLabel("PlxTogether 0.6.0 + Questie + QuestieDB",28,111,544,30,12,Color.White);
        TextLabel("No downloads needed. Existing addon folders are backed up before updates.",28,148,544,45,10,muted);
        TextLabel("FOREVER CLIENT FOLDER",28,207,544,24,9,gold);
        folder.SetBounds(28,237,424,30); folder.Text=@"C:\Program Files (x86)\World of Warcraft\_classic_beta_";
        folder.BackColor=Color.FromArgb(29,35,31); folder.ForeColor=Color.White; folder.BorderStyle=BorderStyle.FixedSingle; Controls.Add(folder);
        StyleButton(browse,"Browse…",466,233,106);
        browse.Click+=delegate { using(var picker=new FolderBrowserDialog {Description="Select the Forever client folder containing WowB.exe",SelectedPath=folder.Text}) if(picker.ShowDialog(this)==DialogResult.OK) folder.Text=picker.SelectedPath; };
        StyleButton(install,"Install addons",28,287,180); install.BackColor=gold; install.ForeColor=Color.FromArgb(20,25,21); install.Click+=Install;
        status.SetBounds(222,291,350,34); status.ForeColor=muted; status.Text="Close WoW before installing."; Controls.Add(status);
        progress.SetBounds(28,338,544,5); progress.Style=ProgressBarStyle.Continuous; Controls.Add(progress);
        log.SetBounds(28,360,544,139); log.Multiline=true; log.ReadOnly=true; log.ScrollBars=ScrollBars.Vertical;
        log.BackColor=Color.FromArgb(24,30,26); log.ForeColor=muted; log.BorderStyle=BorderStyle.FixedSingle; Controls.Add(log);
        log.Text="Ready. Select your game folder, then install.\r\n";
        TextLabel("After installing: enable the addons, then type /plx for your route.\n/plx demo runs the simulated test. /plx live returns to your character.",28,518,544,52,10,muted);
        FormClosing+=delegate(object sender,FormClosingEventArgs e) { if(working) { e.Cancel=true; status.Text="Please wait for installation to finish."; } };
    }
    private void Append(string value) {
        if(String.IsNullOrEmpty(value)||IsDisposed)return;
        BeginInvoke((Action)delegate { log.AppendText(value+Environment.NewLine); });
    }
    private void Install(object sender,EventArgs e) {
        if(installedClient!=null) {
            try { Process.Start(PlayCommand(installedClient)); Close(); }
            catch(Exception error) { status.Text="Could not launch WoW. Try again or open it normally."; Append(error.Message); }
            return;
        }
        string root=AppDomain.CurrentDomain.BaseDirectory;
        string script=Path.Combine(root,"Support","Install-Friends.ps1");
        if(!File.Exists(script)) script=Path.Combine(root,"Install-Friends.ps1");
        if(!File.Exists(script)||!Directory.Exists(Path.Combine(root,"AddOns","Questie"))||!Directory.Exists(Path.Combine(root,"AddOns","QuestieDB"))||!File.Exists(Path.Combine(root,"AddOns","PlxTogether","PlxTogether.toc"))) {
            MessageBox.Show(this,"Extract the entire PlxTogether-Friends.zip first. Keep this executable beside the Support and AddOns folders.","Complete package required",MessageBoxButtons.OK,MessageBoxIcon.Information); return;
        }
        string client;
        try { client=Path.GetFullPath(folder.Text.Trim().Trim('"')); } catch { status.Text="Choose a valid client folder."; return; }
        if(!File.Exists(Path.Combine(client,"WowB.exe"))&&!File.Exists(Path.Combine(client,"Wow.exe"))&&!File.Exists(Path.Combine(client,"WowClassic.exe"))) { status.Text="WoW executable not found in this folder."; return; }
        working=true; install.Enabled=false; browse.Enabled=false; folder.Enabled=false; progress.Style=ProgressBarStyle.Marquee; status.Text="Installing and verifying files…";
        var process=new Process();
        process.StartInfo=new ProcessStartInfo {
            FileName=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"),
            Arguments="-NoProfile -ExecutionPolicy Bypass -File "+Program.Quote(script)+" -ClientPath "+Program.Quote(client),
            UseShellExecute=false,CreateNoWindow=true,WindowStyle=ProcessWindowStyle.Hidden,RedirectStandardOutput=true,RedirectStandardError=true
        };
        process.OutputDataReceived+=delegate(object o,DataReceivedEventArgs args) { Append(args.Data); };
        process.ErrorDataReceived+=delegate(object o,DataReceivedEventArgs args) { Append(args.Data); };
        process.EnableRaisingEvents=true;
        process.Exited+=delegate {
            int code=process.ExitCode;
            BeginInvoke((Action)delegate {
                working=false; install.Enabled=true; browse.Enabled=true; folder.Enabled=true; progress.Style=ProgressBarStyle.Continuous; progress.Value=code==0?100:0;
                status.Text=code==0?"Installed and verified. Ready to play!":"Installation stopped. See details below.";
                status.ForeColor=code==0?Color.FromArgb(140,210,171):Color.FromArgb(240,155,131);
                if(code==0) InstallationSucceeded(client);
            });
        };
        try { process.Start(); process.BeginOutputReadLine(); process.BeginErrorReadLine(); }
        catch(Exception error) { working=false; install.Enabled=true; browse.Enabled=true; folder.Enabled=true; progress.Style=ProgressBarStyle.Continuous; status.Text="Could not start installation."; Append(error.Message); }
    }
}
