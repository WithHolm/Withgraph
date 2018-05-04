using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Data.OData;

namespace WithGraphCore.Connector
{
    class GraphFilter
    {
        private string _filter { get; set;}

        GraphFilter(string filter)
        {
            _filter = filter;
        }

        public string StartProcess()
        {
            //Microsoft.Data.OData.
            return _filter;
        }
    }
}
