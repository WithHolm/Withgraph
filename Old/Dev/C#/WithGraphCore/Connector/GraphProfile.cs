using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security;
using System.Text;
using System.Threading.Tasks;
using static WithGraphCore.Connector.WithHelp;

namespace WithGraphCore.Connector
{
    public class GraphProfileProvider
    {
        private GraphProfile _profile;

        public static GraphProfileProvider Instance { get; private set; }

        static GraphProfileProvider()
        {
            Instance = new GraphProfileProvider();
        }

        private GraphProfileProvider()
        {
            _profile = new GraphProfile();
        }

        public GraphProfile Profile
        {
            get
            {
                return _profile;
            }
            set
            {
                _profile = value;
            }
        }

        public void SetTokenCacheForProfile(GraphProfile profile)
        {
        }

        public void ResetDefaultProfile()
        {
            _profile = new GraphProfile();
        }
    }

    public sealed class GraphProfile
    {
        public String Tenant { get; set; }
        public Guid TenantID { get; set; }
        public String ClientID { get; set; }
        public bool Serviceprincipal { get; set; }
        public System.Net.Mail.MailAddress UPN { get; set; }
        Uri redirectUri = new Uri("urn:ietf:wg:oauth:2.0:oob");
        string resourceAppIdURI = @"https://graph.microsoft.com";
        string authority = @"https://login.microsoftonline.com";
        public AuthenticationResult Auth { get; set; }

        public GraphProfile(){}

        public void Connect(System.Net.Mail.MailAddress UPN, String Tenant = "", String clientID = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547", bool ServicePrincipal = false)
        {
            if (string.IsNullOrEmpty(Tenant))
            {
                this.Tenant = UPN.Host;
            }
            else
            {
                this.Tenant = Tenant;
            }

            this.ClientID = clientID;
            this.Serviceprincipal = Serviceprincipal;
            this.UPN = UPN;


            try
            {
                logging.write("New Connection: "+this.ToString(),logtype.verbose);
                Authenticate authenticate = new Authenticate();
                authenticate.AcquireToken(GraphProfileProvider.Instance.Profile, new Guid().ToString().Replace("-", string.Empty));
            }
            catch (Exception e)
            {
                logging.write(e, logtype.error);
                throw e;
            }
            //var authcontext = new AuthenticationContext(authority);
            //var PlatformParameters = new PlatformParameters(PromptBehavior.Auto);
            //var UserID = new UserIdentifier(UPN.ToString(), UserIdentifierType.OptionalDisplayableId);
            //var usercred = new UserCredential(UPN.ToString());
            //Auth = authcontext.AcquireTokenAsync(resourceAppIdURI, ClientID, redirectUri, PlatformParameters,UserID).Result;
            // var result =  authcontext.AcquireTokenAsync(resourceAppIdURI, ClientID,).Result;
            
            //Console.WriteLine(Auth);
        }

        public void Disconnect()
        {

        }

        public override string ToString()
        {
            return string.Format("UPN:'{0}', Tenant:'{1}', ClientID:'{2}', Serviceprincipal:{3}",UPN, Tenant, ClientID, Serviceprincipal);
        }
    }

    public enum ProfileType
    {
        User,
        ServicePrincipal
    }

    //public 


}
