using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using Microsoft.IdentityModel.Clients.ActiveDirectory;

namespace WithGraph.Connector
{
    [Cmdlet(VerbsLifecycle.Invoke, "Graph")]
    public class InvokeGraphCall : Cmdlet
    {
        [Parameter(Position = 0)]
        public string call { get; set; }

        [Parameter(Position = 1)]
        public string version { get; set; }

        public string Method { get; set;}
        public object Body { get; set; }
        public string Filter { get; set; }
        public string Expand { get; set; }
        public SwitchParameter ReturnCallUrl { get; set; }
        
        private string[] _Versions = { "beta", "v1.0" };
        private string _query { get; set; }

        protected override void BeginProcessing()
        {
            if (string.IsNullOrEmpty(version))
            {
                version = _Versions[0];
            }

            if (!_Versions.Contains(version))
            {
                throw new ArgumentException(string.Format("The version {0} is not in the list of the supported versions: {1}", version, string.Join(",", version)));
            }
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {


            JoinUri test = new JoinUri();
            test.parent = version;
            test.child = call;
            foreach(var tst in test.Invoke())
            {
                WriteObject(tst);
            }
            // _query = ;
            //Process if filter or expand is defined

            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }
}
