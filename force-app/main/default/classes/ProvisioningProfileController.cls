public with sharing class ProvisioningProfileController {
    public class ProvisioningProfileRequest {
        @AuraEnabled public String name;
        @AuraEnabled public Integer version;
        @AuraEnabled public String brokerTimezone;
        @AuraEnabled public String brokerDSTSwitchTimezone;
        @AuraEnabled public String type;
        @AuraEnabled public Integer managerLogin;
        @AuraEnabled public String managerPassword;
        @AuraEnabled public String managerServer;
        @AuraEnabled public String  sfTradingAccountId;
    }

    public class ProvisioningProfileResponse {
        @AuraEnabled public Integer status;
        @AuraEnabled public String statusText;
        @AuraEnabled public String body; // raw body string for debugging
    }

    @AuraEnabled
    public static ProvisioningProfileResponse createProfile(String reqJson) {
        if (String.isBlank(reqJson)) {
            throw new AuraHandledException('Request JSON cannot be blank.');
        }
        ProvisioningProfileRequest req;
        try {
            req = (ProvisioningProfileRequest) JSON.deserialize(reqJson, ProvisioningProfileRequest.class);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Deserialization failed: ' + ex.getMessage() + ' | JSON=' + reqJson);
            throw new AuraHandledException('Invalid request payload.');
        }

        if (String.isBlank(req.name) || req.version == null || String.isBlank(req.brokerTimezone) ||
            String.isBlank(req.brokerDSTSwitchTimezone) || String.isBlank(req.type) ||
            req.managerLogin == null || String.isBlank(req.managerPassword) || String.isBlank(req.managerServer)) {
            throw new AuraHandledException('All fields are required.');
        }

        HttpRequest httpReq = new HttpRequest();
        Http http = new Http();
        String path = '/api/accounts/provision-profile';

        httpReq.setMethod('POST');
        httpReq.setEndpoint('callout:Atkex_Trading' + path);
        httpReq.setHeader('Content-Type', 'application/json');

        // Forward everything — RPi will ignore what it doesn't need
        httpReq.setBody(reqJson);

        ProvisioningProfileResponse resWrap = new ProvisioningProfileResponse();
        try {
            HttpResponse res = http.send(httpReq);
            resWrap.status = res != null ? res.getStatusCode() : 0;
            resWrap.statusText = res != null ? res.getStatus() : 'No response';
            // Expect just {"id":"..."} back
            resWrap.body = res != null ? res.getBody() : null;
        } catch (System.CalloutException ex) {
            System.debug(LoggingLevel.ERROR, 'ProvisioningProfileController.createProfile CalloutException: ' + ex.getMessage());
            throw new AuraHandledException('Callout failed: ' + ex.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ProvisioningProfileController.createProfile Unexpected: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
        return resWrap;
    }
}
