using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;

namespace WithGraph.Connector
{
    [Cmdlet(VerbsCommon.Join, "Uri")]
    public class JoinUri : Cmdlet
    {
        [Parameter (Position =0)]
        public object parent { get; set; }
        [Parameter(Position = 1)]
        public object child { get; set; }

        private string _parent { get; set; }
        private string _child { get; set; }

        protected override void BeginProcessing()
        {
            _parent = parent.ToString();
            _child = child.ToString();
            if(string.IsNullOrEmpty(_parent) |string.IsNullOrEmpty(_child))
            {
                throw new ArgumentNullException("Need both parent and child to be able to join them");
            }
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            if(_parent.EndsWith("/"))
            {
                _parent = _parent.Substring(0, _parent.Length - 1);
            }
            if(_child.StartsWith("/"))
            {
                _child = _child.Substring(1, _child.Length - 1);
            }

            WriteObject(string.Format("{0}/{1}", _parent, _child));
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }
}
