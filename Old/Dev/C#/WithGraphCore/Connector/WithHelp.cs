using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using Newtonsoft.Json;

namespace WithGraphCore.Connector
{
    [Cmdlet(VerbsCommon.Join, "Uri")]
    public class CMDJoinUri : Cmdlet
    {
        [Parameter (Position = 0)]
        public string parent { get; set; }
        [Parameter(Position = 1)]
        public string child { get; set; }

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        protected override void ProcessRecord()
        {
            WriteObject(WithHelp.JoinUri(parent.ToString(), child.ToString()));
            base.ProcessRecord();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }

    public static class WithHelp
    {
        public static string JoinUri (String _parent, String _child)
        {
            if (string.IsNullOrEmpty(_parent) | string.IsNullOrEmpty(_child))
            {
                throw new ArgumentNullException("Need both parent and child to be able to join them");
            }

            if (_parent.EndsWith("/"))
            {
                _parent = _parent.Substring(0, _parent.Length - 1);
            }
            if (_child.StartsWith("/"))
            {
                _child = _child.Substring(1, _child.Length - 1);
            }

            return string.Format("{0}/{1}", _parent, _child);
        }

        #region TenantID And Config
        //public static Guid GetTenantID(string Tenant)
        //{
        //    return GetTenantIDFromConfig(GetOpenIDConfig(Tenant));
        //}

        //public static Guid GetTenantID(OpenIDConfig openIDConfig)
        //{
        //    return GetTenantIDFromConfig(openIDConfig);
        //}

        //private static Guid GetTenantIDFromConfig(OpenIDConfig openIDConfig)
        //{
        //    Guid _TenantID = new Guid();
        //    try
        //    {
        //        Guid newGuid;
        //        IEnumerable<String> _TempGuid = openIDConfig.authorization_endpoint.Split('/').Where(m => Guid.TryParse(m, out newGuid));
        //        _TenantID = Guid.Parse(_TempGuid.ToArray()[0]);
        //    }
        //    catch (Exception E)
        //    {
        //        throw new ArgumentException(string.Format("Could not parse configuration {0}", E.ToString()));
        //    }
        //    return _TenantID;
        //}

        //public static OpenIDConfig GetOpenIDConfig(String Tenant)
        //{
        //    logging.write(string.Format("Getting .wellknown from MS OpenID config for tenant {0}", Tenant), logtype.info, "Withhelp.GetOpenIDConfig");
        //    String OIDConfigURL = string.Format("https://login.windows.net/{0}/.well-known/openid-configuration", Tenant);
        //    var Client = new System.Net.WebClient();
        //    return JsonConvert.DeserializeObject<OpenIDConfig>(Client.DownloadString(OIDConfigURL));
        //}

        ////JsonDocument that answers to https://login.windows.net/{Domain}/.well-known/openid-configuration 
        //public class OpenIDConfig
        //{
        //    public string authorization_endpoint { get; set; }
        //    public string token_endpoint { get; set; }
        //    public List<string> token_endpoint_auth_methods_supported { get; set; }
        //    public string jwks_uri { get; set; }
        //    public List<string> response_modes_supported { get; set; }
        //    public List<string> subject_types_supported { get; set; }
        //    public List<string> id_token_signing_alg_values_supported { get; set; }
        //    public bool http_logout_supported { get; set; }
        //    public bool frontchannel_logout_supported { get; set; }
        //    public string end_session_endpoint { get; set; }
        //    public List<string> response_types_supported { get; set; }
        //    public List<string> scopes_supported { get; set; }
        //    public string issuer { get; set; }
        //    public List<string> claims_supported { get; set; }
        //    public bool microsoft_multi_refresh_token { get; set; }
        //    public string check_session_iframe { get; set; }
        //    public string userinfo_endpoint { get; set; }
        //    public string tenant_region_scope { get; set; }
        //    public string cloud_instance_name { get; set; }
        //    public string cloud_graph_host_name { get; set; }
        //    public string msgraph_host { get; set; }
        //    public string rbac_url { get; set; }
        //}
        #endregion
    }
}
