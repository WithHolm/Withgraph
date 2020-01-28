using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Security;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Newtonsoft.Json;
using static WithGraphCore.Connector.WithHelp;

namespace WithGraphCore.Connector
{

    public class Authenticate
    {
        public String DiscoveryURL { get; set; }
        public String ClientID { get; set; }
        private OpenIDConfig openIDConfig { get; set; }
        private List<OauthScope> oauthScopes { get; set; }
        public String InstanceDiscovery { get;set; }

        public void AcquireToken(GraphProfile graphProfile, 
            string state = "", 
            String ResourceURI = "https://graph.microsoft.com"
            )
        {
            logging.write("Starting new authentication to resource '" + ResourceURI + "'", logtype.verbose);
            // logging.write(graphProfile.ToString());
            if(string.IsNullOrEmpty(state))
            {
                state = new Guid().ToString().Replace("-", string.Empty);
            }

            openIDConfig = GetOpenIDConfig(graphProfile.Tenant);
            graphProfile.TenantID = GetTenantIDFromConfig(openIDConfig);
            SetInstanceDiscoveryURL(openIDConfig.authorization_endpoint);
            // InstanceDiscovery = openIDConfig.authorization_endpoint;
            logging.write("DiscoveryURL =  " + InstanceDiscovery);
            //graphProfile.
        }

        private void SetInstanceDiscoveryURL (String URI)
        {
            InstanceDiscovery = string.Format("{0}{1}","https://login.microsoftonline.com/common/discovery/instance?api-version=1.1&authorization_endpoint=",URI);
        }

        #region TenantID And Config
        public static Guid GetTenantID(string Tenant)
        {
            return GetTenantIDFromConfig(GetOpenIDConfig(Tenant));
        }

        private static Guid GetTenantID(OpenIDConfig openIdconfig)
        {
            return GetTenantIDFromConfig(openIdconfig);
        }

        private static Guid GetTenantIDFromConfig(OpenIDConfig openIDConfig)
        {
            Guid _TenantID = new Guid();
            try
            {
                Guid newGuid;
                IEnumerable<String> _TempGuid = openIDConfig.authorization_endpoint.Split('/').Where(m => Guid.TryParse(m, out newGuid));
                _TenantID = Guid.Parse(_TempGuid.ToArray()[0]);
            }
            catch (Exception E)
            {
                throw new ArgumentException(string.Format("Could not parse configuration {0}", E.ToString()));
            }
            return _TenantID;
        }

        private static OpenIDConfig GetOpenIDConfig(String Tenant)
        {
            if(string.IsNullOrEmpty(Tenant))
            {
                throw new ParameterBindingException("tenantname cannot be nothing");
            }
            //logging.write(string.Format("Getting .wellknown from MS OpenID config for tenant '{0}'", Tenant), logtype.info, "Authenticate.GetOpenIDConfig");
            String OIDConfigURL = string.Format("https://login.windows.net/{0}/.well-known/openid-configuration", Tenant);
            var Client = new System.Net.WebClient();
            logging.write(string.Format("Downloading address '{0}'", OIDConfigURL), logtype.info, "Authenticate.GetOpenIDConfig");
            return JsonConvert.DeserializeObject<OpenIDConfig>(Client.DownloadString(OIDConfigURL));
        }

        //JsonDocument that answers to https://login.windows.net/{Domain}/.well-known/openid-configuration 
        private class OpenIDConfig
        {
            public string authorization_endpoint { get; set; }
            public string token_endpoint { get; set; }
            public List<string> token_endpoint_auth_methods_supported { get; set; }
            public string jwks_uri { get; set; }
            public List<string> response_modes_supported { get; set; }
            public List<string> subject_types_supported { get; set; }
            public List<string> id_token_signing_alg_values_supported { get; set; }
            public bool http_logout_supported { get; set; }
            public bool frontchannel_logout_supported { get; set; }
            public string end_session_endpoint { get; set; }
            public List<string> response_types_supported { get; set; }
            public List<string> scopes_supported { get; set; }
            public string issuer { get; set; }
            public List<string> claims_supported { get; set; }
            public bool microsoft_multi_refresh_token { get; set; }
            public string check_session_iframe { get; set; }
            public string userinfo_endpoint { get; set; }
            public string tenant_region_scope { get; set; }
            public string cloud_instance_name { get; set; }
            public string cloud_graph_host_name { get; set; }
            public string msgraph_host { get; set; }
            public string rbac_url { get; set; }
        }
        #endregion

        //https://login.microsoftonline.com/59c8bfd7-d9bd-4dc4-a960-a3aa033e009e/oauth2/authorize?resource=https%3A%2F%2Fgraph.microsoft.com&client_id=d1ddf0e4-d672-4dae-b554-9d5bdfd93547&response_type=code&haschrome=1&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&login_hint=philip.meholm%40live.com&client-request-id=891c3644-aaee-4a28-9c6e-bdfc03395629&x-client-SKU=PCL.Desktop&x-client-Ver=3.19.3.10102&x-client-CPU=x64&x-client-OS=Microsoft+Windows+NT+10.0.16299.0

        //"https://login.microsoftonline.com/common/discovery/instance?api-version=1.1&authorization_endpoint=https://login.microsoftonline.com/59c8bfd7-d9bd-4dc4-a960-a3aa033e009e/oauth2/authorize"
    }

