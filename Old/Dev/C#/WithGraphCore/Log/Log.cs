﻿using System;
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
using WithGraphCore.Environment;
using Newtonsoft.Json;

namespace WithGraphCore
{
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
        [Parameter]
        public logtype Logtype = logtype.info;

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            foreach(var Message in logging.read(Logtype))
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

    [PsClass]
    public class Logmessage
    {
        public DateTime Time = DateTime.Now;
        public logtype Type { get; set; }
        public string Source { get; set; }
        public string Message { get; set; }

        [PsPropertyHide]
        public string ID = logging.GenerateUinqueID();

        [PsPropertyHide]
        public String Version { get; set; }

        private CultureInfo provider = new CultureInfo("nb-NO");
        private string DatetimeOuptut = "MM.dd.yyyy HH:mm:ss.ffff";

        public void Parse(string Input)
        {
            var splitinput = Input.Split('|'); 
            Time = DateTime.ParseExact(splitinput[0],DatetimeOuptut,provider);
            Type = (logtype)Enum.Parse(typeof(logtype), splitinput[1]);
            Message = splitinput[2].Trim().Replace("#&#","\n");
            Source = splitinput[3].Trim();
        }

        public void Create(String Message, logtype type, string Source)
        {
            this.Message = string.Join(" ", Message).Replace("|", " ").Replace("\n","#&#").Replace("\r", "");
            this.Source = Source;
            this.Type = type;
        }

        public override string ToString ()
        {
            return string.Format("{0}|{1}|{2}\t|{3}", Time.ToString(DatetimeOuptut), Type.ToString(), Message, Source);
        }

    }

    public static class logging
    {
        private static List<Logmessage> InMemoryLog = new List<Logmessage>();
        private static String ID { get; set; }
        private static string Version { get; set; }

        public static string GenerateUinqueID()
        {
            if(string.IsNullOrEmpty(ID))
            {
                ID = Guid.NewGuid().ToString();
            }
            return ID;
        }

        public static string GetLogVersion()
        {
            if (string.IsNullOrEmpty(Version))
            {
                ID = "0.1";
            }
            return Version;
        }

        public static string write(object Message,logtype type = logtype.info, [CallerMemberName] string Source = "")
        {
            string Output = string.Join(" ", Message);
            Logmessage Logmessage = new Logmessage();
            Logmessage.Create(Output, type, Source);

            if (WGCEnvironment.IsCreated == false)
            {
                // If .Log File is not ready yet, write the message to Log in Memory
                InMemoryLog.Add(Logmessage);
            }
            else
            {
                InMemoryLog.Add(Logmessage);

                //Remove Files not used in 1 week
                List<string> DeletedLogFiles = new string[0].ToList();
                foreach (string logfile in Directory.EnumerateFiles(WGCEnvironment.LogDir))
                {
                    var Thisfile = File.GetLastWriteTimeUtc(logfile);
                    if (DateTime.UtcNow >= Thisfile.AddDays(7))
                    {
                        File.Delete(logfile);
                        var temp = write("Removing " + Path.GetFileName(logfile));
                        // Console.WriteLine(logfile); 
                        DeletedLogFiles.Add(logfile);
                    }
                }


                ////Write to log that you are removing old logs
                //foreach (string Logline in DeletedLogFiles.Where(m => m != ""))
                //{
                //    var temp = write("Removing " + Path.GetFileName(Logline));
                //}

                //Write For each line in memory log, write this to .log file
                using (StreamWriter sw = File.AppendText(WGCEnvironment.LogFile))
                {
                    foreach (Logmessage Line in InMemoryLog)
                    {
                        sw.WriteLine(Line.ToString());
                        LogToWeb(Line);
                    }
                }

                InMemoryLog.RemoveAll(item => item != null);
            }

            return Output;
        }  

        public static async Task LogToWeb(Logmessage Log)
        {
            JsonConvert.SerializeObject(Log, Formatting.Indented);
        }

        public static IEnumerable<Logmessage> read(logtype Logtype = logtype.error)
        {
            int LogTypeIntFilter = (int)Logtype;
            if (File.Exists(WGCEnvironment.LogFile))
            {
                // WriteVerbose("Reading from Graphlog @'" + Enviorment.LogFile + "'");
                foreach (string line in File.ReadAllLines(WGCEnvironment.LogFile))
                {
                    var Message = new Logmessage();
                    Message.Parse(line);
                    int ThismessagetypeInt = (int)Message.Type;
                    if (ThismessagetypeInt <= LogTypeIntFilter)
                    {
                        yield return Message;
                    }
                }
            }
        }
    }

    public enum logtype
    {
        info,
        error,
        verbose,
        debug      
    }
}
