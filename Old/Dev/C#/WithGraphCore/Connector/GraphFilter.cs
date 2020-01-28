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

        public void Parse(string filter)
        {
            _filter = filter;
        }

        public override string ToString()
        {
            return _filter;
        }
    }
}
