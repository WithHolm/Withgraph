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
        public static Dictionary<String, String[]> ClassDepenable = new Dictionary<string, string[]>(); 
        //static String[] GraphOdataXML = 

        static Enviorment()
        {
            //Create Folders
            if(!Directory.Exists(UserSave))
            {
                Directory.CreateDirectory(UserSave);
            }

            if(!Directory.Exists(ConfigDir))
            {
                Directory.CreateDirectory(ConfigDir);
            }

            if(!Directory.Exists(CacheDir))
            {
                Directory.CreateDirectory(CacheDir);
            }

            if(Directory.Exists(classesDir))
            {
                Directory.CreateDirectory(classesDir);
            }

            if (Directory.Exists(LogDir))
            {
                Directory.CreateDirectory(LogDir);
            }

            //Import Odata

        }
    }
}
