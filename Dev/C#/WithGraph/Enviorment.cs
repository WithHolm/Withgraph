using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WithGraph
{
    public static class Enviorment
    {
        public static string Moduleroot = Directory.GetCurrentDirectory();
        public static string UserSave = Path.Combine(System.Environment.GetEnvironmentVariable("appdata"), "WithGraph");
        public static string ConfigDir = Path.Combine(UserSave, "Config");
        public static string ConfigFile = Path.Combine(UserSave, "Config.json");
        public static string CacheDir = Path.Combine(UserSave, "Cache");
        public static string classesDir = Path.Combine(UserSave, "Classes");
        public static string LogDir = Path.Combine(UserSave, "Log");
        public static string LogFile = Path.Combine(LogDir, DateTime.Now.ToString("yyyyddMMHHmm")+".Log");
        public static Dictionary<String, String[]> ClassDepenable = new Dictionary<string, string[]>(); 
        //static String[] GraphOdataXML = 

        static void Create()
        {
            if (!Directory.Exists(UserSave))
            {
                Console.WriteLine("Creating " + UserSave);
                Directory.CreateDirectory(UserSave);
            }

            if (!Directory.Exists(ConfigDir))
            {
                Console.WriteLine("Creating " + ConfigDir);
                Directory.CreateDirectory(ConfigDir);
            }

            if (!Directory.Exists(CacheDir))
            {
                Console.WriteLine("Creating " + CacheDir);
                Directory.CreateDirectory(CacheDir);
            }

            if (!Directory.Exists(classesDir))
            {
                Console.WriteLine("Creating " + classesDir);
                Directory.CreateDirectory(classesDir);
            }

            if (!Directory.Exists(LogDir))
            {
                Console.WriteLine("Creating " + LogDir);
                Directory.CreateDirectory(LogDir);
            }
        }

        static Enviorment()
        {
            Create();
            logging.write("GraphConnector started " + DateTime.Now.ToString()+"!");
        }
    }
}
