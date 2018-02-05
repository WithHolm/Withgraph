using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;

namespace WithGraph
{
    [Cmdlet(VerbsCommon.Get,"Test")]
    public class GetTest:PSCmdlet
    {
        [Parameter(Mandatory = true)]
        public string[] name{get;set;}

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            foreach(String n in name)
            {
                WriteVerbose("testing " + n);
                String testing = "hello " + n;
                WriteObject(testing);
            }
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }
}
