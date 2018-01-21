using Microsoft.ServiceBus;
using Microsoft.ServiceBus.Messaging;
using System;
using System.Configuration;

namespace EventHubSASTokenGenerator
{
    class Program
    {
        private static string EventHubServiceNamespace = ConfigurationManager.AppSettings["EventHubNamespace"];
        private static string EventHubNamespaceManageKeyName = ConfigurationManager.AppSettings["EventHubSharedAccessPolicyName"];
        private static string EventHubNamespaceManageKey = ConfigurationManager.AppSettings["EventHubKey"];
        private static string EventHubName = ConfigurationManager.AppSettings["EventHubName"];

        static void Main(string[] args)
        {
            string sas = CreateSharedAccessSignature();
            Console.WriteLine(sas);

            Console.WriteLine("Press Enter to exit.");
            Console.ReadLine();

            //SendTest(sas);
        }

        private static void SendTest(string sas)
        {
            var tokenProvider = SharedAccessSignatureTokenProvider.CreateSharedAccessSignatureTokenProvider(sas);

            var settings = new MessagingFactorySettings
            {
                TransportType = TransportType.Amqp,
                TokenProvider = tokenProvider
            };

            Uri runtimeUri = ServiceBusEnvironment.CreateServiceUri("sb", EventHubServiceNamespace, string.Empty);

            var mf = MessagingFactory.Create(runtimeUri, settings);

            var client = mf.CreateEventHubClient(EventHubName);

            var data = new EventData()
            {
                PartitionKey = "a"
            };

            // Set user properties if needed
            data.Properties.Add("Type", "Telemetry_" + DateTime.Now.ToLongTimeString());

            client.Send(data);
        }

        private static string CreateSharedAccessSignature()
        {
            string eventHubResourcePath = string.Format("https://{0}.servicebus.windows.net/{1}", EventHubServiceNamespace, EventHubName);

            DateTime now = DateTime.Now;
            TimeSpan expireationDate = now.AddYears(1) - now;

            var sas = SharedAccessSignatureTokenProvider.GetSharedAccessSignature(EventHubNamespaceManageKeyName,
                EventHubNamespaceManageKey,
                eventHubResourcePath,
                expireationDate);

            return sas;
        }
    }
}
