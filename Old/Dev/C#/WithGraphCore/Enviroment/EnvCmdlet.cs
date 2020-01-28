using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace WithGraphCore.Environment
{
    [Cmdlet(VerbsCommon.Clear, "WGEnviorment")]
    public class ClearGraphEnviorment : Cmdlet
    {
        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            WGCEnvironment.Remove();
            WriteObject(string.Format("Removed CacheFolder @ {0}",WGCEnvironment.UserSave));
            WriteObject("Please restart this powershell session to create a new one");
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }
}
