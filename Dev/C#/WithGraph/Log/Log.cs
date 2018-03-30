using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Diagnostics;
using System.IO;
using System.Collections;
using System.Globalization;
using System.Runtime.CompilerServices;
using System.Reflection;

namespace WithGraph
{
    [Cmdlet(VerbsCommunications.Write, "GraphLog")]
    public class TestGraphLog : Cmdlet
    {
        [Parameter(Position = 0)]
        public object Message { get; set; }

        [Parameter]
        public logtype Logtype = logtype.info;

        public string Output { get; set; }

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            Output = logging.write(Message, Logtype);

            if (Logtype == logtype.info)
            {
                WriteObject(Output);
            }
            else if (Logtype == logtype.verbose)
            {
                WriteVerbose(Output);
            }
            else if (Logtype == logtype.debug)
            {
                WriteDebug(Output);
            }
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }

    [Cmdlet(VerbsCommunications.Write, "GraphLog")]
    public class WriteGraphLog : Cmdlet
    {
        [Parameter(Position = 0)]
        public object Message { get; set; }

        [Parameter]
        public logtype Logtype = logtype.info;

        public string Output { get; set; }

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            Output = logging.write(Message, Logtype);

            if(Logtype == logtype.info)
            {
                WriteObject(Output);
            }
            else if(Logtype == logtype.verbose)
            {
                WriteVerbose(Output);
            }
            else if(Logtype == logtype.debug)
            {
                WriteDebug(Output);
            }
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }

    [Cmdlet(VerbsCommunications.Read, "GraphLog")]
    public class ReadGraphLog : Cmdlet
    {
        //public string Output { get; set; }

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            foreach(var Message in logging.read())
            {
                WriteObject(Message);
            }
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }

    public class Logmessage
    {
        public DateTime Time { get; set; }
        public logtype Type { get; set; }
        public string Source { get; set; }
        public string Message { get; set; }
        private CultureInfo provider = new CultureInfo("nb-NO");
        private string DatetimeOuptut = "MM.dd.yyyy HH:mm:ss.ffff";

        public void Parse(string Input)
        {
            var splitinput = Input.Split('|');
            //Console.WriteLine(string.Join("<->", splitinput));
            Time = DateTime.ParseExact(splitinput[0],DatetimeOuptut,provider);
            Type = (logtype)Enum.Parse(typeof(logtype), splitinput[1]);
            Message = splitinput[2].Trim();
            Source = splitinput[3].Trim();
        }

        public string Create(object Message, logtype type, string Source)
        {
            string Thismessage = string.Join(" ", Message);
            Thismessage = Thismessage.Replace("|", " ");
            this.Source = Source;



            //StackTrace stackTrace = new StackTrace();
            //var mth = new StackTrace().GetFrame(2).GetMethod();
            //var cls = mth.ReflectedType.Name;
            //Console.WriteLine(cls);
            //foreach (var trace in stackTrace.GetFrame(1).ToString())
            //{
            //    Console.WriteLine(trace.GetMethod());
            //}
            string Output = string.Format("{0}|{1}|\t{2}|{3}", DateTime.Now.ToString(DatetimeOuptut), type.ToString(), Thismessage, Source);
            return Output;
        }
        //public 
    }

    public static class logging
    {
        public static string write(object Message,logtype type = logtype.info, [CallerMemberName] string Source = "")
        {
            string output = string.Join(" ",Message);
            var _ToFile = new Logmessage();
            string Tofile = _ToFile.Create(Message, type, Source);

            for(int i = 0;i<10;i++)
            {
                StackFrame frame = new StackFrame(i);
                var method = frame.GetMethod();
                Console.WriteLine("Source: {2}, Name: {0}, Type: {1}", method.Name, method.DeclaringType, frame.GetFileName());
            }


            //Remove Files older than 1 week
            List<string> DeletedLogFiles = new string[0].ToList();
            foreach(string logfile in Directory.EnumerateFiles(Enviorment.LogDir))
            {
                var Thisfile = File.GetLastWriteTimeUtc(logfile);
                if(DateTime.UtcNow >= Thisfile.AddDays(7))
                {
                    File.Delete(logfile);
                    // Console.WriteLine(logfile);
                    DeletedLogFiles.Add(logfile);
                }
            }

            //if file does not exist
            if (!File.Exists(Enviorment.LogFile))
            {
                // Create a file to write to.
                using (StreamWriter sw = File.CreateText(Enviorment.LogFile))
                {
                    sw.WriteLine(Tofile);
                }
            }
            else
            {
                using (StreamWriter sw = File.AppendText(Enviorment.LogFile))
                {
                    sw.WriteLine(Tofile);
                }
            }

            foreach (string Logline in DeletedLogFiles.Where(m=>m != ""))
            {
                var temp = write("Removing " + Path.GetFileName(Logline));
            }

            return output;
        } 
        public static IEnumerable<Logmessage> read()
        {
            if (File.Exists(Enviorment.LogFile))
            {
                // WriteVerbose("Reading from Graphlog @'" + Enviorment.LogFile + "'");
                foreach (string line in File.ReadAllLines(Enviorment.LogFile))
                {
                    var Message = new Logmessage();
                    Message.Parse(line);
                    yield return Message;
                }
            }
        }
    }

    public enum logtype
    {
        info,
        verbose,
        debug,
        error
    }
}
