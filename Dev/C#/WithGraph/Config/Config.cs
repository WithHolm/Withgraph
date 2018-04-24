using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Management.Automation;
using Microsoft.PowerShell.Commands;

namespace WithGraph
{
    [Cmdlet(VerbsCommon.Get, "GraphSettings")]
    public class GetConfig : Cmdlet
    {
        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            WriteObject((new GraphSettings()).Read());
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }

    public class GraphSettings
    {
        public GraphSettings() => Read();

        public RootObject Read()
        {
            Create();
            return JsonConvert.DeserializeObject<RootObject>(File.ReadAllText(WithGraphEnviorment.ConfigFile));
        }

        private static void Create()
        {
            if (!File.Exists(WithGraphEnviorment.ConfigFile))
            {
                File.WriteAllText(WithGraphEnviorment.ConfigFile, Properties.Resources.ConfigTemplate);
            }            
        }

    }

    public class Cache
    {
        public bool active { get; set; }
        public string OdataXmlTemplate { get; set; }
        public string ExpandcacheTemplate { get; set; }
        public bool CompressExpandCahce { get; set; }
    }

    public class Odata
    {
        public bool Useclasses { get; set; }
        public string GraphTypeDeserialiseString { get; set; }
        public Cache cache { get; set; }
    }

    public class Graphversion
    {
        public string Selected { get; set; }
        public List<string> Avalible { get; set; }
    }

    public class RootObject
    {
        public Odata odata { get; set; }
        public Graphversion Graphversion { get; set; }
    }


    //public class Settingsroot
    //{
    //    [JsonProperty("Odata")]
    //    public OdataSettings Odata { get; set; }
    //    [JsonProperty("GraphVersion")]
    //    public GraphVersionSettings GraphVersion { get; set; }
    //}

    //public class OdataSettings
    //{
    //    private string _GraphTypeDeserialiseString = "(.*).com\\/(?'Version'.*)\\/\\$metadata\\#(?'Odata'\\w*)(?'Entity'.*)";
    //    public bool UseClasses { get; set; }
    //    public CacheSettings cache { get; set; }
    //    public string GraphTypeDeserialiseString
    //    {
    //        //get;set;
    //        get
    //        {
    //            return _GraphTypeDeserialiseString;
    //        }
    //        set
    //        {

    //            string[] Testcases = new string[] { "https://graph.microsoft.com/v1.0/$metadata#users/$entity", "https://graph.microsoft.com/v1.0/$metadata#users", "https://graph.microsoft.com/beta/$metadata#users/$entity", "https://graph.microsoft.com/beta/$metadata#users" };

    //            foreach (string Testcase in Testcases)
    //            {
    //                //Console.WriteLine(value);
    //                //Console.WriteLine(Testcase);
    //                //Test if it matches
    //                //if (System.Text.RegularExpressions.Regex.IsMatch(Testcase, value))
    //                //{
    //                //    //test if it produces the correct groups
    //                //    var test = System.Text.RegularExpressions.Regex.Match(Testcase, value);
    //                //    if (string.IsNullOrEmpty(test.Groups["version"].Value))
    //                //    {
    //                //        logging.write("The regex-string you where to put in did not fulfill the criterias (version did not match)", logtype.error);
    //                //        throw new InvalidOperationException("The regex-string you where to put in did not fulfill the criterias (version did not match)");
    //                //    }
    //                //    //
    //                //    //    if (string.IsNullOrEmpty(test.Groups["odata"].Value))
    //                //    //    {
    //                //    //        throw new InvalidOperationException("The regex-string you where to put in did not fulfill the criterias (odata did not match)");
    //                //    //    }
    //                //    //    if (Testcase.EndsWith("$entity"))
    //                //    //    {
    //                //    //        if (string.IsNullOrEmpty(test.Groups["Entity"].Value))
    //                //    //        {
    //                //    //            throw new InvalidOperationException("The regexstring you where to put in did not fulfill the criterias (entity did not match)");
    //                //    //        }
    //                //    //    }
    //                //}
    //                //else
    //                //{
    //                //    throw new InvalidOperationException("The regexstring you where to put in did not fulfill the criterias (the entire string failed to match with odata feedback)");
    //                //}
    //            }
    //            _GraphTypeDeserialiseString = value;

    //        }
    //    }
    //    // public ConfigOdataCache Cache = new ConfigOdataCache();
    //}
    //public class CacheSettings
    //{
    //    public bool Active { get; set; }
    //    public string OdataXMLTemplate { get; set; }
    //    public string ExpandcacheTemplate { get; set; }
    //    public bool CompressExpandcache { get; set; }
    //}
    //public class GraphVersionSettings
    //{
    //    private string _selected { get; set; }
    //    public string GetTypesafeversion()
    //    {
    //        return Selected.Replace(".", string.Empty);
    //    }

    //    public string Selected { get;set; }
    //    public List<string> Avalible { get; set; }
    //}
}
