using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Management.Automation;
using Microsoft.PowerShell.Commands;
using WithGraphCore.Environment;

namespace WithGraphCore.config
{
    public static class GraphConfig
    {
        public static RootObject Read()
        {
            Create();
            return JsonConvert.DeserializeObject<RootObject>(File.ReadAllText(WGCEnvironment.ConfigFile));
        }

        private static void Create()
        {
            if (!File.Exists(WGCEnvironment.ConfigFile))
            {
                File.WriteAllText(WGCEnvironment.ConfigFile, Properties.Resources.ConfigTemplate);
            }            
        }

        public static string Write(RootObject Config)
        {
            string SaveFile = JsonConvert.SerializeObject(Config);

            return SaveFile;
            //Console.WriteLine(SaveFile);
        }

    }

    public class AvalibleEndpoint
    {
        public string USGoverment { get; set; }
        public string Germany { get; set; }
        public string China { get; set; }
        public string Global { get; set; }
    }

    public class ServiceRootEndpoint
    {
        public string Selected { get; set; }
        public List<AvalibleEndpoint> Avalible { get; set; }
    }

    public class OidAndOauth2Endpoint
    {
        public string Selected { get; set; }
        public List<AvalibleEndpoint> Avalible { get; set; }
    }

    public class ApplicationConnectors
    {
    }

    public class Connector
    {
        public ServiceRootEndpoint ServiceRootEndpoint { get; set; }
        public OidAndOauth2Endpoint OidAndOauth2Endpoint { get; set; }
        public ApplicationConnectors ApplicationConnectors { get; set; }
    }

    public class LogLevel
    {
        public string Show { get; set; }
        public string Selected { get; set; }
        public List<string> Avalible { get; set; }
    }

    public class Client
    {
        public LogLevel LogLevel { get; set; }
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
        public Connector Connector { get; set; }
        public Client Client { get; set; }
        public Odata odata { get; set; }
        public Graphversion Graphversion { get; set; }
    }

}
