using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WithGraph.Authentication
{
    [Serializable]
    public class GraphAccount
    {
        public GraphAccount()
        {
            //AzureAccount azureAccount = this;
            Properties = new Dictionary<Property, string>();
        }

        public string Id { get; set; }

        public AccountType Type { get; set; }

        public Dictionary<Property, string> Properties { get; set; }

        public override bool Equals(object obj)
        {
            GraphAccount azureAccount = obj as GraphAccount;
            if (azureAccount == null)
                return false;
            return string.Equals(azureAccount.Id, Id, StringComparison.InvariantCultureIgnoreCase);
        }

        public override int GetHashCode()
        {
            return Id.GetHashCode();
        }

        public override string ToString()
        {
            return Id;
        }

        public enum AccountType
        {
            ServicePrincipal,
            User,
            AccessToken,
        }

        public enum Property
        {
            Tenants,
            AadAccessToken,
            MsAccessToken,
            CertificateThumbprint,
        }
    }

    public class GraphSession
    {
        public void SetToken(String Token, DateTime dateTime = (new DateTime()))
        {
            
        }

        

        public enum Property
        {
            Tenant,
            Token
        }
    }
}
