using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using HtmlAgilityPack;
using System.IO;
using Newtonsoft.Json;
using System.ComponentModel.Design.Serialization;

namespace WithGraph.Connector
{
    public class OauthApplicationScopes
    {
        public List<OauthScope> OauthScopes { get; set; }
        public List<OauthScope> Active { get; set; }

        async Task<List<OauthScope>> Download(string URI)
        {

            //var url = "https://developer.microsoft.com/en-us/graph/docs/concepts/permissions_reference";
            var web = new HtmlWeb();
            var doc = await web.LoadFromWebAsync(URI);
            HtmlNodeCollection values = doc.DocumentNode
                    .SelectNodes("//tbody/tr");
            List<OauthScope> ret = new List<OauthScope>();
            foreach (HtmlNode Value in values)
            {
                ret.Add(new OauthScope().ParseFromString(Value.InnerText));
            }
            return ret;
        }

        public OauthApplicationScopes()
        {
            DateTime Timestamp = new DateTime();
            logging.write("Start getting Oauth scopes");
            String CachePath = Path.Combine(WithGraphEnviorment.CacheDir, "OauthScopes.json");
            List<OauthScope> ThisOauthScopes = new List<OauthScope>();
            Task<List<OauthScope>> PreLoadScopesFromWeb = Download("https://developer.microsoft.com/en-us/graph/docs/concepts/permissions_reference");

            if (File.Exists(CachePath))
            {
                logging.write("Found local copy. Loading", logtype.verbose);

                //This is really badly written.. i could use some help here :/
                //Deserialise to dummy object cause i am stupid and dont know how to deserialise to a NOT generalised class
                List<OauthScopeDummy> _oauthScopes = JsonConvert.DeserializeObject<List<OauthScopeDummy>>(File.ReadAllText(CachePath));

                //Push the dummy object to a function to get the proper class..
                _oauthScopes.Where(m => m != null).ToList().ForEach(
                    m => ThisOauthScopes.Add(new OauthScope().ParseFromDummyobject(m))
                );
                //foreach (OauthScopeDummy item in _oauthScopes.Where(m=>m != null))
                //{
                //    // Console.WriteLine("Parsing " + item.Raw);
                //    OauthScope scope = new OauthScope();
                //    Console.WriteLine(scope.ParseFromString(item.Raw));
                //    ThisOauthScopes.Add(scope.ParseFromString(item.Raw));
                //}
                // _oauthScopes.ForEach(m => OauthScopes.Add(new OauthScope().ParseFromString(m.Raw)));
            }
            else
            {
                logging.write("No Local copy found. Downloading this shiet from the web. it might take a while :(", logtype.verbose);
                PreLoadScopesFromWeb.Wait();
                ThisOauthScopes = PreLoadScopesFromWeb.Result;
                File.WriteAllText(@CachePath, JsonConvert.SerializeObject(ThisOauthScopes.Where(m=>m!=null)));
                
            }

            OauthScopes = ThisOauthScopes;
            logging.write("Took " + ((new DateTime()) - Timestamp).Milliseconds + " Miliseconds", logtype.debug);
        }
    }

    public class OauthScopeDummy
    {
        public string permission { get; set; }
        public string ShortDescription { get; set; }
        public string LongDescription { get; set; }
        public string Admin { get; set; }
        public String Raw { get; set; }
    }

    [PsClass]
    public class OauthScope
    {     
        public String Permission { get; private set; }
        public String Category {
            get {
                return Permission.Split('.')[0];
            }
        }
        public String ShortDescription { get; private set; }
        public String LongDescription { get; private set; }
        public bool Admin { get; set; }

        [PsPropertyHide]
        public String Raw { get; set; }

        [PsPropertyHide]
        public OauthScope ParseFromString(String Input)
        {
            string[] Lines = Input.Split(
                                new[] { "\r\n", "\r", "\n" },
                                StringSplitOptions.RemoveEmptyEntries
                            );
            if(Lines.Count() != 4)
            {
                return null;
            }

            this.Raw = Input;
            this.Permission = Lines[0].Trim();
            this.ShortDescription = Lines[1].Trim();
            this.LongDescription = Lines[2].Trim();
            if(Lines[3] == "No")
            {
                this.Admin = false;
            }
            else
            {
                this.Admin = true;
            }
            return this;
        }

        [PsPropertyHide]
        public OauthScope ParseFromDummyobject(OauthScopeDummy Input)
        {
            return ParseFromString(Input.Raw);
        }

        [PsPropertyHide]
        public override string ToString()
        {
            return this.Permission;
        }
    }
}
