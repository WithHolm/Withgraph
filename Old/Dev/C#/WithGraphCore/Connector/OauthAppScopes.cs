using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using HtmlAgilityPack;
using System.IO;
using Newtonsoft.Json;
using System.ComponentModel.Design.Serialization;
using System.Management.Automation;
using WithGraphCore.Environment;

namespace WithGraphCore.Connector
{
    [Cmdlet(VerbsCommon.Show, "OauthScopes")]
    public class Cmd_Show_OauthScopes : Cmdlet
    {
        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            OauthAppScopes Scopes = new OauthAppScopes();
            foreach(var item in Scopes.OauthScopes)
            {
                WriteObject(item);
            }
            // WriteObject(Scopes.OauthScopes.ToArray());
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }

    public class OauthAppScopes
    {
        public List<OauthScope> OauthScopes { get; set; }
        public List<OauthScope> Active { get; set; }

        async Task<List<OauthScope>> DownloadAsync(string URI)
        {
            var web = new HtmlWeb();
            var doc = await web.LoadFromWebAsync(URI);
            logging.write("Downloaded Info from: "+ URI, logtype.info);
            HtmlNodeCollection values = doc.DocumentNode
                    .SelectNodes("//tbody/tr");
            List<OauthScope> ret = new List<OauthScope>();
            foreach (HtmlNode Value in values)
            {
                ret.Add(new OauthScope().ParseFromString(Value.InnerText));
            }
            return ret; 
        }

        public OauthAppScopes()
        {
            DateTime Start = DateTime.Now;
            
            String CachePath = Path.Combine(WGCEnvironment.CacheDir, "OauthScopes.json");
            List<OauthScope> ThisOauthScopes = new List<OauthScope>();
            Task<List<OauthScope>> PreLoadScopesFromWeb = DownloadAsync("https://developer.microsoft.com/en-us/graph/docs/concepts/permissions_reference");

            if (File.Exists(CachePath))
            {
                logging.write("Start getting Oauth scopes from cache: " + CachePath, logtype.info);
                var test = JsonConvert.DeserializeObject<List<OauthScope>>(File.ReadAllText(CachePath));
                ThisOauthScopes = test;
            }
            else
            {
                logging.write("Start getting Oauth scopes from Internet", logtype.info);
                PreLoadScopesFromWeb.Wait(); 
                ThisOauthScopes = PreLoadScopesFromWeb.Result;
                File.WriteAllText(@CachePath, JsonConvert.SerializeObject(ThisOauthScopes.Where(m=>m!=null),Formatting.Indented));
            }

            DateTime Done = DateTime.Now;
            // Console.WriteLine(Done.ToString());
            TimeSpan TimeTaken = new TimeSpan(Done.Ticks - Start.Ticks);
            logging.write("Took " + TimeTaken.Milliseconds + " Miliseconds", logtype.debug);
            OauthScopes = ThisOauthScopes;
            
        }
    }

    [PsClass]
    public class OauthScope
    {     
        public string Permission { get; set; }
        public string Category {
            get {
                return Permission.Split('.')[0];
            }
        }
        public string ShortDescription { get; set; }
        public string LongDescription { get; set; }
        public bool Admin { get; set; }
        public bool Active { get; set; }

        [PsPropertyHide]
        public OauthScope ParseFromString(string Input)
        {
            string[] Lines = Input.Split(
                                new[] { "\r\n", "\r", "\n" },
                                StringSplitOptions.RemoveEmptyEntries
                            ); 
            if(Lines.Count() != 4)
            {
                return null;
            }

            //Raw = Input;
            Permission = Lines[0].Trim();
            ShortDescription = Lines[1].Trim();
            LongDescription = Lines[2].Trim();
            Admin = string.Equals(Lines[3], "No");
            return this;
        }

        [PsPropertyHide]
        public override string ToString()
        {
            return Permission;
        }
    }
}
