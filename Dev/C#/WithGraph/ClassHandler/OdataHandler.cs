using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.Remoting.Contexts;
using System.Text;
using System.Threading.Tasks;

namespace WithGraph
{
    public static class OdataDownloader
    {
        static bool DownloadCompleted = false;

        private static async Task DownloadFileAsync(string doc,string savepath)
        {
            try
            {
                using (WebClient webClient = new WebClient())
                {
                    logging.write("Downloading metadata from '" + doc + "' to '"+ savepath + "'.");
                    await webClient.DownloadFileTaskAsync(new Uri(doc), @savepath);
                }
            }
            catch (Exception e)
            {
                logging.write("Failed to download File: " + doc +": "+ e.Message, logtype.error);
            }
        }

        public static async Task DownloadMetadata(List<string> GraphVersion,string Savepath)
        {
            await Task.WhenAll(GraphVersion.Select(doc => DownloadFileAsync("https://graph.microsoft.com/"+doc+"/$metadata",Path.Combine(Savepath, doc+".xml"))));
            DownloadCompleted = true;
        }
    }
}
