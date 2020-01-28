using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WithGraphCore.Environment
{
    public static class WGCEnvironment
    {
        public static string Moduleroot = Directory.GetCurrentDirectory();
        public static string UserSave = Path.Combine(System.Environment.GetEnvironmentVariable("appdata"), "WithGraph");
        public static string ConfigDir = Path.Combine(UserSave, "Config");
        public static string ConfigFile = Path.Combine(UserSave, "Config.json");
        public static string CacheDir = Path.Combine(UserSave, "Cache");
        public static string classesDir = Path.Combine(UserSave, "Classes");
        public static string LogDir = Path.Combine(UserSave, "Log");
        public static string LogFile = Path.Combine(LogDir, DateTime.Now.ToString("yyyyddMMHHmm")+".Log");
        public static Dictionary<string, string[]> ClassDepenable = new Dictionary<string, string[]>();
        public static bool IsCreated = false;
        //static String[] GraphOdataXML = 

        static void Init()
        {
            NewUserSave();
            NewDirectory(ConfigDir);
            NewDirectory(CacheDir);
            NewDirectory(classesDir);
            NewDirectory(LogDir);
            IsCreated = true;
        }

        static void NewUserSave()
        {
            if (!Directory.Exists(UserSave))
            {
                Directory.CreateDirectory(UserSave);
                logging.write("Creating main temp folder: " + UserSave,logtype.debug);
            }
        }

        static bool TestPath (string path)
        {
            if(!path.Contains(UserSave))
            {
                logging.write("Unable To create new item at '" + path + "'. The Directory is outside the defined usersave", logtype.error, "TestPath");
                return false;
            }

            if(Directory.Exists(path))
            {
                return false;
            }
            else if(File.Exists(path))
            {
                return false;
            }

            return true;
        }

        static void NewDirectory(string path)
        {
            NewUserSave();
            if (TestPath(path))
            {
                logging.write("Creating .\\" + (path.Replace(Directory.GetParent(path).FullName, "")), logtype.debug, "Env: New Directory");
                Directory.CreateDirectory(path);
            }
        }

        static void NewFile(string path)
        {
            NewUserSave();
            if (TestPath(path))
            {
                logging.write("Creating .\\" + (path.Replace(Directory.GetParent(path).FullName, "")), logtype.debug, "Env: New Directory");
                File.Create(path);
            }
        }

        public static void Remove()
        {
            Directory.Delete(UserSave, true);

        }

        static WGCEnvironment()
        {
            //RemoveEnviorment();
            Init();
            logging.write(string.Format("GraphConnector started {0} !", DateTime.Now.ToString()),logtype.info,"Enviorment");

            var Config = config.GraphConfig.Read();
            // Config.Graphversion.Avalible
            //OdataDownloader.DownloadMetadata(Config.Graphversion.Avalible,CacheDir);
        }
    }
}
