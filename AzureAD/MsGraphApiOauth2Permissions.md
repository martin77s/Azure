# MS Graph API Oauth2Permissions

Generated by calling the following API:
```url
https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'&$select=appRoles, oauth2PermissionScopes
```

|id|value|displayName|
|-|-|-|
|3c42dec6-49e8-4a0a-b469-36cff0d9da93|TeamsTab.ReadWriteSelfForUser.All|Allow the Teams app to manage only its own tabs for all users|
|91c32b81-0ef0-453f-a5c7-4ce2e562f449|TeamsTab.ReadWriteSelfForTeam.All|Allow the Teams app to manage only its own tabs for all teams|
|9f62e4a2-a2d6-4350-b28b-d244728c4f86|TeamsTab.ReadWriteSelfForChat.All|Allow the Teams app to manage only its own tabs for all chats|
|cb8d6980-6bcb-4507-afec-ed6de3a2d798|IdentityRiskyServicePrincipal.ReadWrite.All|Read and write all risky service principal information|
|607c7344-0eed-41e5-823a-9695ebe1b7b0|IdentityRiskyServicePrincipal.Read.All|Read all identity risky service principal information|
|0e778b85-fefa-466d-9eec-750569d92122|SearchConfiguration.ReadWrite.All|Read and write your organization's search configuration|
|ada977a5-b8b1-493b-9a91-66c206d76ecf|SearchConfiguration.Read.All|Read your organization's search configuration|
|df01ed3b-eb61-4eca-9965-6b3d789751b2|OnlineMeetingArtifact.Read.All|Read online meeting artifacts|
|dc149144-f292-421e-b185-5953f2e98d7f|AppCatalog.ReadWrite.All|Read and write to all app catalogs|
|e12dae10-5a57-4817-b79d-dfbec5348930|AppCatalog.Read.All|Read all app catalogs|
|202bf709-e8e6-478e-bcfd-5d63c50b68e3|WorkforceIntegration.ReadWrite.All|Read and write workforce integrations|
|83cded22-8297-4ff6-a7fa-e97e9545a259|Presence.ReadWrite.All|Read and write presence information for all users|
|a3371ca5-911d-46d6-901c-42c8c7a937d8|TeamworkTag.ReadWrite.All|Read and write tags in Teams|
|b74fd6c4-4bde-488e-9695-eeb100e4907f|TeamworkTag.Read.All|Read tags in Teams|
|7dd1be58-6e76-4401-bf8d-31d1e8180d5b|WindowsUpdates.ReadWrite.All|Read and write all Windows update deployment settings|
|f431331c-49a6-499f-be1c-62af19c34a9d|ExternalConnection.ReadWrite.OwnedBy|Read and write external connections|
|8116ae0f-55c2-452d-9944-d18420f5b2c8|ExternalItem.ReadWrite.OwnedBy|Read and write external items|
|883ea226-0bf2-4a8f-9f9d-92c9162a727d|Sites.Selected|Access selected site collections|
|332a536c-c7ef-4017-ab91-336970924f0d|Sites.Read.All|Read items in all site collections |
|9492366f-7969-46a4-8d15-ed1a20078fff|Sites.ReadWrite.All|Read and write items in all site collections|
|3b4349e1-8cf5-45a3-95b7-69d1751d3e6a|CloudPC.ReadWrite.All|Read and write Cloud PCs|
|a9e09520-8ed4-4cde-838e-4fdea192c227|CloudPC.Read.All|Read Cloud PCs|
|89c8469c-83ad-45f7-8ff2-6e3d4285709e|ServicePrincipalEndpoint.ReadWrite.All|Read and update service principal endpoints|
|5256681e-b7f6-40c0-8447-2d9db68797a0|ServicePrincipalEndpoint.Read.All|Read service principal endpoints|
|a267235f-af13-44dc-8385-c1dc93023186|TeamsActivity.Send|Send a teamwork activity to any user|
|d8e4ec18-f6c0-4620-8122-c8b1f2bf400e|AgreementAcceptance.Read.All|Read all terms of use acceptance statuses|
|c9090d00-6101-42f0-a729-c41074260d47|Agreement.ReadWrite.All|Read and write all terms of use agreements|
|2f3e6f8c-093b-4c57-a58b-ba5ce494a169|Agreement.Read.All|Read all terms of use agreements|
|9f1b81a7-0223-4428-bfa4-0bcb5535f27d|ConsentRequest.ReadWrite.All|Read and write all consent requests|
|999f8c63-0a38-4f1b-91fd-ed1947bdd1a9|Policy.ReadWrite.ConsentRequest|Read and write your organization's consent request policy|
|1260ad83-98fb-4785-abbb-d6cc1806fd41|ConsentRequest.Read.All|Read all consent requests|
|693c5e45-0940-467d-9b8a-1022fb9d42ef|Mail.ReadBasic.All|Read basic mail in all mailboxes|
|6be147d2-ea4f-4b5a-a3fa-3eab6f3c140a|Mail.ReadBasic|Read basic mail in all mailboxes|
|2044e4f1-e56c-435b-925c-44cd8f6ba89a|Policy.ReadWrite.FeatureRollout|Read and write feature rollout policies|
|9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8|RoleManagement.ReadWrite.Directory|Read and write all directory RBAC settings|
|483bed4a-2ad3-4361-a73b-c83ccdbdc53c|RoleManagement.Read.Directory|Read all directory RBAC settings|
|292d869f-3427-49a8-9dab-8c70152b74e9|Organization.ReadWrite.All|Read and write organization information|
|498476ce-e0fe-48b0-b801-37ba7e2685c6|Organization.Read.All|Read organization information|
|913b9306-0ce1-42b8-9137-6a7df690a760|Place.Read.All|Read all company places|
|658aa5d8-239f-45c4-aa12-864f4fc7e490|Member.Read.Hidden|Read all hidden memberships|
|38c3d6ee-69ee-422f-b954-e17819665354|ExternalItem.ReadWrite.All|Read and write items in external datasets|
|18228521-a591-40f1-b215-5fad4488c117|AccessReview.ReadWrite.Membership|Manage access reviews for group and app memberships|
|dc377aa6-52d8-4e23-b271-2a7ae04cedf3|DeviceManagementConfiguration.Read.All|Read Microsoft Intune device configuration and policies|
|7a6ee1e7-141e-4cec-ae74-d9db155731ff|DeviceManagementApps.Read.All|Read Microsoft Intune apps|
|2f51be20-0bb4-4fed-bf7b-db946066c75e|DeviceManagementManagedDevices.Read.All|Read Microsoft Intune devices|
|58ca0d9a-1575-47e1-a3cb-007ef2e4583b|DeviceManagementRBAC.Read.All|Read Microsoft Intune RBAC settings|
|06a5fe6d-c49d-46a7-b082-56b1b14103c7|DeviceManagementServiceConfig.Read.All|Read Microsoft Intune configuration|
|0b57845e-aa49-4e6f-8109-ce654fffa618|OnPremisesPublishingProfiles.ReadWrite.All|Manage on-premises published resources|
|4a771c9a-1cf2-4609-b88e-3d3e02d539cd|TrustFrameworkKeySet.ReadWrite.All|Read and write trust framework key sets|
|fff194f1-7dce-4428-8301-1badb5518201|TrustFrameworkKeySet.Read.All|Read trust framework key sets|
|79a677f7-b79d-40d0-a36a-3e6f8688dd7a|Policy.ReadWrite.TrustFramework|Read and write your organization's trust framework policies|
|246dd0d5-5bd0-4def-940b-0421030a5b68|Policy.Read.All|Read your organization's policies|
|90db2b9a-d928-4d33-a4dd-8442ae3d41e4|IdentityProvider.ReadWrite.All|Read and write identity providers|
|e321f0bb-e7f7-481e-bb28-e3b0b32d4bd0|IdentityProvider.Read.All|Read identity providers|
|5eb59dd3-1da2-4329-8733-9dabdc435916|AdministrativeUnit.ReadWrite.All|Read and write all administrative units|
|134fd756-38ce-4afd-ba33-e9623dbe66c2|AdministrativeUnit.Read.All|Read all administrative units|
|19da66cb-0fb0-4390-b071-ebc76a349482|InformationProtectionPolicy.Read.All|Read all published labels and label policies for an organization.|
|3aeca27b-ee3a-4c2b-8ded-80376e2134a4|Notes.Read.All|Read all OneNote notebooks|
|09850681-111b-4a89-9bed-3f2cae46d706|User.Invite.All|Invite guest users to the organization|
|75359482-378d-4052-8f01-80520e7db3cd|Files.ReadWrite.All|Read and write files in all site collections|
|21792b6c-c986-4ffc-85de-df9da54b52fa|ThreatIndicators.ReadWrite.OwnedBy|Manage threat indicators this app creates or owns|
|f2bf083f-0179-402a-bedb-b2784de8a49b|SecurityActions.ReadWrite.All|Read and update your organization's security actions|
|5e0edab9-c148-49d0-b423-ac253e121825|SecurityActions.Read.All|Read your organization's security actions|
|d903a879-88e0-4c09-b0c9-82f6a1333f84|SecurityEvents.ReadWrite.All|Read and update your organization’s security events|
|bf394140-e372-4bf9-a898-299cfc7564e5|SecurityEvents.Read.All|Read your organization’s security events|
|294ce7c9-31ba-490a-ad7d-97a7d075e4ed|Chat.ReadWrite.All|Read and write all chat messages|
|db06fb33-1953-4b7b-a2ac-f1e2c854f7ae|IdentityRiskEvent.ReadWrite.All|Read and write all risk detection information|
|656f6061-f9fe-4807-9708-6a2e0934df76|IdentityRiskyUser.ReadWrite.All|Read and write all risky user information|
|01d4889c-1287-42c6-ac1f-5d1e02578ef6|Files.Read.All|Read files in all site collections|
|6e472fd1-ad78-48da-a0f0-97ab2c6b769e|IdentityRiskEvent.Read.All|Read all identity risk event information|
|0d412a8c-a06c-439f-b3ec-8abcf54d2f96|EduRoster.ReadBasic.All|Read a limited subset of the organization's roster|
|e0ac9e1b-cb65-4fc5-87c5-1a8bc181f648|EduRoster.Read.All|Read the organization's roster|
|d1808e82-ce13-47af-ae0d-f9b254e6d58a|EduRoster.ReadWrite.All|Read and write the organization's roster|
|6e0a958b-b7fc-4348-b7c4-a6ab9fd3dd0e|EduAssignments.ReadBasic.All|Read class assignments without grades|
|f431cc63-a2de-48c4-8054-a34bc093af84|EduAssignments.ReadWriteBasic.All|Read and write class assignments without grades|
|4c37e1b6-35a1-43bf-926a-6f30f2cdf585|EduAssignments.Read.All|Read class assignments with grades|
|0d22204b-6cad-4dd0-8362-3e3f2ae699d9|EduAssignments.ReadWrite.All|Read and write class assignments with grades|
|7c9db06a-ec2d-4e7b-a592-5a1e30992566|EduAdministration.Read.All|Read Education app settings|
|9bc431c3-b8bc-4a8d-a219-40f10f92eff6|EduAdministration.ReadWrite.All|Manage education app settings|
|dc5007c0-2d7d-4c42-879c-2dab87571379|IdentityRiskyUser.Read.All|Read all identity risky user information|
|741f803b-c850-494e-b5df-cde7c675a1ca|User.ReadWrite.All|Read and write all users' full profiles|
|df021288-bdef-4463-88db-98f22de89214|User.Read.All|Read all users' full profiles|
|b0afded3-3588-46d8-8b3d-9842eff778da|AuditLog.Read.All|Read all audit log data|
|18a4783c-866b-4cc7-a460-3d5e5662c884|Application.ReadWrite.OwnedBy|Manage apps that this app creates or owns|
|405a51b5-8d8d-430b-9842-8be4b0e9f324|User.Export.All|Export user's data|
|60a901ed-09f7-4aa5-a16e-7dd3d6f9de36|ProgramControl.ReadWrite.All|Manage all programs|
|eedb7fdd-7539-4345-a38b-4839e4a84cbd|ProgramControl.Read.All|Read all programs|
|ef5f7d5c-338f-44b0-86c3-351f46c8bb5f|AccessReview.ReadWrite.All|Manage all access reviews|
|d07a8cc0-3d51-4b77-b3b0-32704d1f69fa|AccessReview.Read.All|Read all access reviews|
|230c1aed-a721-4c5d-9cb4-a90514e508ef|Reports.Read.All|Read all usage reports|
|b528084d-ad10-4598-8b93-929746b4d7d6|People.Read.All|Read all users' relevant people lists|
|7e847308-e030-4183-9899-5235d7270f58|Chat.UpdatePolicyViolation.All|Flag chat messages for violating policy|
|6b7d71aa-70aa-4810-a8d9-5d9fb2830017|Chat.Read.All|Read all chat messages|
|7b2449af-6ccd-4f4d-9f78-e550c193f0d1|ChannelMessage.Read.All|Read all channel messages|
|4d02b0cc-d90b-441f-8d82-4fb55c34d6bb|ChannelMessage.UpdatePolicyViolation.All|Flag channel messages for violating policy|
|1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9|Application.ReadWrite.All|Read and write all applications|
|6931bccd-447a-43d1-b442-00a195474933|MailboxSettings.ReadWrite|Read and write all user mailbox settings|
|7e05723c-0bb0-42da-be95-ae9f08a6e53c|Domain.ReadWrite.All|Read and write domains|
|40f97065-369a-49f4-947c-6a255697ae91|MailboxSettings.Read|Read all user mailbox settings|
|810c84a8-4a9e-49e6-bf7d-12d183f40d01|Mail.Read|Read mail in all mailboxes|
|e2a3a72e-5f79-4c64-b1b1-878b674786c9|Mail.ReadWrite|Read and write mail in all mailboxes|
|b633e1c5-b582-4048-a93e-9f11b44c7e96|Mail.Send|Send mail as any user|
|089fe4d0-434a-44c5-8827-41ba8a0b17f5|Contacts.Read|Read contacts in all mailboxes|
|6918b873-d17a-4dc1-b314-35f528134491|Contacts.ReadWrite|Read and write contacts in all mailboxes|
|5b567255-7703-4780-807c-7be8301ae99b|Group.Read.All|Read all groups|
|62a82d76-70ea-41e2-9197-370581804d09|Group.ReadWrite.All|Read and write all groups|
|7ab1d382-f21e-4acd-a863-ba3e13f7da61|Directory.Read.All|Read directory data|
|19dbc75e-c2e2-444c-a770-ec69d8559fc7|Directory.ReadWrite.All|Read and write directory data|
|1138cb37-bd11-4084-a2b7-9f71582aeddb|Device.ReadWrite.All|Read and write devices|
|798ee544-9d2d-430c-a058-570e29e34338|Calendars.Read|Read calendars in all mailboxes|
|ef54d2bf-783f-4e0f-bca1-3210c0444d99|Calendars.ReadWrite|Read and write calendars in all mailboxes|
|1b0c317f-dd31-4305-9932-259a8b6e8099|IdentityUserFlow.Read.All|Read all identity user flows|
|65319a09-a2be-469d-8782-f6b07debf789|IdentityUserFlow.ReadWrite.All|Read and write all identity user flows|
|b8bb2037-6e08-44ac-a4ea-4674e010e2a4|OnlineMeetings.ReadWrite.All|Read and create online meetings|
|c1684f21-1984-47fa-9d61-2dc8c296bb70|OnlineMeetings.Read.All|Read online meeting details|
|a7a681dc-756e-4909-b988-f160edc6655f|Calls.AccessMedia.All|Access media streams in a call as an app|
|fd7ccf6b-3d28-418b-9701-cd10f5cd2fd4|Calls.JoinGroupCallAsGuest.All|Join group calls and meetings as a guest|
|f6b49018-60ab-4f81-83bd-22caeabfed2d|Calls.JoinGroupCall.All|Join group calls and meetings as an app|
|4c277553-8a09-487b-8023-29ee378d8324|Calls.InitiateGroupCall.All|Initiate outgoing group calls from the app|
|284383ee-7f6e-4e40-a2a8-e85dcb029101|Calls.Initiate.All|Initiate outgoing 1 to 1 calls from the app|
|e1a88a34-94c4-4418-be12-c87b00e26bea|OrgContact.Read.All|Read organizational contacts|
|78145de6-330d-4800-a6ce-494ff2d33d07|DeviceManagementApps.ReadWrite.All|Read and write Microsoft Intune apps|
|9241abd9-d0e6-425a-bd4f-47ba86e767a4|DeviceManagementConfiguration.ReadWrite.All|Read and write Microsoft Intune device configuration and policies|
|5b07b0dd-2377-4e44-a38d-703f09a0dc3c|DeviceManagementManagedDevices.PrivilegedOperations.All|Perform user-impacting remote actions on Microsoft Intune devices|
|243333ab-4d21-40cb-a475-36241daa0842|DeviceManagementManagedDevices.ReadWrite.All|Read and write Microsoft Intune devices|
|e330c4f0-4170-414e-a55a-2f022ec2b57b|DeviceManagementRBAC.ReadWrite.All|Read and write Microsoft Intune RBAC settings|
|5ac13192-7ace-4fcf-b828-1a26f28068ee|DeviceManagementServiceConfig.ReadWrite.All|Read and write Microsoft Intune configuration|
|06b708a9-e830-4db3-a914-8e69da51d44f|AppRoleAssignment.ReadWrite.All|Manage app permission grants and app role assignments|
|8e8e4742-1d95-4f68-9d56-6ee75648c72a|DelegatedPermissionGrant.ReadWrite.All|Manage all delegated permission grants|
|70dec828-f620-4914-aa83-a29117306807|TeamsActivity.Read.All|Read all users' teamwork activity feed|
|4cdc2547-9148-4295-8d11-be0db1391d6b|PrivilegedAccess.Read.AzureAD|Read privileged access to Azure AD roles|
|01e37dc9-c035-40bd-b438-b2879c4870a6|PrivilegedAccess.Read.AzureADGroup|Read privileged access to Azure AD groups|
|5df6fe86-1be0-44eb-b916-7bd443a71236|PrivilegedAccess.Read.AzureResources|Read privileged access to Azure resources|
|854d9ab1-6657-4ec8-be45-823027bcd009|PrivilegedAccess.ReadWrite.AzureAD|Read and write privileged access to Azure AD roles|
|2f6817f8-7b12-4f0f-bc18-eeaf60705a9e|PrivilegedAccess.ReadWrite.AzureADGroup|Read and write privileged access to Azure AD groups|
|6f9d5abc-2db6-400b-a267-7de22a40fb87|PrivilegedAccess.ReadWrite.AzureResources|Read and write privileged access to Azure resources|
|197ee4e9-b993-4066-898f-d6aecc55125b|ThreatIndicators.Read.All|Read all threat indicators|
|afdb422a-4b2a-4e07-a708-8ceed48196bf|TeamsApp.Read.All|Read all users' installed Teams apps|
|eb6b3d76-ed75-4be6-ac36-158d04c0a555|TeamsApp.ReadWrite.All|Manage all users' Teams apps|
|4e774092-a092-48d1-90bd-baad67c7eb47|UserNotification.ReadWrite.CreatedByApp|Deliver and manage all user's notifications|
|9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30|Application.Read.All|Read all applications|
|57f1cf28-c0c4-4ec3-9a30-19a2eaaf2f6e|BitlockerKey.Read.All|Read all BitLocker keys|
|f690d423-6b29-4d04-98c6-694c42282419|BitlockerKey.ReadBasic.All|Read all BitLocker keys basic information|
|98830695-27a2-44f7-8c18-0c3ebc9698f6|GroupMember.Read.All|Read all group memberships|
|dbaae8cf-10b5-4b86-a4a1-f871c94c6695|GroupMember.ReadWrite.All|Read and write all group memberships|
|bf7b1a76-6e77-406b-b258-bf5c7720e98f|Group.Create|Create groups|
|f8f035bb-2cce-47fb-8bf5-7baf3ecbee48|ThreatAssessment.Read.All|Read threat assessment requests|
|7b2ebf90-d836-437f-b90d-7b62722c4456|Schedule.Read.All|Read all schedule items|
|b7760610-0545-4e8a-9ec3-cce9e63db01c|Schedule.ReadWrite.All|Read and write all schedule items|
|45bbb07e-7321-4fd7-a8f6-3ff27e6a81c8|CallRecords.Read.All|Read all call records|
|01c0a623-fc9b-48e9-b794-0756f8e8f067|Policy.ReadWrite.ConditionalAccess|Read and write your organization's conditional access policies|
|50483e42-d915-4231-9639-7fdb7fd190e5|UserAuthenticationMethod.ReadWrite.All|Read and write all users' authentication methods |
|38d9df27-64da-44fd-b7c5-a6fbac20248f|UserAuthenticationMethod.Read.All| Read all users' authentication methods|
|49981c42-fd7b-4530-be03-e77b21aed25e|TeamsTab.Create|Create tabs in Microsoft Teams.|
|46890524-499a-4bb2-ad64-1476b4f3e1cf|TeamsTab.Read.All|Read tabs in Microsoft Teams.|
|a96d855f-016b-47d7-b51c-1218a98d791c|TeamsTab.ReadWrite.All|Read and write tabs in Microsoft Teams.|
|dbb9058a-0e50-45d7-ae91-66909b5d4664|Domain.Read.All|Read domains|
|be74164b-cff1-491c-8741-e671cb536e13|Policy.ReadWrite.ApplicationConfiguration|Read and write your organization's application configuration policies|
|7438b122-aefc-4978-80ed-43db9fcc7715|Device.Read.All|Read all devices|
|c529cfca-c91b-489c-af2b-d92990b66ce6|User.ManageIdentities.All|Manage all users' identities|
|de023814-96df-4f53-9376-1e2891ef5a18|UserShiftPreferences.Read.All|Read all user shift preferences|
|d1eec298-80f3-49b0-9efb-d90e224798ac|UserShiftPreferences.ReadWrite.All|Read and write all user shift preferences|
|0c458cef-11f3-48c2-a568-c66751c238c0|Notes.ReadWrite.All|Read and write all OneNote notebooks|
|a82116e5-55eb-4c41-a434-62fe8a61c773|Sites.FullControl.All|Have full control of all site collections|
|0c0bf378-bf22-4481-8f81-9e89a9b4960a|Sites.Manage.All|Create, edit, and delete items and lists in all site collections|
|c74fd47d-ed3c-45c3-9a9e-b8676de685d2|EntitlementManagement.Read.All|Read all entitlement management resources|
|9acd699f-1e81-4958-b001-93b1d2506e19|EntitlementManagement.ReadWrite.All|Read and write all entitlement management resources|
|f3a65bd4-b703-46df-8f7e-0174fea562aa|Channel.Create|Create channels|
|6a118a39-1227-45d4-af0c-ea7b40d210bc|Channel.Delete.All|Delete channels|
|c97b873f-f59f-49aa-8a0e-52b32d762124|ChannelSettings.Read.All|Read the names, descriptions, and settings of all channels|
|243cded2-bd16-4fd6-a953-ff8177894c3d|ChannelSettings.ReadWrite.All|Read and write the names, descriptions, and settings of all channels|
|2280dda6-0bfd-44ee-a2f4-cb867cfc4c1e|Team.ReadBasic.All|Get a list of all teams|
|59a6b24b-4225-4393-8165-ebaec5f55d7a|Channel.ReadBasic.All|Read the names and descriptions  of all channels|
|bdd80a03-d9bc-451d-b7c4-ce7c63fe3c8f|TeamSettings.ReadWrite.All|Read and change all teams' settings|
|242607bd-1d2c-432c-82eb-bdb27baa23ab|TeamSettings.Read.All|Read all teams' settings|
|660b7406-55f1-41ca-a0ed-0b035e182f3e|TeamMember.Read.All|Read the members of all teams|
|0121dc95-1b9f-4aed-8bac-58c5ac466691|TeamMember.ReadWrite.All|Add and remove members from all teams|
|3b55498e-47ec-484f-8136-9013221c06a9|ChannelMember.Read.All|Read the members of all channels|
|35930dcf-aceb-4bd1-b99a-8ffed403c974|ChannelMember.ReadWrite.All|Add and remove members from all channels|
|25f85f3c-f66c-4205-8cd5-de92dd7f0cec|Policy.ReadWrite.AuthenticationFlows|Read and write authentication flow policies|
|29c18626-4985-4dcd-85c0-193eef327366|Policy.ReadWrite.AuthenticationMethod|Read and write all authentication method policies |
|fb221be6-99f2-473f-bd32-01c6a0e9ca3b|Policy.ReadWrite.Authorization|Read and write your organization's authorization policy|
|b2e060da-3baf-4687-9611-f4ebc0f0cbde|Chat.ReadBasic.All|Read names and members of all chat threads|
|9e640839-a198-48fb-8b9a-013fd6f6cbcd|Policy.Read.PermissionGrant|Read consent and permission grant policies|
|a402ca1c-2696-4531-972d-6e5ee4aa11ea|Policy.ReadWrite.PermissionGrant|Manage consent and permission grant policies|
|9709bb33-4549-49d4-8ed9-a8f65e45bb0f|Printer.Read.All|Read printers|
|f5b3f73d-6247-44df-a74c-866173fddab0|Printer.ReadWrite.All|Read and update printers|
|58a52f47-9e36-4b17-9ebe-ce4ef7f3e6c8|PrintJob.Manage.All|Perform advanced operations on print jobs|
|ac6f956c-edea-44e4-bd06-64b1b4b9aec9|PrintJob.Read.All|Read print jobs|
|fbf67eee-e074-4ef7-b965-ab5ce1c1f689|PrintJob.ReadBasic.All|Read basic information for print jobs|
|5114b07b-2898-4de7-a541-53b0004e2e13|PrintJob.ReadWrite.All|Read and write print jobs|
|57878358-37f4-4d3a-8c20-4816e0d457b1|PrintJob.ReadWriteBasic.All|Read and write basic information for print jobs|
|456b71a7-0ee0-4588-9842-c123fcc8f664|PrintTaskDefinition.ReadWrite.All|Read, write and update print task definitions|
|dfb0dd15-61de-45b2-be36-d6a69fba3c79|Teamwork.Migrate.All|Create chat and channel messages with anyone's identity and with any timestamp|
|cc7e7635-2586-41d6-adaa-a8d3bcad5ee5|TeamsAppInstallation.ReadForChat.All|Read installed Teams apps for all chats|
|1f615aea-6bf9-4b05-84bd-46388e138537|TeamsAppInstallation.ReadForTeam.All|Read installed Teams apps for all teams|
|9ce09611-f4f7-4abd-a629-a05450422a97|TeamsAppInstallation.ReadForUser.All|Read installed Teams apps for all users|
|9e19bae1-2623-4c4f-ab6e-2664615ff9a0|TeamsAppInstallation.ReadWriteForChat.All|Manage Teams apps for all chats|
|5dad17ba-f6cc-4954-a5a2-a0dcc95154f0|TeamsAppInstallation.ReadWriteForTeam.All|Manage Teams apps for all teams|
|74ef0291-ca83-4d02-8c7e-d2391e6a444f|TeamsAppInstallation.ReadWriteForUser.All|Manage Teams apps for all users|
|73a45059-f39c-4baf-9182-4954ac0e55cf|TeamsAppInstallation.ReadWriteSelfForChat.All|Allow the Teams app to manage itself for all chats|
|9f67436c-5415-4e7f-8ac1-3014a7132630|TeamsAppInstallation.ReadWriteSelfForTeam.All|Allow the Teams app to manage itself for all teams|
|908de74d-f8b2-4d6b-a9ed-2a17b3b78179|TeamsAppInstallation.ReadWriteSelfForUser.All|Allow the app to manage itself for all users|
|23fc2474-f741-46ce-8465-674744c5c361|Team.Create|Create teams|
|4437522e-9a86-4a41-a7da-e380edd4a97d|TeamMember.ReadWriteNonOwnerRole.All|Add and remove members with non-owner role for all teams|
|ea047cc2-df29-4f3e-83a3-205de61501ca|TermStore.Read.All|Read all term store data|
|f12eb8d6-28e3-46e6-b2c0-b7e4dc69fc95|TermStore.ReadWrite.All|Read and write all term store data|
|79c261e0-fe76-4144-aad5-bdc68fbe4037|ServiceHealth.Read.All|Read service health|
|1b620472-6534-4fe6-9df2-4680e8aa28ec|ServiceMessage.Read.All|Read service messages|
|0c7d31ec-31ca-4f58-b6ec-9950b6b0de69|ShortNotes.Read.All|Read all users' short notes|
|842c284c-763d-4a97-838d-79787d129bab|ShortNotes.ReadWrite.All|Read, create, edit, and delete all users' short notes|
|37730810-e9ba-4e46-b07e-8ca78d182097|Policy.Read.ConditionalAccess|Read your organization's conditional access policies|
|c7fbd983-d9aa-4fa7-84b8-17382c103bc4|RoleManagement.Read.All|Read role management data for all RBAC providers|
|a2611786-80b3-417e-adaa-707d4261a5f0|CallRecord-PstnCalls.Read.All|Read PSTN and direct routing call log data|
|b9bb2381-47a4-46cd-aafb-00cb12f68504|ChatMessage.Read.All|Read all chat messages|
|fd9ce730-a250-40dc-bd44-8dc8d20f39ea|TeamsTab.ReadWriteForChat.All|Allow the Teams app to manage all tabs for all chats|
|6163d4f4-fbf8-43da-a7b4-060fe85ed148|TeamsTab.ReadWriteForTeam.All|Allow the Teams app to manage all tabs for all teams|
|425b4b59-d5af-45c8-832f-bb0b7402348a|TeamsTab.ReadWriteForUser.All|Allow the app to manage all tabs for all users|
|b86848a7-d5b1-41eb-a9b4-54a4e6306e97|APIConnectors.Read.All|Read API connectors for authentication flows|
|1dfe531a-24a6-4f1b-80f4-7a0dc5a0a171|APIConnectors.ReadWrite.All|Read and write API connectors for authentication flows|
|a3410be2-8e48-4f32-8454-c29a7465209d|ChatMember.Read.All|Read the members of all chats|
|57257249-34ce-4810-a8a2-a03adf0c5693|ChatMember.ReadWrite.All|Add and remove members from all chats|
|d9c48af6-9ad9-47ad-82c3-63757137b9af|Chat.Create|Create chats|
|b5991872-94cf-4652-9765-29535087c6d8|PrintSettings.Read.All|Read tenant-wide print settings|
