using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.IO;

namespace WithGraph
{
    [Cmdlet(VerbsCommon.Set, "GraphLog")]
    public class SetGraphLog : Cmdlet
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

    static public class logging
    {
        public static string write(object Message,logtype type)
        {
            string output = string.Join(" ", Message);
            return output;
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
