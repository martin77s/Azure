using System;
using System.Collections.Generic;
using Microsoft.Identity.Client;
using Microsoft.Graph;
using Microsoft.Extensions.Configuration;


namespace MSGraphTest
{
    class Program
    {
        private static GraphServiceClient _graphServiceClient;

        private static IConfigurationRoot LoadAppSettings()
        {
            try
            {
                var config = new ConfigurationBuilder()
                .SetBasePath(System.IO.Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", false, true)
                .Build();

                if (string.IsNullOrEmpty(config["applicationId"]) ||
                    string.IsNullOrEmpty(config["applicationSecret"]) ||
                    string.IsNullOrEmpty(config["redirectUri"]) ||
                    string.IsNullOrEmpty(config["tenantId"]) ||
                    string.IsNullOrEmpty(config["domain"]))
                {
                    return null;
                }

                return config;
            }
            catch (System.IO.FileNotFoundException)
            {
                return null;
            }
        }

        private static IAuthenticationProvider CreateAuthorizationProvider(IConfigurationRoot config)
        {
            var clientId = config["applicationId"];
            var clientSecret = config["applicationSecret"];
            var redirectUri = config["redirectUri"];
            var authority = $"https://login.microsoftonline.com/{config["tenantId"]}/v2.0";

            List<string> scopes = new List<string>();
            scopes.Add("https://graph.microsoft.com/.default");

            var cca = new ConfidentialClientApplication(clientId, authority, redirectUri, new ClientCredential(clientSecret), null, null);
            return new MsalAuthenticationProvider(cca, scopes.ToArray());
        }

        private static GraphServiceClient GetAuthenticatedGraphClient(IConfigurationRoot config)
        {
            var authenticationProvider = CreateAuthorizationProvider(config);
            _graphServiceClient = new GraphServiceClient(authenticationProvider);
            return _graphServiceClient;
        }

        static void Main(string[] args)
        {
            var config = LoadAppSettings();
            if (null == config)
            {
                Console.WriteLine("Missing or invalid appsettings.json file. Please see README.md for configuration instructions.");
                return;
            }

            // Get an authenticated service referece:
            _graphServiceClient = GetAuthenticatedGraphClient(config);

            // Create a user:
            Console.Write("Enter the user's displayName: ");
            string displayName = Console.ReadLine();

            Console.Write("Enter the user's alias: ");
            string alias = Console.ReadLine();

            Console.Write("Enter the user's password: ");
            string password = Console.ReadLine();

            var userHelper = new UserHelper(_graphServiceClient);
            string domain = config["domain"];
            userHelper.CreateUser(displayName, alias, domain, password).GetAwaiter().GetResult();
            var user = userHelper.FindByAlias(alias).Result;

            Console.WriteLine("Created user: {0} ({1})\n",
                              user.DisplayName,
                              user.UserPrincipalName);

            // Create a group:
            Console.Write("Enter the group's displayName: ");
            displayName = Console.ReadLine();

            Console.Write("Enter the group's alias: ");
            alias = Console.ReadLine();

            Console.Write("Enter the group's description: ");
            string description = Console.ReadLine();

            var groupHelper = new GroupHelper(_graphServiceClient);
            groupHelper.CreateGroup(displayName, alias, description).GetAwaiter().GetResult();
            var group = groupHelper.FindByDisplayName(displayName).Result;
            Console.WriteLine("Created group: {0} ({1})\n",
                              group.DisplayName,
                              group.Description);

            // Add a user to a group
            groupHelper.AddMemberToGroup(user.Id, group.Id).GetAwaiter().GetResult();
            Console.WriteLine("User '{0}' added as member to group '{1}'\n",
                              user.DisplayName,
                              group.DisplayName);

        }
    }
}
