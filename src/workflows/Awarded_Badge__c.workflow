<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Email_to_Awarded_Badge_User</fullName>
        <description>Send Email to Awarded Badge User</description>
        <protected>false</protected>
        <recipients>
            <field>User__c</field>
            <type>userLookup</type>
        </recipients>
        
        <senderType>CurrentUser</senderType>
        <template>Gamification/Badge_Awarded</template>
    </alerts>
    <rules>
        <fullName>Send Email Notification Upon Awarding a Badge</fullName>
        <actions>
            <name>Send_Email_to_Awarded_Badge_User</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>Send Email Notification Upon Awarding a Badge</description>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