    public class URLParameters
    {
        public URLParameters()
        {
        }

        public URLParameters(Uri URL)
        {
            var t = URLParameters.Deserialize(URL);
            this.Base = t.Base;
            this.Parameters = t.Parameters;
        }

        public String Base { get; set; }
        public Dictionary<string, string> Parameters { get; set; }

        public static URLParameters Deserialize(Uri URL)
        {
            logging.write("Deserialising new url: '" + URL.ToString() + "'", logtype.verbose, "URLParameters.Deserialize");
            
            URLParameters Return = new URLParameters();

            Return.Base = URL.OriginalString.Substring(0, (URL.OriginalString.Length - URL.Query.Length));
            Return.Parameters = new Dictionary<string, string>();
            URL.Query.Substring(1).Split('&').ToList<string>().ForEach(
                    m =>
                    Return.Parameters.Add(m.Split('=')[0].ToString(), m.Split('=')[1].ToString())
                );
            return Return;
        }

        public string Serialize()
        {
            if(Parameters.Count > 0)
            {
                return this.Base+ "?" + string.Join("&", getDictionarystring());
            }
            else
            {
                return this.Base;
            }
        }

        private IEnumerable<string> getDictionarystring()
        {
            foreach(var item in Parameters)
            {
                yield return string.Format("{0}={1}", item.Key, item.Value);
            }
        }

        public void Addparameter(string Key,string Value)
        {
            this.Parameters.Add(Key, Value);
        }

        public override bool Equals(object obj)
        {
            return base.Equals(obj);
        }

        public override int GetHashCode()
        {
            return base.GetHashCode();
        }

        public override string ToString()
        {
            return JsonConvert.SerializeObject(this, Formatting.None);
            // return "{" + string.Join(",", this.Parameters.Select(kv => kv.Key + "=" + kv.Value).ToArray()) + "}";
        }
    }

    public class Authtoken
    {
        public DateTime ExpiresOn { get; private set; }
        public string Tenant { get; private set; }
        public TokenType TokenType { get; private set; }
        public string Token { get; private set; }
        public OauthAppScopes OauthScope = new OauthAppScopes();

        Authtoken(string TokenString,string tenant)
        {
            Tenant = tenant;
            ExpiresOn = DateTime.Now;

            string[] TokenSplit = TokenString.Split(' ');

            //Bearer ReallyLongTokenString.....
            if (TokenSplit.Count() == 2)
            {
                ExpiresOn = DateTime.Now;
                TokenType = (TokenType)Enum.Parse(typeof(TokenType),TokenSplit[0]);
                Token = TokenSplit[2];
                
            }
            //TokenString
            else if(TokenSplit.Count() == 1)
            {
                foreach (TokenType TType in Enum.GetValues(typeof(TokenType)))
                {
                    if(TokenString == TType.ToString())
                    {
                        throw new ArgumentException("Cannot create token object on just Tokentype. You need to have string 'TOKENTYPE TokenAuthorisationCode' ");
                    }
                }

                TokenType = TokenType.Bearer;
                Token = TokenSplit[0];
            }
            else
            {
                //! Create proper throw
                throw new ArgumentException("Authtoken wrongly set. You need to have the following string 'TOKENTYPE TokenAuthorisationCode' ") ;
            }
        }

        override public string ToString()
        {
            return string.Format("{0} {1}", TokenType.ToString().ToUpper(), Token);
        }
    }

    public enum TokenType
    {
        Bearer
    }



    //[Cmdlet(VerbsCommunications.Connect, "GraphApi")]
    //public class ConnectGraphApi : Cmdlet
    //{
    //    [Parameter(Position = 0, ParameterSetName = "Credentials")]
    //    public PSCredential Credential { get; set; }
    //    [Parameter(Position = 1)]
    //    public String applicationID { get; set; }

    //    //public AzureAccount AzureEnviorment { get; set; }

    //    protected override void BeginProcessing()
    //    {
    //        //var AzureEnvName = (new AzureEnvironment()).Name;
    //        //if (AzureRmProfileProvider.Instance.Profile.Environments.ContainsKey(AzureEnvName))
    //        //{
    //        //    var _AzureEnviorment = AzureRmProfileProvider.Instance.Profile.Environments[AzureEnvName];

    //        //    logging.write(string.Format("Current Azure Enviorment: {0}", _AzureEnviorment), logtype.verbose);
    //        //    WriteVerbose(string.Format("Current Azure Enviorment: {0}", _AzureEnviorment));
    //        //    AzureSession.NewSessionstate();
    //        //    AzureSession.AzureEnvironment = _AzureEnviorment;
    //        //}
    //        base.BeginProcessing();
    //    }

    //    protected override void ProcessRecord()
    //    {
    //        //logging.write("Creating new azure session", logtype.verbose);
    //        //GraphAccount Account = new GraphAccount();
    //        ////Account.SetProperty(AzureAccount.Property.Tenants, this.tenantid);
    //        //if (Credential != null)
    //        //{
    //        //    Account.Id = Credential.UserName;
    //        //    Account.Type = GraphAccount.AccountType.User;
    //        //}
    //        //SecureString Password = new SecureString();
    //        //if(parameterse)

    //        base.ProcessRecord();
    //    }

    //    protected override void EndProcessing()
    //    {
    //        base.EndProcessing();
    //    }
    //}
}
