using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Graph;

namespace MSGraphTest
{
    public class GroupHelper
    {
        private GraphServiceClient _graphClient;

        public GroupHelper(GraphServiceClient graphClient)
        {
            if (null == graphClient) throw new ArgumentNullException(nameof(graphClient));
            _graphClient = graphClient;
        }

        public async Task<Group> FindByDisplayName(string displayName)
        {
            List<QueryOption> queryOptions = new List<QueryOption>
            {
                new QueryOption("$filter", $@"displayName eq '{displayName}'")
            };

            var groupResult = await _graphClient.Groups.Request(queryOptions).GetAsync();
            if (groupResult.Count != 1) throw new ApplicationException($"Unable to find a group with the displayName {displayName}");
            return groupResult[0];
        }

        public async Task CreateGroup(string displayName, string alias, string description)
        {
            var groupToAdd = BuildGroupToAdd(displayName, alias, description);
            await _graphClient.Groups.Request().AddAsync(groupToAdd);
        }

        private static Group BuildGroupToAdd(string displayName, string alias, string description)
        {
            var group = new Group
            {
                DisplayName = displayName,
                MailNickname = alias,
                Description = description,
                SecurityEnabled = true,
                MailEnabled = false
            };
            return group;
        }

        public async Task AddMemberToGroup(string userId, string groupId)
        {
            var userToAdd = new DirectoryObject { Id = userId };
            await _graphClient.Groups[groupId].Members.References.Request().AddAsync(userToAdd);
        }
    }
}