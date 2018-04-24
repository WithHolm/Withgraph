using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Security;
using WithGraph.Authentication;


namespace WithGraph.Connector
{
    //[Cmdlet(VerbsCommunications.Connect, "GraphApi")]
    //public class ConnectGraphApi : Cmdlet
    //{
    //    [Parameter(Position = 0,ParameterSetName ="Credentials")]
    //    public PSCredential Credential { get; set; }
    //    [Parameter(Position = 1)]
    //    public PSCredential applicationID { get; set; }

    //    //public AzureAccount AzureEnviorment { get; set; }

    //    protected override void BeginProcessing()
    //    {
    //        var AzureEnvName = (new AzureEnvironment()).Name;
    //        if(AzureRmProfileProvider.Instance.Profile.Environments.ContainsKey(AzureEnvName))
    //        {
    //            var _AzureEnviorment = AzureRmProfileProvider.Instance.Profile.Environments[AzureEnvName];

    //            logging.write(string.Format("Current Azure Enviorment: {0}", _AzureEnviorment), logtype.verbose);
    //            //WriteVerbose(string.Format("Current Azure Enviorment: {0}", _AzureEnviorment));
    //            AzureSession.NewSessionstate();
    //            AzureSession.AzureEnvironment = _AzureEnviorment;
    //        }
    //        base.BeginProcessing();
    //    }

    //    protected override void ProcessRecord()
    //    {
    //        logging.write("Creating new azure session", logtype.verbose);
    //        GraphAccount Account = new GraphAccount();
    //        //Account.SetProperty(AzureAccount.Property.Tenants, this.tenantid);
    //        if(Credential != null)
    //        {
    //            Account.Id = Credential.UserName;
    //            Account.Type = GraphAccount.AccountType.User;
    //        }
    //        SecureString Password = new SecureString();
    //        //if(parameterse)

    //        base.ProcessRecord();
    //    }

    //    protected override void EndProcessing()
    //    {
    //        base.EndProcessing();
    //    }
    //}
}
